-- Run on NEW before restoring the schema (safe to re-run).
--
-- 1. A fresh Supabase project auto-grants ALL to anon/authenticated/service_role on every object
--    postgres creates in public. pg_dump only emits the grants that differ from the owner-only
--    default, so restoring on top of those defaults would silently re-open every revoke from
--    Phase 4 (including SELECT on main_1_hr's salary/PII columns). Switch them off for the restore;
--    post.sql puts them back.
-- 2. Objects outside public that depend on public functions block `pg_restore --clean` from
--    dropping those functions. Drop them here; extras.sql recreates them from the old project.
create extension if not exists pg_cron with schema pg_catalog;
alter default privileges for role postgres in schema public revoke all on tables    from anon, authenticated, service_role;
alter default privileges for role postgres in schema public revoke all on functions from anon, authenticated, service_role;
alter default privileges for role postgres in schema public revoke all on sequences from anon, authenticated, service_role;
drop event trigger if exists ensure_rls;
do $$
declare p record;
begin
  for p in select policyname from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'listing\_photos\_%' loop
    execute format('drop policy %I on storage.objects', p.policyname);
  end loop;
end $$;
