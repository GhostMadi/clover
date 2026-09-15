-- Allow FCM web tokens on the same table mobile uses (ios|android|web).
-- Unique (user_id, platform) already keeps one active token per platform.

alter table public.push_device_tokens
  drop constraint if exists push_device_tokens_platform_check;

alter table public.push_device_tokens
  add constraint push_device_tokens_platform_check
  check (platform in ('ios', 'android', 'web'));

comment on constraint push_device_tokens_user_platform_unique on public.push_device_tokens is
  'MVP: one active FCM token per user per platform (ios|android|web); rotations replace.';
