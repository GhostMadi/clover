-- Attendance rich chat: enum kinds + ref table (commit before functions use new values).
-- Follow-up: 20260905210100_attendance_rich_chat_reinvite_corrections_list.sql
-- Process: docs/business/attendance.md

do $$ begin
  alter type public.chat_message_kind add value if not exists 'attendance_invite';
exception when duplicate_object then null;
end $$;

do $$ begin
  alter type public.chat_message_kind add value if not exists 'attendance_rules';
exception when duplicate_object then null;
end $$;

create table if not exists public.chat_message_attendance_cards (
  message_id uuid primary key references public.chat_messages(id) on delete cascade,
  card_type text not null check (card_type in ('attendance_invite', 'attendance_rules')),
  workplace_id uuid not null references public.attendance_workplaces(id) on delete cascade,
  membership_id uuid null references public.attendance_memberships(id) on delete set null,
  workplace_name text not null,
  config_version int null,
  created_at timestamptz not null default now()
);

create index if not exists chat_message_attendance_cards_workplace_idx
  on public.chat_message_attendance_cards (workplace_id);

alter table public.chat_message_attendance_cards enable row level security;

drop policy if exists chat_attendance_cards_select on public.chat_message_attendance_cards;
create policy chat_attendance_cards_select on public.chat_message_attendance_cards
  for select to authenticated
  using (
    exists (
      select 1
      from public.chat_messages m
      join public.chat_participants p on p.conversation_id = m.conversation_id
      where m.id = message_id
        and p.user_id = auth.uid()
        and p.left_at is null
    )
  );

revoke insert, update, delete on public.chat_message_attendance_cards from authenticated, anon;

create or replace function public._chat_attendance_card_json(p_message_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select jsonb_build_object(
    'v', 1,
    'card', c.card_type,
    'workplace_id', c.workplace_id,
    'workplace_name', c.workplace_name,
    'membership_id', c.membership_id,
    'config_version', c.config_version
  )
  from public.chat_message_attendance_cards c
  where c.message_id = p_message_id
  limit 1;
$$;

revoke all on function public._chat_attendance_card_json(uuid) from public;
