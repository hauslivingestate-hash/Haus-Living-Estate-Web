-- Phase-4-style checks, run as each persona inside a rolled-back transaction.
\pset format unaligned
\pset tuples_only on
\set ON_ERROR_STOP 0

create temp table personas as
select employee_code, nickname, auth_user_id from main_1_hr
where employee_code in ('S-003', 'E-001') or (position = 'Marketing' and auth_user_id is not null);
grant select on personas to authenticated;

select 'persona|' || employee_code || '|' || nickname || '|' || (auth_user_id is not null) from personas order by 1;


-- one block per persona
select format($f$
begin;
select set_config('request.jwt.claims', %L, true);
set local role authenticated;
select 'as|%s|me=' || coalesce(current_employee_code(), 'null')
  || '|listings=' || (select count(*) from main_4_listing_database)
  || '|leads=' || (select count(*) from main_6_buyer_crm)
  || '|others_leads=' || (select count(*) from main_6_buyer_crm where sale_id is distinct from current_employee_code())
  || '|last_match=' || (select count(*) from main_7_last_match)
  || '|activities=' || (select count(*) from activities)
  || '|owners=' || (select count(*) from main_2_owner)
  || '|salary_visible=' || (select count(salary) from v_employee_private)
  || '|perms=' || (select count(*) from my_permissions());
rollback;
$f$, json_build_object('sub', auth_user_id, 'role', 'authenticated')::text, employee_code)
from personas where auth_user_id is not null order by employee_code
\gexec

-- agent write attempts that must affect 0 rows / fail
select format($f$
begin;
select set_config('request.jwt.claims', %L, true);
set local role authenticated;
with u as (update main_6_buyer_crm set sale_id = current_employee_code() where sale_id <> current_employee_code() returning 1)
select 'neg|steal_leads_rows=' || count(*) from u;
with d as (delete from main_4_listing_database returning 1) select 'neg|delete_listings_rows=' || count(*) from d;
rollback;
$f$, json_build_object('sub', auth_user_id, 'role', 'authenticated')::text)
from personas where employee_code = 'S-003'
\gexec

-- base-table salary must be denied outright for authenticated
begin;
set local role authenticated;
select 'neg|base_salary=' || count(salary) from main_1_hr;
rollback;

-- anon must be denied everywhere
begin;
set local role anon;
select 'neg|anon_listings=' || count(*) from main_4_listing_database;
rollback;
begin;
set local role anon;
select 'neg|anon_hr=' || count(*) from main_1_hr;
rollback;
begin;
set local role anon;
select 'neg|anon_has_perm=' || public.has_perm('roles.manage');
rollback;
