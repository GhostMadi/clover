-- Post share into chat: batch RPC, recipient analytics, frequent-recipients refresh.

-- --------------------------------------------------------------------------- post_send_events.recipient_id
alter table public.post_send_events
  add column if not exists recipient_id uuid null references public.profiles (id) on delete set null;

comment on column public.post_send_events.recipient_id is
  'DM share target; set by share_post_to_recipients for frequent-recipient ranking.';

create index if not exists post_send_events_sender_recipient_idx
  on public.post_send_events (sender_id, recipient_id, created_at desc)
  where recipient_id is not null;

-- --------------------------------------------------------------------------- post_assert_shareable
create or replace function public.post_assert_shareable(p_post_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_post_id is null then
    raise exception 'post_id_required' using errcode = 'P0012';
  end if;

  if not exists (
    select 1
    from public.posts p
    inner join public.profiles pr on pr.id = p.user_id
    where p.id = p_post_id
      and p.deleted_at is null
      and not p.is_archived
      and pr.content_visible = true
      and pr.account_state <> 'hibernate'
  ) then
    raise exception 'post_not_shareable' using errcode = 'P0013';
  end if;
end;
$$;

revoke all on function public.post_assert_shareable(uuid) from public;
grant execute on function public.post_assert_shareable(uuid) to authenticated;

comment on function public.post_assert_shareable(uuid) is
  'Ensures post exists, is public/active, and author is visible.';

-- --------------------------------------------------------------------------- share_post_to_recipients
create or replace function public.share_post_to_recipients(
  p_post_id uuid,
  p_recipient_ids uuid[],
  p_message text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid := auth.uid();
  v_caption text := nullif(trim(coalesce(p_message, '')), '');
  v_recipient uuid;
  v_cid uuid;
  v_mid uuid;
  v_shared_count int := 0;
  v_results jsonb := '[]'::jsonb;
  v_recipients uuid[];
  v_sends_count int;
  v_max_recipients constant int := 20;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  perform public.post_assert_shareable(p_post_id);

  select coalesce(array_agg(recipient_id), '{}'::uuid[])
  into v_recipients
  from (
    select distinct r as recipient_id
    from unnest(coalesce(p_recipient_ids, '{}'::uuid[])) as r
    where r is not null
      and r <> uid
    limit v_max_recipients
  ) s;

  if coalesce(array_length(v_recipients, 1), 0) = 0 then
    raise exception 'recipients_required' using errcode = 'P0014';
  end if;

  foreach v_recipient in array v_recipients loop
    begin
      if not exists (
        select 1
        from public.profile_follows f
        where f.follower_id = uid
          and f.following_id = v_recipient
      ) then
        v_results := v_results || jsonb_build_array(
          jsonb_build_object(
            'recipient_id', v_recipient,
            'ok', false,
            'error_code', 'not_following'
          )
        );
        continue;
      end if;

      if not exists (
        select 1
        from public.profiles pr
        where pr.id = v_recipient
          and pr.content_visible = true
          and pr.account_state <> 'hibernate'
      ) then
        v_results := v_results || jsonb_build_array(
          jsonb_build_object(
            'recipient_id', v_recipient,
            'ok', false,
            'error_code', 'recipient_unavailable'
          )
        );
        continue;
      end if;

      v_cid := public.create_dm(v_recipient);

      v_mid := public.send_message(
        v_cid,
        'post_ref',
        v_caption,
        null,
        null,
        p_post_id,
        gen_random_uuid()
      );

      insert into public.post_send_events (post_id, sender_id, recipient_id)
      values (p_post_id, uid, v_recipient);

      v_shared_count := v_shared_count + 1;

      v_results := v_results || jsonb_build_array(
        jsonb_build_object(
          'recipient_id', v_recipient,
          'conversation_id', v_cid,
          'message_id', v_mid,
          'ok', true
        )
      );
    exception
      when others then
        v_results := v_results || jsonb_build_array(
          jsonb_build_object(
            'recipient_id', v_recipient,
            'ok', false,
            'error_code', sqlstate,
            'error_message', sqlerrm
          )
        );
    end;
  end loop;

  if v_shared_count = 0 then
    raise exception 'share_failed' using errcode = 'P0015';
  end if;

  select p.sends_count
  into v_sends_count
  from public.posts p
  where p.id = p_post_id;

  return jsonb_build_object(
    'shared_count', v_shared_count,
    'sends_count', coalesce(v_sends_count, 0),
    'results', v_results
  );
end;
$$;

revoke all on function public.share_post_to_recipients(uuid, uuid[], text) from public;
grant execute on function public.share_post_to_recipients(uuid, uuid[], text) to authenticated;

comment on function public.share_post_to_recipients(uuid, uuid[], text) is
  'Share post into DM(s): open/reuse DM, send post_ref message, bump sends_count. Recipients must be followed.';

-- --------------------------------------------------------------------------- frequent recipients (post_send_events)
create or replace function public.list_post_share_frequent_recipients(p_limit int default 10)
returns table (
  profile_id uuid,
  username text,
  avatar_url text,
  share_count bigint
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  with scored as (
    select
      e.recipient_id as profile_id,
      count(*)::bigint as share_count,
      max(e.created_at) as last_shared_at
    from public.post_send_events e
    inner join public.profile_follows f
      on f.follower_id = auth.uid()
     and f.following_id = e.recipient_id
    where e.sender_id = auth.uid()
      and e.recipient_id is not null
    group by e.recipient_id
  )
  select
    pr.id as profile_id,
    case when pr.reset_at is not null then 'noName' else pr.username end as username,
    case when pr.reset_at is not null then null else pr.avatar_url end as avatar_url,
    s.share_count
  from scored s
  inner join public.profiles pr on pr.id = s.profile_id
  where pr.content_visible = true
    and pr.account_state <> 'hibernate'
  order by s.share_count desc, s.last_shared_at desc
  limit least(greatest(coalesce(p_limit, 10), 1), 50);
$$;

revoke all on function public.list_post_share_frequent_recipients(int) from public;
grant execute on function public.list_post_share_frequent_recipients(int) to authenticated;

comment on function public.list_post_share_frequent_recipients(int) is
  'Top followed users the current user shared posts with (post_send_events.recipient_id).';

notify pgrst, 'reload schema';
