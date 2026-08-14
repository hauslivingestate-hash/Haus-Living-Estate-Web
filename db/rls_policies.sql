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
-- own → all. A team tier was added and reverted on 2026-08-13: Ben's call is that a team
-- lead sees every owner, which leaves nobody in a middle tier.
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
-- ⚠️ ท่อนของตัวเองต้องมี status='pending' ด้วยเสมอ (แก้ 2026-08-14 ตอนต่อหน้า /leave)
-- ของเดิมเป็น "แถวของตัวเอง" ล้วน ๆ → เซลยิง REST อัปเดตใบลาตัวเองเป็น 'approved' ได้เอง
-- (พิสูจน์แล้วว่าทำได้จริงก่อนแก้) ตัวที่กันอยู่มีแค่ด่านในแอป ซึ่งไม่ใช่ด่านสุดท้าย
-- `with check` ก็ต้องมีเงื่อนไขเดียวกัน ไม่งั้นแก้จาก pending → approved ยังผ่าน
create policy p_update on public.leave_requests for update to authenticated
  using      ((select has_perm('leave.manage')) or (select has_perm('roles.manage'))
              or (employee_code = (select current_employee_code()) and status = 'pending'))
  with check ((select has_perm('leave.manage')) or (select has_perm('roles.manage'))
              or (employee_code = (select current_employee_code()) and status = 'pending'));
-- ลบใบลาที่ตัดสินไปแล้ว = ลบหลักฐานการตัดสิน จึงเหลือเฉพาะ pending เหมือนกัน
create policy p_delete on public.leave_requests for delete to authenticated
  using ((select has_perm('leave.manage')) or (select has_perm('roles.manage'))
         or (employee_code = (select current_employee_code()) and status = 'pending'));


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

-- ============================================================
-- 12) เพิ่มเติม 2026-08-07 (Phase 5 ข้อ 1 — เขียนจริงหน้าแก้ไขทรัพย์) — สร้างเจ้าของใหม่ไม่ได้
--     ผลข้างเคียงของแก้ #11 ข้างบน: p_select ของ main_2_owner ให้เห็นเฉพาะเจ้าของที่ "มี
--     listing ผูกอยู่แล้ว" — เจ้าของที่เพิ่งสร้าง (ยังไม่ผูกกับใคร) เลยมองไม่เห็นตัวเอง
--     `insert ... returning owner_id` (สิ่งที่ supabase-js ทำเวลาเรียก .insert().select())
--     โดน p_select เช็คด้วย เลยชน 42501 ทุกครั้งที่จะสร้างเจ้าของใหม่ (เจอจริงตอนทดสอบ
--     ListingEditSheet ผ่าน browser-automation กับบัญชี Mhow/S-004)
--     ทางแก้: RPC security definer ที่เช็คสิทธิ์เอง (เหมือน p_insert เดิมทุกประการ) แล้ว
--     insert ตรงๆ โดยไม่ใช้ returning ผ่าน RLS — ฟังก์ชันรันด้วยสิทธิ์เจ้าของ (ไม่ force
--     row security) เลยไม่ชน p_select ระหว่างสร้าง
-- ============================================================
create or replace function public.create_owner(p_name text, p_phone text, p_line text)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare v_id bigint;
begin
  if not (has_perm('listings.create') or has_perm('listings.edit') or has_perm('roles.manage')) then
    raise exception 'insufficient permission' using errcode = '42501';
  end if;
  insert into main_2_owner (owner_name, owner_phone, owner_line)
    values (p_name, p_phone, p_line)
    returning owner_id into v_id;
  return v_id;
end;
$$;

revoke execute on function public.create_owner(text, text, text) from anon;


-- ============================================================
-- 13) เพิ่มเติม 2026-08-08 (Phase 5 ข้อ 3 — ฟอร์มเพิ่มลีด) — สร้างลีดใหม่
--     รับลีด 1 ครั้ง = เขียน 2 แถว: main_5_lead_database (บันทึกตอนรับ, trigger สร้าง
--     lead_id ให้) + main_6_buyer_crm (แถวที่เซลทำงานด้วย) ผูกกันด้วย lead_ref
--     ทำจาก client ไม่ได้เพราะต้อง `insert ... returning lead_id` เพื่อรู้ id ที่ trigger
--     สร้าง แต่ RETURNING โดน SELECT policy เช็คด้วย ซึ่งเป็น
--       leads.view_all OR (leads.view_own AND sales_id = ตัวเอง)
--     → admin ที่มอบลีดให้คนอื่น และ listing_support (ไม่มีทั้งคู่) จะมองไม่เห็นแถวที่
--     ตัวเองเพิ่งเขียน ชน 42501 — กับดักเดียวกับ main_2_owner ทางแก้เดียวกัน
--     insert ทั้ง 2 แถวอยู่ในฟังก์ชันเดียว = ทรานแซกชันเดียว ลีดครึ่งๆ กลางๆ เกิดไม่ได้
--     รับ jsonb ไม่ใช่ param แยก ~18 ตัว เพราะฟิลด์ฟอร์มยังเพิ่มอีก + type boundary จริง
--     อยู่ที่ TypeScript ฝั่ง server action
-- ============================================================
create or replace function public.create_lead(p jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lead_id text;
  v_sale_id text;
begin
  if not (has_perm('leads.create') or has_perm('roles.manage')) then
    raise exception 'insufficient permission' using errcode = '42501';
  end if;

  if coalesce(btrim(p->>'lead_name'), '') = '' then
    raise exception 'lead_name is required' using errcode = '23514';
  end if;

  -- รหัสที่ส่งมาตรงๆ ชนะเสมอ ไม่งั้นแปลจากชื่อ (ฟอร์ม/n8n ส่ง "Sales Assigned" มาเป็นชื่อ)
  -- ชื่อที่แมปไม่ได้ "ไม่" ทำให้ insert ล้ม — ลีดยังถูกสร้างแต่ sale_id เป็น null แล้วไปโผล่
  -- ในตัวกรอง "ยังไม่มอบหมาย" ให้คนมาแก้ ดีกว่าทำลีดลูกค้าหายเพราะพิมพ์ชื่อผิด
  v_sale_id := nullif(p->>'sale_id', '');
  if v_sale_id is null then
    v_sale_id := resolve_employee_code(p->>'sale_name');
  end if;

  insert into main_5_lead_database (
    date_received, lead_type, listing_code, lead_name, phone, line_id,
    gender, nationality, remark, sales_id,
    contact_date, contact_time, marketing_channel, contact_by
  ) values (
    coalesce((p->>'date_received')::date, current_date),
    nullif(p->>'lead_type', ''),
    nullif(p->>'listing_code', ''),
    btrim(p->>'lead_name'),
    nullif(btrim(coalesce(p->>'phone', '')), ''),
    nullif(p->>'line_id', ''),
    nullif(p->>'gender', ''),
    nullif(p->>'nationality', ''),
    nullif(p->>'remark', ''),
    v_sale_id,
    nullif(p->>'contact_date', '')::date,
    nullif(p->>'contact_time', '')::time,
    nullif(p->>'marketing_channel', ''),
    nullif(p->>'contact_by', '')
  )
  returning lead_id into v_lead_id;

  -- ลีดใหม่เริ่มที่สเตจ 'Lead' / สถานะ 'Active' เสมอ — นี่คือสิ่งที่ทำให้ "เซลติดต่อลูกค้า
  -- แล้วยัง" (derive จาก pipeline_stage) อ่านว่ายังไม่ติดต่อ จนกว่าจะมีคนขยับสเตจจริง
  insert into main_6_buyer_crm (
    lead_id, lead_ref, date_received, listing_code, lead_type, sale_id,
    lead_name, phone, line_id, admin_remark, budget,
    potential, lead_status, pipeline_stage,
    marketing_channel, contact_by, gender, nationality, contact_date, contact_time,
    interest_zone, interest_property_type, purpose, sell_reason
  ) values (
    v_lead_id, v_lead_id,
    coalesce((p->>'date_received')::date, current_date),
    nullif(p->>'listing_code', ''),
    nullif(p->>'lead_type', ''),
    v_sale_id,
    btrim(p->>'lead_name'),
    nullif(btrim(coalesce(p->>'phone', '')), ''),
    nullif(p->>'line_id', ''),
    nullif(p->>'remark', ''),
    nullif(p->>'budget', '')::numeric,
    coalesce(nullif(p->>'potential', ''), 'New Lead'),
    'Active',
    'Lead',
    nullif(p->>'marketing_channel', ''),
    nullif(p->>'contact_by', ''),
    nullif(p->>'gender', ''),
    nullif(p->>'nationality', ''),
    nullif(p->>'contact_date', '')::date,
    nullif(p->>'contact_time', '')::time,
    nullif(p->>'interest_zone', ''),
    nullif(p->>'interest_property_type', ''),
    nullif(p->>'purpose', ''),
    nullif(p->>'sell_reason', '')
  );

  return v_lead_id;
end;
$$;

revoke execute on function public.create_lead(jsonb) from anon;

-- lookup ใหม่ 2 ตัวของฟอร์มลีด — ต้องมี policy ไม่งั้น rls_auto_enable() ของ Supabase
-- บังคับเปิด RLS แล้วไม่มีใครอ่าน dropdown ได้เลย (กลุ่มเดียวกับ §2 "รายการอ้างอิง")
do $do$
declare t text;
begin
  foreach t in array array['lead_purpose','sell_reason'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists p_select on public.%I', t);
    execute format('drop policy if exists p_insert on public.%I', t);
    execute format('drop policy if exists p_update on public.%I', t);
    execute format('drop policy if exists p_delete on public.%I', t);
    execute format('create policy p_select on public.%I for select to authenticated using (true)', t);
    execute format($f$create policy p_insert on public.%I for insert to authenticated
      with check ((select has_perm('reference.manage')) or (select has_perm('masterdata.govern')) or (select has_perm('roles.manage')))$f$, t);
    execute format($f$create policy p_update on public.%I for update to authenticated
      using      ((select has_perm('reference.manage')) or (select has_perm('masterdata.govern')) or (select has_perm('roles.manage')))
      with check ((select has_perm('reference.manage')) or (select has_perm('masterdata.govern')) or (select has_perm('roles.manage')))$f$, t);
    execute format($f$create policy p_delete on public.%I for delete to authenticated
      using ((select has_perm('reference.manage')) or (select has_perm('masterdata.govern')) or (select has_perm('roles.manage')))$f$, t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end
$do$;

-- ============================================================
-- 13) 2026-08-13 — ขอบเขตการเห็นเจ้าของทรัพย์: ยืนยันว่าเป็น own → all (ไม่มีชั้นทีม)
--     วันนั้นเคยเพิ่ม permission `contacts.view_team` + ชั้นกลางใน policy ของ contacts และ
--     main_2_owner แล้ว **ถอนกลับทั้งหมดในวันเดียวกัน** เพราะ Ben สรุปว่า "หัวหน้าทีมให้เห็น
--     ทั้งหมด" → ไม่มีใครเหลืออยู่ในชั้นกลาง เก็บ key ที่ไม่มีคนถือไว้ก็รกเปล่า ๆ
--     สรุปกติกาที่ใช้จริง: เซล = เฉพาะเจ้าของทรัพย์ที่ตัวเองดูแล ·
--     Admin / CEO / หัวหน้าทีม / Listing Support = เห็นทั้งหมด · Marketing = ไม่เห็นเลย
--     (ทั้งหมดนี้คือสิ่งที่ §6 กับ §11 ด้านบนเขียนไว้อยู่แล้ว — ไม่ต้องรันอะไรเพิ่ม)
-- ============================================================

-- ============================================================
-- 14) 2026-08-14 — เซลล์ใหม่ (โปรเบชั่น) + กติกาใบลาที่แคบลง
-- ============================================================

-- 14.1 บันไดขั้นเซลล์ใหม่ — อ่านได้ทุกคนที่ login (เซลบนกระดานต้องเห็นเกณฑ์ของตัวเอง)
--      แก้ได้เฉพาะคนคุมข้อมูลกลาง เหมือน zone / action_type
-- ⚠️ ตารางใหม่ทุกตารางต้องเขียน policy เอง — rls_auto_enable() ของ Supabase เปิด RLS ให้
--    อัตโนมัติ ถ้าไม่มี policy จะอ่านไม่ได้เลย (เจอมาแล้วตอนทำ lead_purpose/sell_reason)
alter table public.probation_rank enable row level security;
alter table public.rank_criterion enable row level security;
revoke all on public.probation_rank, public.rank_criterion from anon;
grant select, insert, update, delete on public.probation_rank, public.rank_criterion to authenticated;

drop policy if exists p_select on public.probation_rank;
create policy p_select on public.probation_rank for select to authenticated using (true);
drop policy if exists p_insert on public.probation_rank;
create policy p_insert on public.probation_rank for insert to authenticated
  with check ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')));
drop policy if exists p_update on public.probation_rank;
create policy p_update on public.probation_rank for update to authenticated
  using      ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')))
  with check ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')));
drop policy if exists p_delete on public.probation_rank;
create policy p_delete on public.probation_rank for delete to authenticated
  using ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')));

drop policy if exists p_select on public.rank_criterion;
create policy p_select on public.rank_criterion for select to authenticated using (true);
drop policy if exists p_insert on public.rank_criterion;
create policy p_insert on public.rank_criterion for insert to authenticated
  with check ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')));
drop policy if exists p_update on public.rank_criterion;
create policy p_update on public.rank_criterion for update to authenticated
  using      ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')))
  with check ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')));
drop policy if exists p_delete on public.rank_criterion;
create policy p_delete on public.rank_criterion for delete to authenticated
  using ((select has_perm('masterdata.govern')) or (select has_perm('roles.manage')));

-- 14.2 🔴 GRANT ระดับคอลัมน์ของ main_1_hr — ส่วนนี้เคยรันสดตอน 2026-08-03 แต่ไม่เคยถูก
--      บันทึกลงไฟล์ ทำให้ setup ใหม่จะได้ฐานที่ "เงินเดือน/PII อ่านได้หมด" เงียบ ๆ
--      ⚠️⚠️ เพิ่มคอลัมน์ใหม่ใน main_1_hr เมื่อไหร่ ต้อง grant คอลัมน์นั้นด้วยเสมอ
--      เพราะตารางนี้ไม่มี grant ระดับตารางให้สืบทอด — 2026-08-14 เพิ่ม probation_start/
--      probation_passed_at แล้วลืม grant ทำให้ทุกหน้าที่แตะ main_1_hr พังหมด
--      (PostgREST ล้มทั้ง query → "permission denied for table main_1_hr")
revoke select on public.main_1_hr from anon, authenticated;
grant select (
  employee_code, status, division, position, second_position,
  first_name_en, last_name_en, first_name_th, last_name_th, nickname,
  gender, nationality, phone, additional_phone, email, work_email,
  birthday, date_started, probation_start, probation_passed_at,
  emergency_contact, emergency_contact_phone, emergency_contact_relationship,
  remark, line_userid, sales_sheet_url, team_id, auth_user_id, created_at
) on public.main_1_hr to authenticated;
-- ไม่มีในลิสต์โดยตั้งใจ (อ่านได้ทางเดียวคือ v_employee_private ซึ่งเช็คสิทธิ์ทีละคอลัมน์):
--   salary · commission · id_card_no · kbank_account · payslip_drive · agreement_files
-- ⚠️ UPDATE ไม่ได้ถูกถอน — คนที่ผ่าน policy `people.manage` เขียนทับคอลัมน์เหล่านี้ได้
--    ทั้งที่อ่านไม่ได้ ด่านที่กันจริงอยู่ที่ชั้นแอป (lib/mutations/employees.ts FIELDS[].group)

-- 14.3 ใบลา — ท่อน "แถวของตัวเอง" ต้องมี status='pending' ด้วย
--      ของเดิมไม่มี → เซลยิง REST อัปเดตใบลาตัวเองเป็น 'approved' ได้ (ดูหัวข้อใบลาด้านบน
--      ซึ่งแก้ไว้แล้ว — ย้ำไว้ตรงนี้เพราะเป็นบทเรียนเดียวกัน: `with check` ต้องมีเงื่อนไขด้วย
--      ไม่ใช่แค่ `using` ไม่งั้นการแก้ pending → approved ยังผ่าน)
