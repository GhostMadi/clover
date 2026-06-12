-- Rename markers.title -> address_text (it's an address, not an event title).
-- Keep backward-compatible: if already renamed, do nothing.

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'markers'
      and column_name = 'title'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'markers'
      and column_name = 'address_text'
  ) then
    execute 'alter table public.markers rename column title to address_text';
  end if;
end $$;

comment on column public.markers.address_text is
  'Адрес/место события (текст). Раньше называлось title, но это вводило в заблуждение.';

notify pgrst, 'reload schema';

