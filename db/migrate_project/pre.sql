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
  for p in select policyname from pg_policies where schemaname = 'storage' and tablename = 'objects' loop
    execute format('drop policy %I on storage.objects', p.policyname);
  end loop;
end $$;

-- 3. Empty out `public` so the restore lands on bare ground.
--    `pg_restore --clean` cannot do this job: it emits DROP POLICY ... ON <table> for every
--    policy in the dump, and a policy's IF EXISTS does not cover a *table* that the target has
--    never had - so the first table added since the last copy aborts the whole restore.
do $$
declare r record;
begin
  for r in select format('drop table if exists %I.%I cascade', schemaname, tablename) c from pg_tables where schemaname = 'public' loop execute r.c; end loop;
  for r in select format('drop view if exists %I.%I cascade', schemaname, viewname) c from pg_views where schemaname = 'public' loop execute r.c; end loop;
  for r in select format('drop materialized view if exists %I.%I cascade', schemaname, matviewname) c from pg_matviews where schemaname = 'public' loop execute r.c; end loop;
  for r in select format('drop routine if exists %s cascade', p.oid::regprocedure) c from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' loop execute r.c; end loop;
  for r in select format('drop sequence if exists %I.%I cascade', schemaname, sequencename) c from pg_sequences where schemaname = 'public' loop execute r.c; end loop;
  for r in select format('drop type if exists %I.%I cascade', n.nspname, t.typname) c from pg_type t join pg_namespace n on n.oid = t.typnamespace where n.nspname = 'public' and t.typtype in ('e', 'd') loop execute r.c; end loop;
end $$;
