-- Booking staff invite: chat kind + card ref table.
-- Follow-up RPCs: 20260908171000_booking_staff_invite_rpc.sql
-- Product: docs/business/booking-staff-plan.md

do $$ begin
  alter type public.chat_message_kind add value if not exists 'booking_staff_invite';
exception when duplicate_object then null;
end $$;

create table if not exists public.chat_message_booking_cards (
  message_id uuid primary key references public.chat_messages(id) on delete cascade,
  card_type text not null check (card_type in ('booking_staff_invite')),
  invite_id uuid not null,
  host_id uuid not null references public.profiles(id) on delete cascade,
  host_display_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists chat_message_booking_cards_host_idx
  on public.chat_message_booking_cards (host_id);

create index if not exists chat_message_booking_cards_invite_idx
  on public.chat_message_booking_cards (invite_id);

alter table public.chat_message_booking_cards enable row level security;

drop policy if exists chat_booking_cards_select on public.chat_message_booking_cards;
create policy chat_booking_cards_select on public.chat_message_booking_cards
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

revoke insert, update, delete on public.chat_message_booking_cards from authenticated, anon;

create or replace function public._chat_booking_card_json(p_message_id uuid)
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
    'invite_id', c.invite_id,
    'host_id', c.host_id,
    'host_display_name', c.host_display_name
  )
  from public.chat_message_booking_cards c
  where c.message_id = p_message_id
  limit 1;
$$;

revoke all on function public._chat_booking_card_json(uuid) from public;
