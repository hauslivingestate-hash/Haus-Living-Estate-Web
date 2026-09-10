-- Final sync, step 1 (runs on NEW inside the same transaction as the data load).
-- Empties every app table + the migrated accounts so the fresh dump from OLD can be loaded
-- on top. Structure, grants, policies, cron and the bucket are untouched: they were verified
-- identical in the rehearsal and a data reload doesn't change them.
set session_replication_role = replica;
select 'truncate table ' || string_agg(format('%I.%I', schemaname, tablename), ', ') || ';'
from pg_tables where schemaname = 'public'
\gexec
delete from auth.identities;
delete from auth.users;
