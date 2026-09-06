-- Drop booking_reviews: product decision — no in-app reviews after visit.
-- Client can leave feedback outside the app later; schema unused (no RPC/UI).

drop policy if exists booking_reviews_select on public.booking_reviews;

revoke all on table public.booking_reviews from authenticated;
revoke all on table public.booking_reviews from anon;
revoke all on table public.booking_reviews from service_role;

drop table if exists public.booking_reviews cascade;

notify pgrst, 'reload schema';
