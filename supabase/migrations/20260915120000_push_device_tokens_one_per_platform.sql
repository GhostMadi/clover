-- One FCM token per user+platform (stale rotations caused duplicate tray pushes).
-- Spec: docs/supabase/SPEC_PUSH_FCM.md

-- Keep newest row per (user_id, platform); drop older rotations.
delete from public.push_device_tokens t
using public.push_device_tokens newer
where t.user_id = newer.user_id
  and t.platform = newer.platform
  and t.id <> newer.id
  and (
    newer.updated_at > t.updated_at
    or (newer.updated_at = t.updated_at and newer.id > t.id)
  );

drop index if exists public.push_device_tokens_user_platform_unique;
alter table public.push_device_tokens
  drop constraint if exists push_device_tokens_user_platform_unique;

alter table public.push_device_tokens
  add constraint push_device_tokens_user_platform_unique unique (user_id, platform);

comment on constraint push_device_tokens_user_platform_unique on public.push_device_tokens is
  'MVP: one active FCM token per user per platform (ios|android); rotations replace.';
