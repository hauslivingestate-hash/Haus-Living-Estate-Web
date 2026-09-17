-- Prints one line per fact; run against both projects and diff the output.
set timezone = 'UTC';
set extra_float_digits = 3;
\pset format unaligned
\pset tuples_only on

-- 1. Row count + content hash of every table that holds app data
select format($q$select 'DATA|%s.%s|' || count(*) || '|' || md5(coalesce(string_agg(t::text, E'\n' order by t::text), '')) from %I.%I t$q$,
              n.nspname, c.relname, n.nspname, c.relname)
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where c.relkind = 'r' and n.nspname = 'public'
order by 1
\gexec

-- Storage: compare what identifies a file, not the row. Files are re-uploaded through the
-- storage API rather than copied as rows, so ids, owners and timestamps are new by design.
select 'BUCKET|' || id || '|public=' || public || '|limit=' || coalesce(file_size_limit::text, '') || '|' || coalesce(array_to_string(allowed_mime_types, ','), '') from storage.buckets order by id;
select 'STORFILE|' || bucket_id || '/' || name || '|' || coalesce(metadata->>'size', '?') || '|' || coalesce(metadata->>'mimetype', '?') from storage.objects order by bucket_id, name;

-- Migration history: the CLI skips a version it already sees here, so it has to come across
-- or the next `supabase db push` replays every migration against the new project.
select 'MIGR|' || count(*) || '|' || coalesce(max(version), '') from supabase_migrations.schema_migrations;

-- auth: compare the columns that matter (ids, emails, password hashes), not bookkeeping timestamps
select 'AUTHUSER|' || id || '|' || coalesce(email, '') || '|' || md5(coalesce(encrypted_password, '')) || '|' || (email_confirmed_at is not null) || '|' || coalesce(raw_app_meta_data::text, '') from auth.users order by id;
select 'AUTHIDENT|' || id || '|' || user_id || '|' || provider || '|' || provider_id from auth.identities order by id;

-- 2. Relation-level grants + RLS flags
select 'REL|' || c.relname || '|' || c.relkind::text || '|rls=' || c.relrowsecurity || '|force=' || c.relforcerowsecurity || '|' || coalesce(c.relacl::text, '<default>') || '|owner=' || pg_get_userbyid(c.relowner)
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind in ('r', 'v', 'm', 'S') order by c.relname;

-- 3. Column-level grants (main_1_hr salary/PII lives here)
select 'COLACL|' || c.relname || '.' || a.attname || '|' || a.attacl::text
from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and a.attnum > 0 and not a.attisdropped and a.attacl is not null order by 1;

-- 4. Columns: type, default, nullability, generated/identity
select 'COL|' || table_name || '.' || column_name || '|' || data_type || '|' || coalesce(column_default, '') || '|' || is_nullable || '|' || coalesce(is_generated, '') || '|' || coalesce(identity_generation, '')
from information_schema.columns where table_schema = 'public' order by table_name, ordinal_position;

-- 5. Functions: body, security definer, config, grants
select 'FN|' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')|secdef=' || p.prosecdef || '|' || coalesce(array_to_string(p.proconfig, ','), '') || '|' || coalesce(p.proacl::text, '<default>') || '|' || md5(pg_get_functiondef(p.oid))
from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' order by 1;

-- 6. Policies (public + storage)
select 'POL|' || schemaname || '.' || tablename || '|' || policyname || '|' || permissive || '|' || cmd || '|' || array_to_string(roles, ',') || '|' || coalesce(qual, '') || '|' || coalesce(with_check, '')
from pg_policies where schemaname in ('public', 'storage') order by 1;

-- 7. Triggers (definition + enabled state)
select 'TRG|' || c.relname || '|' || t.tgname || '|' || t.tgenabled::text || '|' || pg_get_triggerdef(t.oid)
from pg_trigger t join pg_class c on c.oid = t.tgrelid join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and not t.tgisinternal order by 1;

-- 8. Constraints + indexes
select 'CON|' || conrelid::regclass || '|' || conname || '|' || pg_get_constraintdef(oid)
from pg_constraint where connamespace = 'public'::regnamespace order by 1;
select 'IDX|' || indexname || '|' || indexdef from pg_indexes where schemaname = 'public' order by 1;

-- 9. Views
select 'VIEW|' || c.relname || '|' || coalesce(array_to_string(c.reloptions, ','), '') || '|' || md5(pg_get_viewdef(c.oid))
from pg_class c where c.relnamespace = 'public'::regnamespace and c.relkind = 'v' order by 1;

-- 10. Sequence positions
select 'SEQ|' || schemaname || '.' || sequencename || '|' || coalesce(last_value::text, 'null') from pg_sequences where schemaname = 'public' order by 1;

-- 11. Default privileges, cron, event triggers, schema grants
select 'DEFACL|' || pg_get_userbyid(d.defaclrole) || '|' || coalesce(n.nspname, '*') || '|' || d.defaclobjtype::text || '|' || d.defaclacl::text
from pg_default_acl d left join pg_namespace n on n.oid = d.defaclnamespace
where coalesce(n.nspname, '*') in ('public', 'storage', 'auth', '*') order by 1;
select 'CRON|' || jobname || '|' || schedule || '|' || trim(command) || '|' || active from cron.job order by 1;
select 'EVT|' || evtname || '|' || evtevent || '|' || evtenabled::text || '|' || evtfoid::regproc::text || '|' || coalesce(array_to_string(evttags, ','), '') from pg_event_trigger order by 1;
select 'NSP|' || nspname || '|' || coalesce(nspacl::text, '') from pg_namespace where nspname in ('public', 'storage') order by 1;
