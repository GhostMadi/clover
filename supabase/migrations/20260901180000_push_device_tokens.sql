-- FCM device tokens per user (client upsert; server sends push in v2).

create table if not exists public.push_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios', 'android')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint push_device_tokens_user_token_unique unique (user_id, token)
);

create index if not exists push_device_tokens_user_id_idx
  on public.push_device_tokens (user_id);

create index if not exists push_device_tokens_token_idx
  on public.push_device_tokens (token);

alter table public.push_device_tokens enable row level security;

drop policy if exists push_device_tokens_select_own on public.push_device_tokens;
create policy push_device_tokens_select_own
  on public.push_device_tokens
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists push_device_tokens_insert_own on public.push_device_tokens;
create policy push_device_tokens_insert_own
  on public.push_device_tokens
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists push_device_tokens_update_own on public.push_device_tokens;
create policy push_device_tokens_update_own
  on public.push_device_tokens
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists push_device_tokens_delete_own on public.push_device_tokens;
create policy push_device_tokens_delete_own
  on public.push_device_tokens
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on public.push_device_tokens to authenticated;
