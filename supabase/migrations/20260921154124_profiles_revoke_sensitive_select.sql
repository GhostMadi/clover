-- Restrict sensitive profiles columns from PostgREST (anon / authenticated).
-- Product: docs/business/profile-data.md
-- Own email/phone: Auth session on clients. is_site_admin: RPC / service_role only.
-- Column GRANT is table-wide for allowed rows under RLS; hiding columns requires revoke.

revoke select on table public.profiles from anon, authenticated;

grant select (
  id,
  full_name,
  username,
  country_code,
  city_code,
  avatar_url,
  background_url,
  bio,
  followers_count,
  following_count,
  cluster_count,
  post_count,
  created_at,
  updated_at,
  username_change_count,
  username_next_change_allowed_at,
  account_state,
  content_visible,
  reset_at,
  last_reset_at,
  last_hibernate_at,
  has_filters,
  tag_link_id
) on table public.profiles to anon, authenticated;

comment on column public.profiles.email is
  'Mirror / admin; not selectable by anon/authenticated via PostgREST. Clients use Auth session.';
comment on column public.profiles.phone is
  'Mirror from Auth; not selectable by anon/authenticated via PostgREST.';
comment on column public.profiles.is_site_admin is
  'Site admin flag; not selectable by anon/authenticated. Use is_site_admin() RPC or service_role.';
