-- Fix booking_service payload on post detail when RLS in nested SQL subquery is too strict.

create or replace function public.booking_service_enriched_json(p_service_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case
    when p_service_id is null then 'null'::jsonb
    else coalesce(
      (
        select jsonb_build_object(
          'id', bs.id,
          'title', bs.title,
          'emoji_text', bs.emoji_text,
          'price', bs.price,
          'duration_minutes', bs.duration_minutes,
          'is_active', bs.is_active
        )
        from public.booking_services bs
        where bs.id = p_service_id
          and (
            bs.host_id = auth.uid()
            or exists (
              select 1
              from public.posts p
              where p.booking_service_id = bs.id
                and p.deleted_at is null
            )
          )
      ),
      'null'::jsonb
    )
  end;
$$;

comment on function public.booking_service_enriched_json(uuid) is
  'Booking service subtree for post detail; explicit visibility (host or linked visible post).';

revoke all on function public.booking_service_enriched_json(uuid) from public;
grant execute on function public.booking_service_enriched_json(uuid) to authenticated, anon;

notify pgrst, 'reload schema';
