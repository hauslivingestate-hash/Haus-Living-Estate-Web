-- ============================================================
-- HAUS LIVING ESTATE — RLS POLICIES (Phase 4)
-- ✅ รันบน production แล้ว 2026-08-03 (ทดสอบครบทั้ง anon / agent / admin / marketing / trigger)
-- รันไฟล์นี้ "หลัง" supabase_full_setup.sql + หลังมีตาราง RBAC (permissions/roles/user_roles)
-- รันซ้ำได้ (drop policy if exists ทุกอัน) — ไม่มีคำสั่งที่แตะข้อมูลสักบรรทัด
--
-- หลักการ
--   1) anon (คนที่ยังไม่ล็อกอิน) = อ่านไม่ได้เลยสักตาราง  ← ปิด demo_read_all ที่เปิดค้างไว้
--   2) authenticated = เห็นเท่าที่ "สิทธิ์ใน RBAC" อนุญาต — ใช้ has_perm() ตัวเดียวกับที่ UI ใช้ซ่อนเมนู
--      → สิ่งที่หน้าเว็บซ่อน กับสิ่งที่ DB ปฏิเสธ จึงตรงกันเสมอ
--   3) ขอบเขต own / team / all มาจาก visible_employee_codes()
--   4) ทุก policy มีทางออกฉุกเฉิน has_perm('roles.manage') (system_admin/ceo) กันล็อกตัวเองออก
--
-- ⚠️ ข้อจำกัดที่รู้ตัว: RLS กรองได้แค่ "แถว" กรอง "คอลัมน์" ไม่ได้
--    - เงินเดือน/PII ของ main_1_hr กันด้วย GRANT ระดับคอลัมน์ (ทำไปแล้ว) + view v_employee_private
--    - role marketing มีแค่ listings.marketing แต่ policy ให้ update ทั้งแถว → แก้ราคาได้ด้วย
--      ถ้าจะกันต้องใช้ column-level grant ซึ่งแยกรายคนไม่ได้ (grant ผูกกับ role authenticated ทั้งก้อน)
--      ทางแก้จริงคือทำ RPC เฉพาะคอลัมน์การตลาด — ยังไม่ทำ
-- ============================================================


-- ============================================================
-- 0) ล้าง policy ชุดเดิม (demo_read_all = อ่านได้ทุกอย่างไม่ต้องล็อกอิน, admin_write)
--    + policy ชุดใหม่ทั้งหมด เพื่อให้รันไฟล์ซ้ำได้
-- ============================================================
do $do$
declare t text;
begin
  for t in
    select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
  loop
    execute format('drop policy if exists demo_read_all on public.%I', t);
    execute format('drop policy if exists admin_write   on public.%I', t);
    execute format('drop policy if exists p_select      on public.%I', t);
    execute format('drop policy if exists p_insert      on public.%I', t);
    execute format('drop policy if exists p_update      on public.%I', t);
    execute format('drop policy if exists p_delete      on public.%I', t);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end
$do$;


-- ============================================================
-- 1) ถอนสิทธิ์ anon ออกจากทุกตาราง/วิว
--    anon key ฝังอยู่ในหน้าเว็บ (public โดยธรรมชาติ) → ถ้าไม่ถอน ใครก็ยิง REST อ่านได้
--    ถอน GRANT ด้วย ไม่ใช่แค่ policy → ขอมาจะได้ 42501 ชัด ๆ แทนที่จะได้ [] เงียบ ๆ
-- ============================================================
do $do$
declare t text;
begin
  for t in
    select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r','v')
  loop
    execute format('revoke all on public.%I from anon', t);
  end loop;
end
$do$;


-- ============================================================
-- 2) ตาราง lookup / อ้างอิง — ล็อกอินแล้วอ่านได้หมด (เป็นแค่ dropdown)
--    แยกกลุ่มตามว่า "ใครมีสิทธิ์แก้"
-- ============================================================
do $do$
declare
  t   text;
  grp record;
begin
  for grp in
    select * from (values
      -- รายการอ้างอิง (dropdown ทั่วไป)
      (array['gender','nationality','potential','lead_status','pipeline_stage','bank_loan',
             'lead_type','complain_status','marketing_channel','contact_by','employee_status',
             'job_position','second_position','listing_status','listing_type','property_type',
             'in_out_project','direction','view_type','unit_position','price_remark',
             'unit_condition','close_type','listing_potential'],
       $q$ (select has_perm('reference.manage')) or (select has_perm('masterdata.govern')) or (select has_perm('roles.manage')) $q$),
      -- ข้อมูลหลักที่ CEO/หัวหน้าคุม (โซน · ประเภทกิจกรรม · แท็กลีด)
      (array['action_type','lead_tags_ref','zone','zone_sales'],
       $q$ (select has_perm('masterdata.govern')) or (select has_perm('roles.manage')) $q$),
      -- นิยาม RBAC — แก้ได้เฉพาะคนจัดการสิทธิ์
      (array['permissions','roles','role_permissions'],
       $q$ (select has_perm('roles.manage')) $q$),
      -- ประเภท/โควตาวันลา
      (array['leave_type','leave_allowances'],
       $q$ (select has_perm('leave.manage')) or (select has_perm('roles.manage')) $q$)
    ) as g(tables, write_expr)
  loop
    foreach t in array grp.tables loop
      execute format('create policy p_select on public.%I for select to authenticated using (true)', t);
      execute format('create policy p_insert on public.%I for insert to authenticated with check (%s)', t, grp.write_expr);
      execute format('create policy p_update on public.%I for update to authenticated using (%s) with check (%s)', t, grp.write_expr, grp.write_expr);
      execute format('create policy p_delete on public.%I for delete to authenticated using (%s)', t, grp.write_expr);
    end loop;
  end loop;
end
$do$;


-- ============================================================
-- 3) พนักงาน / ทีม / บทบาท
-- ============================================================

-- main_1_hr: ล็อกอินแล้วเห็นรายชื่อเพื่อนร่วมงานได้ (ทำเนียบพนักงาน)
-- เงินเดือน/บัตรประชาชน/บัญชีธนาคาร ไม่ได้กันตรงนี้ — กันด้วย GRANT ระดับคอลัมน์ไปแล้ว
create policy p_select on public.main_1_hr for select to authenticated using (true);
create policy p_insert on public.main_1_hr for insert to authenticated
  with check ((select has_perm('people.manage')) or (select has_perm('roles.manage')));
create policy p_update on public.main_1_hr for update to authenticated
  using      ((select has_perm('people.manage')) or (select has_perm('roles.manage')))
  with check ((select has_perm('people.manage')) or (select has_perm('roles.manage')));
create policy p_delete on public.main_1_hr for delete to authenticated
  using ((select has_perm('roles.manage')));

create policy p_select on public.teams for select to authenticated using (true);
create policy p_insert on public.teams for insert to authenticated
  with check ((select has_perm('teams.manage')) or (select has_perm('roles.manage')));
create policy p_update on public.teams for update to authenticated
  using      ((select has_perm('teams.manage')) or (select has_perm('roles.manage')))
  with check ((select has_perm('teams.manage')) or (select has_perm('roles.manage')));
create policy p_delete on public.teams for delete to authenticated
  using ((select has_perm('teams.manage')) or (select has_perm('roles.manage')));

-- user_roles: ใครถือสิทธิ์อะไร = ข้อมูลอ่อนไหว → เห็นของตัวเอง หรือคนที่คุมสิทธิ์/บุคคล
-- (lib/auth.ts อ่านของตัวเองผ่าน policy นี้)
create policy p_select on public.user_roles for select to authenticated
  using (employee_code = (select current_employee_code())
         or (select has_perm('roles.manage')) or (select has_perm('people.manage')));
create policy p_insert on public.user_roles for insert to authenticated
  with check ((select has_perm('roles.manage')));
create policy p_update on public.user_roles for update to authenticated
  using ((select has_perm('roles.manage'))) with check ((select has_perm('roles.manage')));
create policy p_delete on public.user_roles for delete to authenticated
  using ((select has_perm('roles.manage')));


-- ============================================================
-- 4) คลังทรัพย์ — ทรัพย์เป็นของบริษัท ใครมี listings.view ก็เห็นทั้งหมด
--    (หน้า "ทรัพย์ทั้งบริษัท" ตั้งใจให้เป็นแบบนี้) แต่ "แก้" ต้องมีสิทธิ์แยก
-- ============================================================

create policy p_select on public.main_4_listing_database for select to authenticated
  using ((select has_perm('listings.view')));
create policy p_insert on public.main_4_listing_database for insert to authenticated
  with check ((select has_perm('listings.create')) or (select has_perm('roles.manage')));
create policy p_update on public.main_4_listing_database for update to authenticated
  using      ((select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')))
  with check ((select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));
create policy p_delete on public.main_4_listing_database for delete to authenticated
  using ((select has_perm('roles.manage')));

-- โครงการ
create policy p_select on public.main_3_property_detail for select to authenticated
  using ((select has_perm('listings.view')));
create policy p_insert on public.main_3_property_detail for insert to authenticated
  with check ((select has_perm('projects.edit')) or (select has_perm('listings.create')) or (select has_perm('roles.manage')));
create policy p_update on public.main_3_property_detail for update to authenticated
  using      ((select has_perm('projects.edit')) or (select has_perm('roles.manage')))
  with check ((select has_perm('projects.edit')) or (select has_perm('roles.manage')));
create policy p_delete on public.main_3_property_detail for delete to authenticated
  using ((select has_perm('roles.manage')));

-- เจ้าของทรัพย์ (เบอร์/ไลน์ = PII) — ใครดูทรัพย์ได้ก็ต้องติดต่อเจ้าของได้
create policy p_select on public.main_2_owner for select to authenticated
  using ((select has_perm('listings.view')) or (select has_perm('contacts.view_all')));
create policy p_insert on public.main_2_owner for insert to authenticated
  with check ((select has_perm('listings.create')) or (select has_perm('listings.edit')) or (select has_perm('roles.manage')));
create policy p_update on public.main_2_owner for update to authenticated
  using      ((select has_perm('listings.edit')) or (select has_perm('roles.manage')))
  with check ((select has_perm('listings.edit')) or (select has_perm('roles.manage')));
create policy p_delete on public.main_2_owner for delete to authenticated
  using ((select has_perm('roles.manage')));

-- รูปทรัพย์
create policy p_select on public.main_8_listing_photo for select to authenticated
  using ((select has_perm('listings.view')));
create policy p_insert on public.main_8_listing_photo for insert to authenticated
  with check ((select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('listings.create')) or (select has_perm('roles.manage')));
create policy p_update on public.main_8_listing_photo for update to authenticated
  using      ((select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')))
  with check ((select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));
create policy p_delete on public.main_8_listing_photo for delete to authenticated
  using ((select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));

-- ⚠️ main_9 / main_10 / main_11 ถูกเขียนโดย trigger (log_listing_status_change, sync_potential_listing)
--    trigger เหล่านี้ไม่ใช่ security definer → รันด้วยสิทธิ์ของ "คนที่แก้ทรัพย์"
--    ถ้า policy เขียนแคบกว่าสิทธิ์แก้ทรัพย์ การแก้ทรัพย์จะล้มทั้งรายการ จึงต้องกว้างเท่ากัน
create policy p_select on public.main_9_support_log for select to authenticated
  using ((select has_perm('listings.view')));
create policy p_insert on public.main_9_support_log for insert to authenticated
  with check ((select has_perm('listings.create')) or (select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));
create policy p_update on public.main_9_support_log for update to authenticated
  using ((select has_perm('roles.manage'))) with check ((select has_perm('roles.manage')));
create policy p_delete on public.main_9_support_log for delete to authenticated
  using ((select has_perm('roles.manage')));

create policy p_select on public.main_10_potential_listing for select to authenticated
  using ((select has_perm('listings.view')));
create policy p_insert on public.main_10_potential_listing for insert to authenticated
  with check ((select has_perm('listings.create')) or (select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));
create policy p_update on public.main_10_potential_listing for update to authenticated
  using      ((select has_perm('listings.create')) or (select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')))
  with check ((select has_perm('listings.create')) or (select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));
create policy p_delete on public.main_10_potential_listing for delete to authenticated
  using ((select has_perm('listings.create')) or (select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));

-- log ประวัติเข้า/ออกเกณฑ์ A List — เขียนอย่างเดียว ห้ามแก้ย้อนหลัง
create policy p_select on public.main_11_potential_listing_log for select to authenticated
  using ((select has_perm('listings.view')));
create policy p_insert on public.main_11_potential_listing_log for insert to authenticated
  with check ((select has_perm('listings.create')) or (select has_perm('listings.edit')) or (select has_perm('listings.marketing')) or (select has_perm('roles.manage')));
create policy p_update on public.main_11_potential_listing_log for update to authenticated
  using ((select has_perm('roles.manage'))) with check ((select has_perm('roles.manage')));
create policy p_delete on public.main_11_potential_listing_log for delete to authenticated
  using ((select has_perm('roles.manage')));


-- ============================================================
-- 5) Lead / ดีล — จุดที่ own vs all ต่างกันจริง
-- ============================================================

-- ลีดต้นทาง (รับจากฟอร์ม n8n)
create policy p_select on public.main_5_lead_database for select to authenticated
  using ((select has_perm('leads.view_all'))
         or ((select has_perm('leads.view_own')) and sales_id = (select current_employee_code())));
create policy p_insert on public.main_5_lead_database for insert to authenticated
  with check ((select has_perm('leads.create')) or (select has_perm('roles.manage')));
create policy p_update on public.main_5_lead_database for update to authenticated
  using      ((select has_perm('leads.edit')) or (select has_perm('leads.assign')) or (select has_perm('roles.manage')))
  with check ((select has_perm('leads.edit')) or (select has_perm('leads.assign')) or (select has_perm('roles.manage')));
create policy p_delete on public.main_5_lead_database for delete to authenticated
  using ((select has_perm('roles.manage')));

-- CRM ฝั่งผู้ซื้อ: เซลเห็นเฉพาะดีลที่ตัวเองถือ · หัวหน้า/แอดมิน/CEO เห็นหมด
-- ลีดที่ยังไม่มีคนถือ (sale_id is null) เห็นได้เฉพาะคนที่มี leads.view_all ซึ่งเป็นคนกลุ่มเดียวกับที่มี leads.assign
create policy p_select on public.main_6_buyer_crm for select to authenticated
  using ((select has_perm('leads.view_all'))
         or ((select has_perm('leads.view_own')) and sale_id = (select current_employee_code())));
create policy p_insert on public.main_6_buyer_crm for insert to authenticated
  with check (((select has_perm('leads.create')) or (select has_perm('roles.manage')))
              and (sale_id = (select current_employee_code())
                   or sale_id is null
                   or (select has_perm('leads.assign'))));
-- with check กันเซลโยนดีลออกจากมือตัวเอง: แก้แล้วแถวต้องยังอยู่ในขอบเขตที่ตัวเองเห็น
-- เว้นแต่มี leads.assign (แอดมิน/หัวหน้า) ซึ่งหน้าที่คือมอบหมายต่อ
create policy p_update on public.main_6_buyer_crm for update to authenticated
  using (((select has_perm('leads.edit')) or (select has_perm('leads.assign')) or (select has_perm('roles.manage')))
         and ((select has_perm('leads.view_all')) or sale_id = (select current_employee_code())))
  with check ((select has_perm('leads.assign')) or (select has_perm('leads.view_all'))
              or sale_id = (select current_employee_code()));
create policy p_delete on public.main_6_buyer_crm for delete to authenticated
  using ((select has_perm('roles.manage')));

-- ดีลที่ปิดได้: own / team / all ครบสามชั้น
create policy p_select on public.main_7_last_match for select to authenticated
  using ((select has_perm('lastmatch.view_all'))
         or ((select has_perm('lastmatch.view_team')) and sale_id in (select visible_employee_codes()))
         or ((select has_perm('lastmatch.view_own'))  and sale_id = (select current_employee_code())));
create policy p_insert on public.main_7_last_match for insert to authenticated
  with check ((select has_perm('lastmatch.add'))
              and (sale_id = (select current_employee_code())
                   or (select has_perm('lastmatch.view_all'))
                   or (select has_perm('lastmatch.view_team'))));
create policy p_update on public.main_7_last_match for update to authenticated
  using      ((select has_perm('roles.manage'))
              or ((select has_perm('lastmatch.add')) and sale_id = (select current_employee_code()))
              or ((select has_perm('lastmatch.view_all')) and (select has_perm('lastmatch.add'))))
  with check ((select has_perm('roles.manage'))
              or ((select has_perm('lastmatch.add')) and sale_id = (select current_employee_code()))
              or ((select has_perm('lastmatch.view_all')) and (select has_perm('lastmatch.add'))));
create policy p_delete on public.main_7_last_match for delete to authenticated
  using ((select has_perm('roles.manage')));


-- ============================================================
-- 6) ผู้ติดต่อ
-- ============================================================
create policy p_select on public.contacts for select to authenticated
  using ((select has_perm('contacts.view_all'))
         or ((select has_perm('contacts.view_own'))
             and (created_by = (select current_employee_code())
                  or assigned_to = (select current_employee_code()))));
create policy p_insert on public.contacts for insert to authenticated
  with check ((select has_perm('contacts.manage')) or (select has_perm('roles.manage')));
create policy p_update on public.contacts for update to authenticated
  using      (((select has_perm('contacts.manage')) or (select has_perm('roles.manage')))
              and ((select has_perm('contacts.view_all'))
                   or created_by = (select current_employee_code())
                   or assigned_to = (select current_employee_code())))
  with check ((select has_perm('contacts.manage')) or (select has_perm('roles.manage')));
create policy p_delete on public.contacts for delete to authenticated
  using ((select has_perm('roles.manage')));

-- contact_roles เกาะตาม contact แม่ — subquery ด้านล่างโดน RLS ของ contacts ทับอีกชั้นเอง
create policy p_select on public.contact_roles for select to authenticated
  using (exists (select 1 from public.contacts c where c.id = contact_id));
create policy p_insert on public.contact_roles for insert to authenticated
  with check (((select has_perm('contacts.manage')) or (select has_perm('roles.manage')))
              and exists (select 1 from public.contacts c where c.id = contact_id));
create policy p_update on public.contact_roles for update to authenticated
  using      (((select has_perm('contacts.manage')) or (select has_perm('roles.manage')))
              and exists (select 1 from public.contacts c where c.id = contact_id))
  with check ((select has_perm('contacts.manage')) or (select has_perm('roles.manage')));
create policy p_delete on public.contact_roles for delete to authenticated
  using (((select has_perm('contacts.manage')) or (select has_perm('roles.manage')))
         and exists (select 1 from public.contacts c where c.id = contact_id));


-- ============================================================
-- 7) งานประจำวัน / ผลงาน — ของใครของมัน หัวหน้าเห็นของลูกทีม
-- ============================================================

-- กิจกรรม (ฐานของแดชบอร์ดผลงาน)
create policy p_select on public.activities for select to authenticated
  using (employee_code = (select current_employee_code())
         or ((select has_perm('performance.view_team')) and employee_code in (select visible_employee_codes())));
create policy p_insert on public.activities for insert to authenticated
  with check ((select has_perm('roles.manage'))
              or ((select has_perm('activity.log')) and employee_code = (select current_employee_code())));
create policy p_update on public.activities for update to authenticated
  using      ((select has_perm('roles.manage')) or employee_code = (select current_employee_code()))
  with check ((select has_perm('roles.manage')) or employee_code = (select current_employee_code()));
create policy p_delete on public.activities for delete to authenticated
  using ((select has_perm('roles.manage')) or employee_code = (select current_employee_code()));

-- แผนงานวันนี้ / ปุ่มลัดส่วนตัว / แจ้งเตือน — ส่วนตัวล้วน
do $do$
declare t text;
begin
  foreach t in array array['tasks','user_quick_actions','notifications'] loop
    execute format($f$create policy p_select on public.%I for select to authenticated
        using (employee_code = (select current_employee_code()) or (select has_perm('roles.manage')))$f$, t);
    execute format($f$create policy p_insert on public.%I for insert to authenticated
        with check (employee_code = (select current_employee_code()) or (select has_perm('roles.manage')))$f$, t);
    execute format($f$create policy p_update on public.%I for update to authenticated
        using      (employee_code = (select current_employee_code()) or (select has_perm('roles.manage')))
        with check (employee_code = (select current_employee_code()) or (select has_perm('roles.manage')))$f$, t);
    execute format($f$create policy p_delete on public.%I for delete to authenticated
        using (employee_code = (select current_employee_code()) or (select has_perm('roles.manage')))$f$, t);
  end loop;
end
$do$;

-- เป้าหมาย/KPI: ตัวเองตั้งเป้าเสริมได้ (targets.stretch) · หัวหน้าตั้งให้ลูกทีม (targets.set)
create policy p_select on public.targets for select to authenticated
  using (employee_code = (select current_employee_code())
         or ((select has_perm('performance.view_team')) and employee_code in (select visible_employee_codes())));
create policy p_insert on public.targets for insert to authenticated
  with check ((select has_perm('roles.manage'))
              or ((select has_perm('targets.stretch')) and employee_code = (select current_employee_code()))
              or ((select has_perm('targets.set'))     and employee_code in (select visible_employee_codes())));
create policy p_update on public.targets for update to authenticated
  using      ((select has_perm('roles.manage'))
              or ((select has_perm('targets.stretch')) and employee_code = (select current_employee_code()))
              or ((select has_perm('targets.set'))     and employee_code in (select visible_employee_codes())))
  with check ((select has_perm('roles.manage'))
              or ((select has_perm('targets.stretch')) and employee_code = (select current_employee_code()))
              or ((select has_perm('targets.set'))     and employee_code in (select visible_employee_codes())));
create policy p_delete on public.targets for delete to authenticated
  using ((select has_perm('roles.manage'))
         or ((select has_perm('targets.stretch')) and employee_code = (select current_employee_code()))
         or ((select has_perm('targets.set'))     and employee_code in (select visible_employee_codes())));

-- ใบลา: เห็นของตัวเอง · HR/CEO เห็นหมดและอนุมัติได้
create policy p_select on public.leave_requests for select to authenticated
  using (employee_code = (select current_employee_code())
         or (select has_perm('leave.manage')) or (select has_perm('roles.manage')));
create policy p_insert on public.leave_requests for insert to authenticated
  with check ((select has_perm('leave.manage')) or (select has_perm('roles.manage'))
              or ((select has_perm('leave.request')) and employee_code = (select current_employee_code())));
create policy p_update on public.leave_requests for update to authenticated
  using      ((select has_perm('leave.manage')) or (select has_perm('roles.manage'))
              or employee_code = (select current_employee_code()))
  with check ((select has_perm('leave.manage')) or (select has_perm('roles.manage'))
              or employee_code = (select current_employee_code()));
create policy p_delete on public.leave_requests for delete to authenticated
  using ((select has_perm('leave.manage')) or (select has_perm('roles.manage'))
         or employee_code = (select current_employee_code()));


-- ============================================================
-- 8) audit_log — เขียนได้ในนามตัวเองเท่านั้น อ่านได้เฉพาะคนคุมระบบ ห้ามแก้/ลบ
-- ============================================================
create policy p_select on public.audit_log for select to authenticated
  using ((select has_perm('roles.manage')));
create policy p_insert on public.audit_log for insert to authenticated
  with check (changed_by = (select current_employee_code()) or (select has_perm('roles.manage')));
-- ไม่มี p_update / p_delete โดยตั้งใจ = ไม่มีใครลบร่องรอยตัวเองได้


-- ============================================================
-- 9) ปิด endpoint /rest/v1/rpc/* ของ helper + ตรึง search_path
--    helper อ่าน auth.uid() ซึ่ง anon ไม่มีอยู่แล้ว แต่ไม่มีเหตุผลให้เปิดทิ้งไว้ให้ยิงเล่น
-- ============================================================
revoke execute on function public.current_employee_code()  from anon;
revoke execute on function public.my_permissions()         from anon;
revoke execute on function public.has_perm(text)           from anon;
revoke execute on function public.visible_employee_codes() from anon;
revoke execute on function public.zone_primary_sale(text)  from anon;

-- ตรึง search_path ของ trigger function (advisor 0011) — พฤติกรรมไม่เปลี่ยน
-- แต่กันคนที่สร้าง schema ชื่อซ้ำมาแย่ง resolve ชื่อตาราง
alter function public.set_lead_database_id()      set search_path = public;
alter function public.set_hr_employee_code()      set search_path = public;
alter function public.set_listing_id()            set search_path = public;
alter function public.set_livinginsider_date()    set search_path = public;
alter function public.set_last_match_id()         set search_path = public;
alter function public.set_project_id()            set search_path = public;
alter function public.set_updated_at()            set search_path = public;
alter function public.sync_potential_listing()    set search_path = public;
alter function public.log_listing_status_change() set search_path = public;
alter function public.zone_primary_sale(text)     set search_path = public;
alter function public.fn_sale_status(date, date)  set search_path = public;

-- หมายเหตุ: `rls_auto_enable()` ที่ advisor เตือนว่า anon เรียกได้ — **ไม่ต้องแตะ**
-- เป็น event trigger ของ Supabase เอง (บังคับเปิด RLS ให้ตารางที่สร้างใหม่) `returns event_trigger`
-- จึงเรียกผ่าน REST ไม่ได้จริง

-- ============================================================
-- 10) ตรวจผลลัพธ์
-- ============================================================
-- ต้องได้ "0 แถว" ทั้งคู่ ถ้ามีแถวโผล่มาแปลว่ายังมีรูรั่ว
select 'ตารางที่ยังไม่มี policy' as ปัญหา, c.relname as ตาราง
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
  and not exists (select 1 from pg_policy p where p.polrelid = c.oid)
union all
select 'policy ที่ยังเปิดให้ anon', c.relname || ' / ' || p.polname
from pg_policy p join pg_class c on c.oid = p.polrelid
where 'anon' = any (select rolname from pg_roles where oid = any (p.polroles));

-- นับ policy ต่อตาราง (ดูภาพรวม — ปกติได้ 3-4 อันต่อตาราง)
-- select c.relname, count(*) from pg_policy p join pg_class c on c.oid=p.polrelid
-- join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' group by 1 order by 2, 1;

-- ============================================================
-- 11) เพิ่มเติม 2026-08-03 (หลัง Ben ทัก) — เบอร์เจ้าของต้องกันจริง ไม่ใช่แค่ไม่โชว์คอลัมน์
--     หน้า "ทรัพย์ทั้งบริษัท" เขียนไว้เองว่า "ไม่แสดงข้อมูลเจ้าของ" แต่ข้อมูลถูกส่งถึง
--     เบราว์เซอร์อยู่ดี + ยิง REST ตรงก็ได้ครบ 452 ราย → ย้ายมากันที่ RLS
--     v_main_listing ใช้ LEFT JOIN → คนไม่มีสิทธิ์ได้ owner_* เป็น null แต่แถวทรัพย์ยังครบ
-- ============================================================
drop policy if exists p_select on public.main_2_owner;
create policy p_select on public.main_2_owner for select to authenticated
  using (
    (select has_perm('contacts.view_all'))
    or (select has_perm('roles.manage'))
    or exists (
      select 1 from public.main_4_listing_database l
      where l.owner_id = main_2_owner.owner_id
        and coalesce(l.sale_id, zone_primary_sale(l.zone)) = (select current_employee_code())
    )
  );
create index if not exists idx_main_4_owner_id on public.main_4_listing_database (owner_id);
create index if not exists idx_main_4_sale_id  on public.main_4_listing_database (sale_id);
