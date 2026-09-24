-- Fix: block_user 409 when an open content_report already exists (e.g. prior report).
-- Dedupe index is on (reporter, target) for open+null post regardless of source.

create or replace function public.block_user(
  p_target uuid,
  p_reason text default 'abusive_user',
  p_post_id uuid default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_reason text := coalesce(nullif(trim(p_reason), ''), 'abusive_user');
  v_note text := nullif(trim(p_note), '');
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_target is null or p_target = uid then
    raise exception 'cannot_block_self' using errcode = 'P0007';
  end if;

  if not exists (select 1 from public.profiles pr where pr.id = p_target) then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;

  if v_reason not in (
    'objectionable_content', 'abusive_user', 'spam', 'harassment', 'other'
  ) then
    v_reason := 'abusive_user';
  end if;

  if p_post_id is not null and not exists (
    select 1 from public.posts p
    where p.id = p_post_id and p.user_id = p_target and p.deleted_at is null
  ) then
    p_post_id := null;
  end if;

  if v_note is not null and char_length(v_note) > 500 then
    v_note := left(v_note, 500);
  end if;

  insert into public.profile_blocks (blocker_id, blocked_id)
  values (uid, p_target)
  on conflict do nothing;

  delete from public.profile_follows
  where (follower_id = uid and following_id = p_target)
     or (follower_id = p_target and following_id = uid);

  -- Notify developer; skip if any open report already covers this target/post
  -- (unique index content_reports_open_* is source-agnostic).
  if not exists (
    select 1
    from public.content_reports r
    where r.reporter_id = uid
      and r.target_user_id = p_target
      and r.status = 'open'
      and (
        (p_post_id is null and r.target_post_id is null)
        or r.target_post_id is not distinct from p_post_id
      )
  ) then
    insert into public.content_reports (
      reporter_id, target_user_id, target_post_id, reason_code, source, note
    )
    values (uid, p_target, p_post_id, v_reason, 'block', v_note);
  else
    -- Mark that a block also happened (keep original report row).
    update public.content_reports r
    set note = case
          when v_note is not null and (r.note is null or length(trim(r.note)) = 0) then v_note
          when v_note is not null then left(r.note || ' | block: ' || v_note, 500)
          when r.source = 'report' and (r.note is null or position('blocked' in lower(r.note)) = 0)
            then left(coalesce(r.note || ' | ', '') || 'blocked', 500)
          else r.note
        end
    where r.reporter_id = uid
      and r.target_user_id = p_target
      and r.status = 'open'
      and (
        (p_post_id is null and r.target_post_id is null)
        or r.target_post_id is not distinct from p_post_id
      );
  end if;
end;
$$;

comment on function public.block_user(uuid, text, uuid, text) is
  'Block target, unfollow both ways; content_reports source=block or reuse open report.';

notify pgrst, 'reload schema';
