-- Generates the DDL for everything outside `public` that the app relies on.
select format('create policy %I on %I.%I as %s for %s to %s%s%s;',
         policyname, schemaname, tablename, permissive, cmd,
         array_to_string(roles, ', '),
         case when qual is not null then ' using (' || qual || ')' else '' end,
         case when with_check is not null then ' with check (' || with_check || ')' else '' end)
from pg_policies where schemaname = 'storage'
union all
select format('select cron.schedule(%L, %L, %L);', jobname, schedule, trim(command))
from cron.job
union all
select format('create event trigger %I on %s%s execute function %s();',
         evtname, evtevent,
         case when evttags is not null then ' when tag in (' || (select string_agg(quote_literal(t), ', ') from unnest(evttags) t) || ')' else '' end,
         evtfoid::regproc)
from pg_event_trigger where evtname = 'ensure_rls';
