-- Support requests from public website form (App Store / users).
-- Product: docs/business/support.md · Spec: docs/supabase/SPEC_SUPPORT_REQUESTS.md

create table if not exists public.support_requests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  contact text not null,
  message text not null,
  user_id uuid references auth.users (id) on delete set null,
  source text not null default 'web',
  status text not null default 'new',
  constraint support_requests_contact_len check (
    char_length(trim(contact)) between 2 and 200
  ),
  constraint support_requests_message_len check (
    char_length(trim(message)) between 10 and 4000
  ),
  constraint support_requests_source_check check (source in ('web', 'app')),
  constraint support_requests_status_check check (status in ('new', 'in_progress', 'done'))
);

create index if not exists support_requests_created_at_idx
  on public.support_requests (created_at desc);

create index if not exists support_requests_status_idx
  on public.support_requests (status);

alter table public.support_requests enable row level security;

drop policy if exists support_requests_insert on public.support_requests;
create policy support_requests_insert
  on public.support_requests
  for insert
  to anon, authenticated
  with check (
    (user_id is null or user_id = auth.uid())
    and status = 'new'
    and source in ('web', 'app')
  );

revoke select, update, delete on public.support_requests from anon, authenticated;
grant insert on public.support_requests to anon, authenticated;
grant select, update, delete on public.support_requests to service_role;
