-- Booking staff invite RPCs + enrich chat with booking_card.
-- Depends on: 20260908170000_booking_staff_invite_kinds.sql
-- Product: docs/business/booking-staff-plan.md

do $$ begin
  create type public.booking_staff_invite_status as enum (
    'pending',
    'accepted',
    'declined',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.booking_staff_invites (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  invitee_id uuid not null references public.profiles(id) on delete cascade,
  status public.booking_staff_invite_status not null default 'pending',
  staff_id uuid null references public.booking_staff(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  responded_at timestamptz null,
  constraint booking_staff_invites_not_self check (host_id <> invitee_id)
);

create unique index if not exists booking_staff_invites_pending_uniq
  on public.booking_staff_invites (host_id, invitee_id)
  where status = 'pending';

create index if not exists booking_staff_invites_host_status_idx
  on public.booking_staff_invites (host_id, status, created_at desc);

create index if not exists booking_staff_invites_invitee_status_idx
  on public.booking_staff_invites (invitee_id, status, created_at desc);

drop trigger if exists trg_booking_staff_invites_set_updated_at on public.booking_staff_invites;
create trigger trg_booking_staff_invites_set_updated_at
  before update on public.booking_staff_invites
  for each row execute function public.booking_set_updated_at();

alter table public.booking_staff_invites enable row level security;

drop policy if exists booking_staff_invites_select on public.booking_staff_invites;
create policy booking_staff_invites_select
  on public.booking_staff_invites
  for select to authenticated
  using (host_id = auth.uid() or invitee_id = auth.uid());

revoke insert, update, delete on public.booking_staff_invites from authenticated, anon;
grant select on public.booking_staff_invites to authenticated;

-- FK from chat cards → invites (after table exists)
alter table public.chat_message_booking_cards
  drop constraint if exists chat_message_booking_cards_invite_id_fkey;

alter table public.chat_message_booking_cards
  add constraint chat_message_booking_cards_invite_id_fkey
  foreign key (invite_id) references public.booking_staff_invites(id) on delete cascade;

-- --------------------------------------------------------------------------- post card
create or replace function public.booking_post_chat_card(
  p_conversation_id uuid,
  p_sender_id uuid,
  p_payload jsonb,
  p_fallback_text text
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  mid uuid;
  v_card text;
  v_kind public.chat_message_kind;
  v_text text;
  v_invite_id uuid;
  v_host_id uuid;
  v_host_name text;
begin
  if p_conversation_id is null or p_sender_id is null then
    return null;
  end if;

  v_card := coalesce(p_payload->>'card', '');
  if v_card <> 'booking_staff_invite' then
    v_kind := 'system'::public.chat_message_kind;
    v_text := left(coalesce(nullif(trim(p_fallback_text), ''), 'Запись'), 4000);
    insert into public.chat_messages (conversation_id, sender_id, kind, text)
    values (p_conversation_id, p_sender_id, v_kind, v_text)
    returning id into mid;
    return mid;
  end if;

  v_kind := 'booking_staff_invite'::public.chat_message_kind;
  v_invite_id := nullif(p_payload->>'invite_id', '')::uuid;
  v_host_id := nullif(p_payload->>'host_id', '')::uuid;
  v_host_name := coalesce(nullif(trim(p_payload->>'host_display_name'), ''), 'аккаунт');
  v_text := left(coalesce(nullif(trim(p_fallback_text), ''), v_host_name), 4000);

  if v_invite_id is null or v_host_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0020';
  end if;

  insert into public.chat_messages (conversation_id, sender_id, kind, text)
  values (p_conversation_id, p_sender_id, v_kind, v_text)
  returning id into mid;

  insert into public.chat_message_booking_cards (
    message_id, card_type, invite_id, host_id, host_display_name
  ) values (
    mid, v_card, v_invite_id, v_host_id, v_host_name
  );

  return mid;
end;
$$;

revoke all on function public.booking_post_chat_card(uuid, uuid, jsonb, text) from public;

create or replace function public.booking_send_staff_invite_dm(
  p_invite_id uuid,
  p_actor_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_inv public.booking_staff_invites%rowtype;
  v_host_name text;
  v_dm uuid;
begin
  select * into v_inv from public.booking_staff_invites where id = p_invite_id;
  if not found then
    return null;
  end if;

  select coalesce(nullif(trim(full_name), ''), nullif(trim(username), ''), 'аккаунт')
    into v_host_name
  from public.profiles
  where id = v_inv.host_id;

  begin
    v_dm := public.create_dm(v_inv.invitee_id);
    perform public.booking_post_chat_card(
      v_dm,
      p_actor_id,
      jsonb_build_object(
        'v', 1,
        'card', 'booking_staff_invite',
        'invite_id', v_inv.id,
        'host_id', v_inv.host_id,
        'host_display_name', coalesce(v_host_name, 'аккаунт')
      ),
      'Стать исполнителем записи · ' || coalesce(v_host_name, 'аккаунт')
    );
  exception when others then
    v_dm := null;
  end;

  return v_dm;
end;
$$;

revoke all on function public.booking_send_staff_invite_dm(uuid, uuid) from public;

-- --------------------------------------------------------------------------- invite / accept / reject / cancel
create or replace function public.booking_invite_staff(p_profile_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_id uuid;
  v_existing uuid;
begin
  uid := public.booking_assert_authenticated();

  if p_profile_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0020';
  end if;
  if p_profile_id = uid then
    raise exception 'self_booking' using errcode = 'P0027';
  end if;
  if not public.booking_host_has_booking_tag(uid) then
    raise exception 'booking_disabled' using errcode = 'P0025';
  end if;
  if not exists (select 1 from public.profiles p where p.id = p_profile_id) then
    raise exception 'not_found' using errcode = 'P0022';
  end if;

  -- Already linked active staff → nothing to invite
  if exists (
    select 1 from public.booking_staff s
    where s.host_id = uid and s.profile_id = p_profile_id and s.is_active
  ) then
    raise exception 'already_staff' using errcode = 'P0023';
  end if;

  select id into v_existing
  from public.booking_staff_invites
  where host_id = uid and invitee_id = p_profile_id and status = 'pending'
  limit 1;

  if v_existing is not null then
    perform public.booking_send_staff_invite_dm(v_existing, uid);
    return v_existing;
  end if;

  insert into public.booking_staff_invites (host_id, invitee_id, status)
  values (uid, p_profile_id, 'pending')
  returning id into v_id;

  perform public.booking_send_staff_invite_dm(v_id, uid);
  return v_id;
end;
$$;

create or replace function public.booking_accept_staff_invite(p_invite_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_inv public.booking_staff_invites%rowtype;
  v_staff_id uuid;
  v_username text;
  v_full_name text;
  v_display text;
begin
  uid := public.booking_assert_authenticated();

  if p_invite_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0020';
  end if;

  select * into v_inv from public.booking_staff_invites where id = p_invite_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0022';
  end if;
  if v_inv.invitee_id <> uid then
    raise exception 'forbidden' using errcode = 'P0025';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'invalid_status' using errcode = 'P0024';
  end if;

  select username, full_name into v_username, v_full_name
  from public.profiles where id = uid;

  v_display := coalesce(nullif(trim(v_full_name), ''), nullif(trim(v_username), ''), 'Исполнитель');

  select s.id into v_staff_id
  from public.booking_staff s
  where s.host_id = v_inv.host_id and s.profile_id = uid
  limit 1;

  if v_staff_id is null then
    insert into public.booking_staff (host_id, profile_id, display_name, username, is_active)
    values (
      v_inv.host_id,
      uid,
      v_display,
      nullif(trim(v_username), ''),
      true
    )
    returning id into v_staff_id;
  else
    update public.booking_staff
    set is_active = true,
        display_name = v_display,
        username = coalesce(nullif(trim(v_username), ''), username)
    where id = v_staff_id;
  end if;

  update public.booking_staff_invites
  set status = 'accepted',
      staff_id = v_staff_id,
      responded_at = now()
  where id = p_invite_id;

  return v_staff_id;
end;
$$;

create or replace function public.booking_reject_staff_invite(p_invite_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_inv public.booking_staff_invites%rowtype;
begin
  uid := public.booking_assert_authenticated();

  select * into v_inv from public.booking_staff_invites where id = p_invite_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0022';
  end if;
  if v_inv.invitee_id <> uid then
    raise exception 'forbidden' using errcode = 'P0025';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'invalid_status' using errcode = 'P0024';
  end if;

  update public.booking_staff_invites
  set status = 'declined', responded_at = now()
  where id = p_invite_id;
end;
$$;

create or replace function public.booking_cancel_staff_invite(p_invite_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_inv public.booking_staff_invites%rowtype;
begin
  uid := public.booking_assert_authenticated();

  select * into v_inv from public.booking_staff_invites where id = p_invite_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0022';
  end if;
  if v_inv.host_id <> uid then
    raise exception 'forbidden' using errcode = 'P0025';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'invalid_status' using errcode = 'P0024';
  end if;

  update public.booking_staff_invites
  set status = 'cancelled', responded_at = now()
  where id = p_invite_id;
end;
$$;

create or replace function public.list_booking_staff_invites_pending()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
begin
  uid := public.booking_assert_authenticated();

  return query
  select jsonb_build_object(
    'id', i.id,
    'host_id', i.host_id,
    'invitee_id', i.invitee_id,
    'status', i.status,
    'created_at', i.created_at,
    'invitee_display_name', coalesce(nullif(trim(p.full_name), ''), nullif(trim(p.username), ''), ''),
    'invitee_username', p.username,
    'invitee_avatar_url', p.avatar_url
  )
  from public.booking_staff_invites i
  join public.profiles p on p.id = i.invitee_id
  where i.host_id = uid
    and i.status = 'pending'
  order by i.created_at desc;
end;
$$;

revoke all on function public.booking_invite_staff(uuid) from public;
revoke all on function public.booking_accept_staff_invite(uuid) from public;
revoke all on function public.booking_reject_staff_invite(uuid) from public;
revoke all on function public.booking_cancel_staff_invite(uuid) from public;
revoke all on function public.list_booking_staff_invites_pending() from public;

grant execute on function public.booking_invite_staff(uuid) to authenticated;
grant execute on function public.booking_accept_staff_invite(uuid) to authenticated;
grant execute on function public.booking_reject_staff_invite(uuid) to authenticated;
grant execute on function public.booking_cancel_staff_invite(uuid) to authenticated;
grant execute on function public.list_booking_staff_invites_pending() to authenticated;

-- --------------------------------------------------------------------------- enrich chat
drop function if exists public.list_messages_enriched(uuid, int, timestamptz);
drop function if exists public.get_message_enriched(uuid);

create function public.list_messages_enriched(
  p_conversation_id uuid,
  p_limit int default 50,
  p_before timestamptz default null
)
returns table (
  message jsonb,
  sender jsonb,
  reply_preview jsonb,
  reactions jsonb,
  attachments jsonb,
  post_ref jsonb,
  my_reactions jsonb,
  attendance_card jsonb,
  booking_card jsonb
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  with me as (select auth.uid() as uid),
  ok as (
    select public.chat_assert_participant(p_conversation_id) as _
  ),
  base as (
    select m.*
    from public.chat_messages m
    where m.conversation_id = p_conversation_id
      and m.deleted_at is null
      and (p_before is null or m.created_at < p_before)
    order by m.created_at desc, m.id desc
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
  )
  select
    (
      to_jsonb(b.*) || jsonb_build_object(
        'read_by_peer',
        (
          exists (
            select 1
            from public.chat_participants op
            cross join me mm
            where op.conversation_id = b.conversation_id
              and op.user_id <> mm.uid
              and op.left_at is null
          )
          and not exists (
            select 1
            from public.chat_participants pp
            cross join me mm
            left join public.chat_messages rm
              on rm.id = pp.last_read_message_id
             and rm.conversation_id = pp.conversation_id
             and rm.deleted_at is null
            where pp.conversation_id = b.conversation_id
              and pp.user_id <> mm.uid
              and pp.left_at is null
              and (
                pp.last_read_message_id is null
                or rm.id is null
                or (
                  b.created_at > rm.created_at
                  or (b.created_at = rm.created_at and b.id > rm.id)
                )
              )
          )
        )
      )
    ) as message,
    jsonb_build_object('id', pr.id, 'username', pr.username, 'avatar_url', pr.avatar_url) as sender,
    (
      select jsonb_build_object(
        'id', r.id,
        'sender_id', r.sender_id,
        'text', r.text,
        'kind', r.kind::text,
        'created_at', r.created_at
      )
      from public.chat_messages r
      where r.id = b.reply_to_message_id
      limit 1
    ) as reply_preview,
    (
      select coalesce(jsonb_agg(jsonb_build_object('emoji', x.emoji, 'count', x.cnt) order by x.cnt desc), '[]'::jsonb)
      from (
        select emoji, count(*)::int as cnt
        from public.chat_message_reactions rr
        where rr.message_id = b.id
        group by emoji
      ) x
    ) as reactions,
    (
      select coalesce(jsonb_agg(to_jsonb(a.*) order by a.created_at asc), '[]'::jsonb)
      from public.chat_message_attachments a
      where a.message_id = b.id
    ) as attachments,
    public._chat_post_ref_json(b.id) as post_ref,
    public._chat_my_reactions_json(b.id) as my_reactions,
    public._chat_attendance_card_json(b.id) as attendance_card,
    public._chat_booking_card_json(b.id) as booking_card
  from base b
  join public.profiles pr on pr.id = b.sender_id
  order by (b.created_at) asc, b.id asc;
$$;

create function public.get_message_enriched(p_message_id uuid)
returns table (
  message jsonb,
  sender jsonb,
  reply_preview jsonb,
  reactions jsonb,
  attachments jsonb,
  post_ref jsonb,
  my_reactions jsonb,
  attendance_card jsonb,
  booking_card jsonb
)
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  conv uuid;
begin
  select m.conversation_id into conv
  from public.chat_messages m
  where m.id = p_message_id
    and m.deleted_at is null;

  if conv is null then
    raise exception 'message_not_found' using errcode = 'P0014';
  end if;

  perform public.chat_assert_participant(conv);

  return query
  select
    l.message,
    l.sender,
    l.reply_preview,
    l.reactions,
    l.attachments,
    l.post_ref,
    l.my_reactions,
    l.attendance_card,
    l.booking_card
  from public.list_messages_enriched(conv, 200, null) l
  where (l.message->>'id')::uuid = p_message_id
  limit 1;
end;
$$;

revoke all on function public.list_messages_enriched(uuid, int, timestamptz) from public;
revoke all on function public.get_message_enriched(uuid) from public;
grant execute on function public.list_messages_enriched(uuid, int, timestamptz) to authenticated;
grant execute on function public.get_message_enriched(uuid) to authenticated;

notify pgrst, 'reload schema';
