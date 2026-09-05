-- После 20260830110000 (drop profiles.category_code) на remote могли остаться
-- триггеры/функции с NEW.category_code → INSERT posts падает с 42703.
-- Симптom: record "new" has no field "category_code" (часто через UPDATE profiles.post_count).

do $cleanup$
declare
  r record;
begin
  for r in
    select
      t.tgname as trigger_name,
      n.nspname as schema_name,
      c.relname as table_name
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_proc p on p.oid = t.tgfoid
    where n.nspname = 'public'
      and not t.tgisinternal
      and coalesce(p.prosrc, '') ilike '%category_code%'
  loop
    execute format(
      'drop trigger if exists %I on %I.%I',
      r.trigger_name,
      r.schema_name,
      r.table_name
    );
    raise notice 'Dropped trigger % on %.%', r.trigger_name, r.schema_name, r.table_name;
  end loop;

  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and coalesce(p.prosrc, '') ilike '%category_code%'
  loop
    execute format('drop function if exists %s cascade', r.sig);
    raise notice 'Dropped function %', r.sig;
  end loop;
end
$cleanup$;

notify pgrst, 'reload schema';
