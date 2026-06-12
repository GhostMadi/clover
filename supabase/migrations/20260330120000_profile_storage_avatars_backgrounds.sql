-- Storage buckets + RLS (avatars & profile_backgrounds) для profiles.avatar_url / background_url.
-- Путь: {auth.uid()}/... — первая папка = владелец (storage.foldername).

-- --------------------------------------------------------------------------- Buckets (create/update)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'avatars',
    'avatars',
    true,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
  ),
  (
    'profile_backgrounds',
    'profile_backgrounds',
    true,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp']::text[]
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- --------------------------------------------------------------------------- Drop previous policy names (идемпотентность / смена имён)
drop policy if exists "avatars_public_read" on storage.objects;
drop policy if exists "avatars_authenticated_insert" on storage.objects;
drop policy if exists "avatars_authenticated_update" on storage.objects;
drop policy if exists "avatars_authenticated_delete" on storage.objects;
drop policy if exists "profile_backgrounds_public_read" on storage.objects;
drop policy if exists "profile_backgrounds_authenticated_insert" on storage.objects;
drop policy if exists "profile_backgrounds_authenticated_update" on storage.objects;
drop policy if exists "profile_backgrounds_authenticated_delete" on storage.objects;

drop policy if exists public_read_avatars on storage.objects;
drop policy if exists public_read_profile_backgrounds on storage.objects;
drop policy if exists avatars_write_own on storage.objects;
drop policy if exists profile_backgrounds_write_own on storage.objects;
drop policy if exists avatars_update_own on storage.objects;
drop policy if exists profile_backgrounds_update_own on storage.objects;
drop policy if exists avatars_delete_own on storage.objects;
drop policy if exists profile_backgrounds_delete_own on storage.objects;

-- --------------------------------------------------------------------------- Policies
-- Public SELECT for downloads/listing
create policy public_read_avatars
  on storage.objects
  for select to public
  using (bucket_id = 'avatars');

create policy public_read_profile_backgrounds
  on storage.objects
  for select to public
  using (bucket_id = 'profile_backgrounds');

-- INSERT
create policy avatars_write_own
  on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

create policy profile_backgrounds_write_own
  on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'profile_backgrounds'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

-- UPDATE (overwrite/upsert)
create policy avatars_update_own
  on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

create policy profile_backgrounds_update_own
  on storage.objects
  for update to authenticated
  using (
    bucket_id = 'profile_backgrounds'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'profile_backgrounds'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

-- DELETE (cleanup)
create policy avatars_delete_own
  on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

create policy profile_backgrounds_delete_own
  on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'profile_backgrounds'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
