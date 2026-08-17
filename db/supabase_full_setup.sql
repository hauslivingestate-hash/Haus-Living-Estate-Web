-- ============================================================
-- HAUS LIVING ESTATE — FULL DATABASE SETUP (รันทีเดียวจบทั้งระบบ)
-- วางทั้งไฟล์นี้ใน Supabase > SQL Editor แล้วกด Run
-- โมดูล: main_1_hr | main_5_lead_database | main_6_buyer_crm |
--        main_4_listing_database (+ owner/main_3_property_detail/last_match/photo)
-- FK เชื่อมครบในไฟล์เดียว
-- ============================================================


-- ============================================================
-- 0) ล้างของเก่าทั้งหมด (setup ครั้งแรกเท่านั้น) ⚠️ ถ้ามีข้อมูลจริงแล้วอย่ารัน
-- ============================================================
drop view  if exists v_support_listing     cascade;
drop view  if exists v_main_listing        cascade;
drop table if exists main_11_potential_listing_log cascade;
drop table if exists main_10_potential_listing cascade;
drop table if exists main_9_support_log     cascade;
drop table if exists main_8_listing_photo     cascade;
drop table if exists main_7_last_match        cascade;
drop table if exists main_6_buyer_crm         cascade;
drop table if exists main_5_lead_database     cascade;
drop table if exists main_4_listing_database  cascade;
drop table if exists main_3_property_detail        cascade;
drop table if exists main_2_owner             cascade;
drop table if exists rank_criterion            cascade;
drop table if exists probation_rank            cascade;
drop table if exists main_1_hr                cascade;
-- ชื่อเก่า เผื่อเคยรันไว้ (ก่อนใส่เลขนำหน้า main_1_..main_10_)
drop table if exists main_listing_photo    cascade;
drop table if exists main_last_match       cascade;
drop table if exists main_buyer_crm        cascade;
drop table if exists main_lead_database    cascade;
drop table if exists main_listing_database cascade;
drop table if exists property_detail       cascade;
drop table if exists main_owner            cascade;
drop table if exists main_hr               cascade;
drop table if exists buyer_crm cascade;
drop table if exists leads cascade;
drop table if exists lead_database cascade;
drop table if exists hr cascade;
-- lookups
drop table if exists potential cascade;
drop table if exists lead_status cascade;
drop table if exists pipeline_stage cascade;
drop table if exists bank_loan cascade;
drop table if exists lead_type cascade;
drop table if exists complain_status cascade;
drop table if exists marketing_channel cascade;
drop table if exists contact_by cascade;
drop table if exists lead_purpose cascade;
drop table if exists sell_reason cascade;
drop table if exists employee_status cascade;
drop table if exists job_position cascade;
drop table if exists second_position cascade;
drop table if exists gender cascade;
drop table if exists nationality cascade;
drop table if exists listing_status cascade;
drop table if exists listing_type cascade;
drop table if exists property_type cascade;
drop table if exists in_out_project cascade;
drop table if exists zone cascade;
drop table if exists direction cascade;
drop table if exists view_type cascade;
drop table if exists unit_position cascade;
drop table if exists price_remark cascade;
drop table if exists unit_condition cascade;
drop table if exists close_type cascade;
drop table if exists listing_potential cascade;
drop table if exists lead_tags_ref cascade;
-- RBAC
drop table if exists user_roles       cascade;
drop table if exists role_permissions cascade;
drop table if exists roles            cascade;
drop table if exists permissions      cascade;
drop table if exists teams            cascade;
drop table if exists zone_sales       cascade;
-- ตารางที่เว็บแอปใช้
drop table if exists audit_log          cascade;
drop table if exists notifications      cascade;
drop table if exists leave_requests     cascade;
drop table if exists leave_allowances   cascade;
drop table if exists leave_type         cascade;
drop table if exists contact_roles      cascade;
drop table if exists contacts           cascade;
drop table if exists user_quick_actions cascade;
drop table if exists activities         cascade;
drop table if exists tasks              cascade;
drop table if exists targets            cascade;
drop table if exists action_type        cascade;


-- ============================================================
-- 1) LOOKUPS ทั้งหมด
-- ============================================================

-- ---- ใช้ร่วมหลายตาราง ----
create table gender (name text primary key);
insert into gender (name) values ('Male'), ('Female'), ('Other'), ('N/A');

create table nationality (name text primary key);
insert into nationality (name) values ('Thai'), ('Foreigner');

-- ---- main_6_buyer_crm ----
create table potential (name text primary key);
insert into potential (name) values ('A'), ('B'), ('C'), ('New Lead'), ('Agent');

create table lead_status (name text primary key);
insert into lead_status (name) values ('Active'), ('Lose'), ('Reject'), ('Win');

create table pipeline_stage (name text primary key);
insert into pipeline_stage (name) values
  ('Lead'), ('Call'), ('Follow'), ('Appoint'), ('Show'), ('Nego'), ('Close'), ('Win');

create table bank_loan (name text primary key);
insert into bank_loan (name) values
  ('Process'), ('Approved'), ('Rejected'), ('Blacklist (Credit Bureau)');

-- ---- main_5_lead_database ----
create table lead_type (name text primary key);
insert into lead_type (name) values
  ('Owner - Sale'), ('Owner - Rent'), ('Owner - Others'),
  ('Buyer - Buy'), ('Buyer - Rent'), ('Co-Agent');

create table complain_status (name text primary key);
insert into complain_status (name) values ('Open'), ('In Progress'), ('Resolved'), ('Closed');

create table marketing_channel (name text primary key);
insert into marketing_channel (name) values
  ('Ddproperty'), ('Livinginsider'), ('Facebook Organic'), ('Tiktok'),
  ('Facebook Ad'), ('ป้าย Offline'), ('Referral'), ('อื่นๆ');

create table contact_by (name text primary key);
insert into contact_by (name) values
  ('Call'), ('LINE OA'), ('Facebook Inbox'), ('Tiktok Inbox'),
  ('Ddproperty Inbox'), ('Livinginsider Inbox'), ('Email'), ('Personal');

-- ความต้องการของลีด (เพิ่ม 2026-08-08 ตอนต่อฟอร์มเพิ่มลีด — ฟอร์มถามมาตั้งแต่แรกแต่ไม่มีที่เก็บ)
create table lead_purpose (name text primary key);
insert into lead_purpose (name) values ('ซื้ออยู่เอง'), ('ลงทุน / ปล่อยเช่า'), ('เช่า');

create table sell_reason (name text primary key);
insert into sell_reason (name) values
  ('ขยับขยาย'), ('ย้ายที่อยู่'), ('ต้องการเงินสด'), ('ขายทำกำไร'), ('อื่นๆ');

-- ---- main_1_hr ----
create table employee_status (name text primary key);
insert into employee_status (name) values ('Active'), ('Probation'), ('Warning'), ('Terminate');

create table job_position (name text primary key);
insert into job_position (name) values ('CEO'), ('CTO'), ('CFO'), ('Listing Support'), ('Marketing');

create table second_position (name text primary key);
insert into second_position (name) values ('Sales'), ('Support');

-- ---- main_4_listing_database / main_3_property_detail / last_match ----
create table listing_status (name text primary key);
insert into listing_status (name) values
  ('Posted'), ('Ready to Post'), ('Update'), ('Need Info'),
  ('Cancel'), ('Cancel Completed'), ('Sold'), ('Sold Completed');

create table listing_type (name text primary key);
insert into listing_type (name) values
  ('Sale'), ('Rent'), ('Sale & Rent'), ('Sale with Tenant'), ('Co - Agent');

create table property_type (name text primary key, code text not null);
insert into property_type (name, code) values
  ('บ้านเดี่ยว','H'), ('บ้านแฝด','H'), ('คอนโด','C'), ('ทาวน์เฮ้าส์','T'), ('ทาวน์โฮม','T'),
  ('ที่ดิน','L'), ('อพาร์ทเม้นท์','A'), ('โรงแรม','E'), ('ออฟฟิศ','O'), ('โกดัง','G'), ('โรงงาน','G');

create table in_out_project (name text primary key);
insert into in_out_project (name) values ('ในโครงการ'), ('นอกโครงการ');

-- เซลที่ดูแลโซนไม่ได้อยู่ที่นี่ — อยู่ในตาราง zone_sales (1 โซนมีได้หลายเซล)
-- ดูหัวข้อ 2.2 ท้าย main_1_hr
create table zone (
  seq              bigint generated always as identity,   -- เลขรันข้างหน้า
  zone_id          text primary key,                      -- Zone ID (ตัวย่อ) ใช้ประกอบ Listing ID
  name_eng         text,
  name_thai        text,
  created_at       timestamptz default now()
);
insert into zone (zone_id, name_eng, name_thai) values
  ('BGY','Bangyai','บางใหญ่'), ('RP1','Ratchaphruek (ต้น)','ราชพฤกษ์ต้น'),
  ('PHU','Phuttamonthon','พุทธมณฑล'), ('KAL','Kallapapruek','กัลปพฤกษ์'),
  ('SSW','Suksawat','สุขสวัสดิ์'), ('RM2','Rama 2','พระราม 2'), ('RM5','Rama 5','พระราม 5'),
  ('RP2','Ratchaphruek (กลาง)','ราชพฤกษ์กลาง'), ('BGK','Bang - Kluay','บางกรวย'),
  ('PDP','Pradipat','ประดิพัทธ์'), ('RP3','Ratchaphruek (ปลาย)','ราชพฤกษ์ปลาย'),
  ('CYP','Chaiyaphruek','ชัยพฤกษ์'), ('CWT','Chaengwattana','แจ้งวัฒนะ'),
  ('DMK','Don mueang','ดอนเมือง'), ('NGM','Ngam Wong Wan','งามวงศ์วาน'),
  ('SLY','Salaya','ศาลายา'), ('ASK','Asoke','อโศก'), ('RM3','Rama 3','พระราม 3'),
  ('PKS','Phetkasem','เพชรเกษม'), ('CRK','Charoennakhorn','เจริญนคร'),
  ('KCP','Kanchanaphisek','กาญจนาภิเษก'), ('PCC','Prachachuen','ประชาชื่น'),
  ('WWY','Wongwianyai','วงเวียนใหญ่');

create table direction (name text primary key);
insert into direction (name) values
  ('North'), ('South'), ('East'), ('West'),
  ('Northeast'), ('Northwest'), ('Southeast'), ('Southwest');

create table view_type (name text primary key);
insert into view_type (name) values ('โล่ง'), ('Block');

create table unit_position (name text primary key);
insert into unit_position (name) values
  ('มุม'), ('ริม'), ('หน้าบ้าน/หน้าสวน'), ('หน้าบ้านไม่ชนใคร'), ('ปกติ'),
  ('ไม่ใกล้ลิฟต์'), ('ไม่ใกล้ห้องขยะ'), ('วิวโล่ง/วิวสวน'), ('หน้าห้องไม่ชนใคร'), ('สระว่ายน้ำ');

create table price_remark (name text primary key);
insert into price_remark (name) values
  ('50/50 Transfer Fee'), ('All Included'), ('All Tax Not Included'), ('All 50/50');

create table unit_condition (name text primary key);
insert into unit_condition (name) values ('Great'), ('Good'), ('Bad'), ('Broken');

create table close_type (name text primary key);
insert into close_type (name) values
  ('ปิดเอง'), ('เจ้าของขายเอง'), ('เอเจ้นอื่นสอยไป'), ('ไม่รู้'), ('มือ 1');

create table listing_potential (name text primary key);
insert into listing_potential (name) values
  ('Normal'), ('A List'), ('A List + Fb add'), ('Exclusive'), ('Exclusive A');

-- แท็กกลุ่มลูกค้า (main_6_buyer_crm.tag_id) — CEO กำหนดรายการ, 1 ลีดติดได้ 1 แท็ก
-- ⚠️ ข้อยกเว้นเดียวจาก convention "lookup ใช้ name เป็น PK": ตารางนี้ใช้ id
--    เหตุผล: แอปเขียนรอไว้แล้วด้วย id (lib/tags.ts -> LeadTag {id,label,tone}, ค่า
--    investor/own_stay/rent_out/foreigner) + ตารางนี้ไม่ใช่ lookup แท้ (มี tone/sort_order/is_active)
--    หมายเหตุ: ที่ใช้ชื่อเป็น PK ไม่ได้พังตอนเปลี่ยนชื่อ เพราะ FK ทุกตัวใช้ on update cascade อยู่แล้ว
-- ลบแท็ก: ใช้ is_active = false แทน delete (ลีดเก่าจะได้ไม่กลายเป็นแท็กผี)
create table lead_tags_ref (
  id         text primary key,
  label      text not null,
  tone       text not null default 'neutral'
             check (tone in ('accent','blue','violet','amber','green','neutral')),
  sort_order integer default 0,
  is_active  boolean default true,
  created_at timestamptz default now()
);
-- seed ชั่วคราว รอ CEO ตั้งจริงที่ ตั้งค่า > แท็ก Lead
-- เป็นแกน "ลูกค้าประเภทไหน" ไม่ใช่ร้อน/อุ่น/เย็น (ความร้อนใช้ potential A/B/C อยู่แล้ว)
insert into lead_tags_ref (id, label, tone, sort_order) values
  ('investor',  'นักลงทุน',   'violet', 1),
  ('own_stay',  'ซื้ออยู่เอง', 'green',  2),
  ('rent_out',  'ปล่อยเช่า',   'blue',   3),
  ('foreigner', 'ต่างชาติ',    'amber',  4);


-- ============================================================
-- 2) TABLE: main_1_hr  (+ auto Employee Code)
-- ============================================================
create table main_1_hr (
  employee_code   text primary key,        -- auto-run
  status          text references employee_status (name) on update cascade,
  division        text,
  position        text references job_position (name)    on update cascade,
  second_position text references second_position (name) on update cascade,
  first_name_en   text,  last_name_en  text,
  first_name_th   text,  last_name_th  text,
  nickname        text,
  gender          text references gender (name)      on update cascade,
  nationality     text references nationality (name) on update cascade default 'Thai',
  phone           text,  additional_phone text,
  salary          numeric,  commission   numeric,
  id_card_no      text,  email text,  work_email text,
  birthday        date,  date_started date,
  agreement_files text,
  emergency_contact text, emergency_contact_phone text, emergency_contact_relationship text,
  remark          text,  kbank_account text,
  line_userid     text,                    -- << main_5_lead_database ดึงไปใช้
  payslip_drive   text,
  -- ลิงก์ชีทรายคน (HR Sheet คอลัมน์ U) — บางคนมีหลายลิงก์คั่น comma
  -- ใช้ตอน backfill ว่า listing ไหนเป็นของเซลคนไหน (created_by ในชีททรัพย์เป็น Stone ทั้งหมด)
  sales_sheet_url text,
  -- โปรแกรมเซลล์ใหม่ (โปรเบชั่น) — เป็น "ข้อเท็จจริง" ไม่ derive จาก date_started
  -- (ทุกคนเริ่มงานวันเดียวกัน 2025-11-01 จะ derive ยังไงก็ได้ทั้งทีมหรือไม่ได้เลย)
  -- probation_start   null = ไม่เคยเข้าโปรแกรม · เกณฑ์แบบ total นับกิจกรรมตั้งแต่วันนี้
  -- probation_passed_at  ตั้งแล้ว = ออกจากโปรแกรมถาวร (เก็บไว้ไม่ derive เพราะเกณฑ์แบบ
  --                      monthly ที่เดือนนี้ทำไม่ถึงจะทำให้ "ไม่ผ่าน" ย้อนหลังได้)
  probation_start     date,
  probation_passed_at date,
  -- สะพาน Auth <-> พนักงาน: ทุก RLS policy วิ่งผ่านตรงนี้ (auth.uid() -> employee_code)
  -- null = ยังไม่มีบัญชี login (เช่น พนักงานที่ลาออกแล้ว)
  auth_user_id    uuid unique references auth.users (id) on delete set null,
  created_at      timestamptz default now()
);

-- helper: session ปัจจุบัน -> employee_code
-- security definer เพราะตอนเปิด RLS จริง policy ต้องอ่าน main_1_hr ได้ก่อน policy จะทำงาน
create or replace function current_employee_code()
returns text language sql stable security definer set search_path = public as $$
  select employee_code from main_1_hr where auth_user_id = auth.uid()
$$;
revoke execute on function current_employee_code() from public;
grant  execute on function current_employee_code() to authenticated;

create or replace function set_hr_employee_code()
returns trigger language plpgsql as $$
declare prefix text; next_num int;
begin
  if new.employee_code is null or new.employee_code = '' then
    if new.second_position = 'Sales' then prefix := 'S';
    elsif new.second_position = 'Support' then prefix := 'SP';
    else prefix := case new.position
                     when 'CEO' then 'C' when 'CTO' then 'CT' when 'CFO' then 'CF'
                     when 'Listing Support' then 'LS' when 'Marketing' then 'MK' else 'E' end;
    end if;
    select coalesce(max(substring(employee_code from '[0-9]+$')::int),0)+1 into next_num
      from main_1_hr where split_part(employee_code,'-',1) = prefix;
    new.employee_code := prefix || '-' || lpad(next_num::text,3,'0');
  end if;
  return new;
end; $$;
drop trigger if exists trg_set_hr_employee_code on main_1_hr;
create trigger trg_set_hr_employee_code before insert on main_1_hr
  for each row execute function set_hr_employee_code();

-- ============================================================
-- 2.2) zone_sales — เซลคนไหนดูแลโซนไหนบ้าง  (ต้องรอ main_1_hr ก่อน)
--
-- หลักคิดการมอบหมาย (Ben, 2026-08-03):
--   "ทรัพย์" เป็นตัวตัดสินว่าใครดูแล (main_4_listing_database.sale_id)
--   ลีดวิ่งตามรหัสทรัพย์ที่ลูกค้าสนใจ ไม่ใช่ตามโซน
--   โซนจึงมีหลายเซลได้โดยไม่กำกวม (ของจริง: พระราม 3 = Pup + Mhow)
--
-- โซนยังจำเป็นเป็น "ตัวสำรอง" 2 กรณี: ลีดที่ไม่ระบุทรัพย์ · ทรัพย์ใหม่ที่ยังไม่ระบุเซล
-- -> ธง is_primary ตอบว่าใครเป็นเจ้าภาพโซนนั้น (โซนละไม่เกิน 1 คน)
-- ============================================================
create table zone_sales (
  zone_id       text not null references zone (zone_id)            on update cascade on delete cascade,
  employee_code text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  is_primary    boolean not null default false,
  created_at    timestamptz default now(),
  primary key (zone_id, employee_code)
);
create unique index uq_zone_primary  on zone_sales (zone_id) where is_primary;
create index        idx_zone_sales_emp on zone_sales (employee_code);

-- เจ้าภาพโซน — ใช้เฉพาะตอนทรัพย์ยังไม่ระบุ sale_id
create or replace function zone_primary_sale(p_zone text)
returns text language sql stable as $$
  select employee_code from zone_sales where zone_id = p_zone and is_primary limit 1
$$;


-- ============================================================
-- 2.1) RBAC — บทบาท & สิทธิ์  (เพิ่ม 2026-08-03)
-- ต้องอยู่ใน DB ไม่ใช่แค่ในโค้ดแอป เพราะ RLS policy ต้องอ่านได้
-- ตรงกับ PERMISSION_GROUPS / SEED_ROLES ใน haus-crm/lib/rbac.ts
-- ============================================================
create table permissions (
  key         text primary key,
  group_key   text not null,
  group_label text not null,
  label       text not null,
  hint        text,
  sort_order  integer default 0
);

create table roles (
  id          text primary key,
  name        text not null,
  description text,
  is_system   boolean default false,   -- ลบไม่ได้ (CEO)
  sort_order  integer default 0,
  created_at  timestamptz default now()
);

create table role_permissions (
  role_id        text not null references roles (id)        on update cascade on delete cascade,
  permission_key text not null references permissions (key) on update cascade on delete cascade,
  primary key (role_id, permission_key)
);

-- ทีมขาย (1 คน = 1 ทีม) — visible_employee_codes() ใช้หา "ลูกทีม"
create table teams (
  id           text primary key,
  name         text not null,
  leader_code  text references main_1_hr (employee_code) on update cascade on delete set null,
  revenue_goal numeric,
  sort_order   integer default 0,
  created_at   timestamptz default now()
);
alter table main_1_hr add column team_id text references teams (id) on update cascade on delete set null;

-- ใครถือ role อะไร — ผูกกับ employee_code (ไม่ใช่ id ปลอม u_stone ในแอป)
-- 1 คนถือได้หลาย role, สิทธิ์จริง = union (เช่น Stone = CEO + Agent)
create table user_roles (
  employee_code text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  role_id       text not null references roles (id)                on update cascade on delete cascade,
  primary key (employee_code, role_id)
);
create index idx_user_roles_role on user_roles (role_id);
create index idx_hr_auth_user    on main_1_hr (auth_user_id);

-- ---- helper ที่ RLS policy ทุกตัวจะเรียก ----
-- security definer: policy ต้องอ่าน user_roles/main_1_hr ได้ ก่อน policy ของตารางนั้นจะทำงาน
create or replace function my_permissions()
returns setof text language sql stable security definer set search_path = public as $$
  select distinct rp.permission_key
  from main_1_hr h
  join user_roles      ur on ur.employee_code = h.employee_code
  join role_permissions rp on rp.role_id       = ur.role_id
  where h.auth_user_id = auth.uid()
$$;

create or replace function has_perm(p text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from my_permissions() k where k = p)
$$;

-- employee_code ที่คนนี้เห็นข้อมูลได้ — own / team / all
--   org-wide (roles.manage | people.manage) -> ทุกคน   (CEO, HR)
--   หัวหน้าทีม (teams.leader_code = ตัวเอง)   -> ทั้งทีม (Sales Leader)
--   ที่เหลือ                                  -> ตัวเอง
create or replace function visible_employee_codes()
returns setof text language sql stable security definer set search_path = public as $$
  with me as (select employee_code, team_id from main_1_hr where auth_user_id = auth.uid())
  select h.employee_code
  from main_1_hr h
  where has_perm('roles.manage') or has_perm('people.manage')
     or h.employee_code = (select employee_code from me)
     or exists (select 1 from teams t
                where t.leader_code = (select employee_code from me) and h.team_id = t.id)
$$;

revoke execute on function my_permissions(), has_perm(text), visible_employee_codes() from public;
grant  execute on function my_permissions(), has_perm(text), visible_employee_codes() to authenticated;

-- ---- seed: catalog สิทธิ์ 35 ตัว + 7 บทบาท ----
insert into permissions (key, group_key, group_label, label, hint, sort_order) values
  ('leads.view_all','leads','Lead / ดีล','ดู Lead ทั้งหมด',null,10),
  ('leads.view_own','leads','Lead / ดีล','ดู Lead ของตัวเอง','เฉพาะที่ได้รับมอบหมาย',11),
  ('leads.create','leads','Lead / ดีล','เพิ่ม Lead (ปุ่มลอย)','รับสาย/แชท แล้วบันทึกลูกค้าเป็นลีด',12),
  ('leads.assign','leads','Lead / ดีล','มอบหมาย Lead',null,13),
  ('leads.edit','leads','Lead / ดีล','แก้ไข Lead',null,14),
  ('contacts.view_all','contacts','ผู้ติดต่อ','ดูผู้ติดต่อทั้งหมด',null,20),
  ('contacts.view_own','contacts','ผู้ติดต่อ','ดูเฉพาะที่สร้าง/ได้รับมอบหมาย',null,21),
  ('contacts.manage','contacts','ผู้ติดต่อ','จัดการผู้ติดต่อ',null,22),
  ('listings.view','inventory','คลังทรัพย์','ดูทรัพย์',null,30),
  ('listings.create','inventory','คลังทรัพย์','เพิ่มทรัพย์ใหม่','งานของเซลล์ — สร้างรายการทรัพย์ (แยกจากการแก้ไข)',31),
  ('listings.edit','inventory','คลังทรัพย์','แก้ไขทรัพย์',null,32),
  ('listings.marketing','inventory','คลังทรัพย์','การตลาด / ลงพอร์ทัล',null,33),
  ('projects.edit','inventory','คลังทรัพย์','แก้ไขโครงการ',null,34),
  ('lastmatch.add','inventory','คลังทรัพย์','เพิ่ม Last Match',null,35),
  ('lastmatch.view_all','inventory','คลังทรัพย์','ดู Last Match ทั้งบริษัท',null,36),
  ('lastmatch.view_team','inventory','คลังทรัพย์','ดู Last Match ของทีม','หัวหน้าทีมเห็นของลูกทีมทุกคน',37),
  ('lastmatch.view_own','inventory','คลังทรัพย์','ดู Last Match ของตัวเอง','เซลส์เห็นเฉพาะดีลที่ตัวเองปิด',38),
  ('activity.log','activity','กิจกรรม','บันทึกกิจกรรม','ติ๊กงานในแผนวันนี้แล้วระบบบันทึกกิจกรรมให้ — สำหรับคนที่ทำงานขาย',40),
  ('website.manage','website','เว็บพอร์ทัล','จัดการเนื้อหาเว็บหน้าบ้าน','เมนู / แบนเนอร์ / เนื้อหาบนเว็บพอร์ทัลลูกค้า — Marketing',50),
  ('performance.view_team','performance','เป้าหมาย / KPI','ดูผลงานทีม',null,60),
  ('performance.view_own','performance','เป้าหมาย / KPI','ดูผลงานตัวเอง',null,61),
  ('targets.set','performance','เป้าหมาย / KPI','ตั้งเป้าหมายให้ทีม',null,62),
  ('targets.stretch','performance','เป้าหมาย / KPI','ตั้งเป้าหมายส่วนตัวเพิ่ม',null,63),
  ('financials.view_comp','financials','การเงิน','ดูค่าตอบแทนของทีม (เงินเดือน/คอมมิชชั่น)','เงินเดือน + เรตคอมของพนักงาน — CEO/HR เท่านั้น',70),
  ('financials.payroll','financials','การเงิน','จัดการเงินเดือน',null,71),
  ('people.manage','people','บุคคล','จัดการพนักงาน (HR)',null,80),
  ('people.view_sensitive','people','บุคคล','ดูข้อมูลอ่อนไหว (บัตร ปชช./บัญชี/สลิป)','PII และเอกสารพนักงาน — CEO/HR เท่านั้น',81),
  ('teams.manage','people','บุคคล','จัดการทีมขาย','สร้างทีม กำหนดหัวหน้า และมอบหมายเซลเข้าทีม',82),
  ('leave.request','people','บุคคล','ขอลา','ยื่นใบลาจากหน้าแผนวันนี้',83),
  ('leave.manage','people','บุคคล','อนุมัติ / จัดการวันลา','ดูใบลาทุกคนและอนุมัติ — CEO / HR',84),
  ('people.manage_accounts','people','บุคคล','จัดการบัญชีผู้ใช้ (สร้าง/ตั้งรหัสผ่าน)','สร้างบัญชี login ใหม่ + รีเซ็ตรหัสผ่าน — เข้าถึงบัญชี auth โดยตรง CEO / HR เท่านั้น',85),
  ('masterdata.govern','masterdata','ข้อมูลหลัก','จัดการโซน & เทมเพลตกิจกรรม/KPI','โซน · ประเภทกิจกรรม · เทมเพลต KPI — CEO/หัวหน้า',90),
  ('reference.manage','masterdata','ข้อมูลหลัก','จัดการรายการอ้างอิง (ประเภททรัพย์ / ช่องทาง / ฟิลด์ Lead)','ประเภททรัพย์ · Marketing Channel · Contact By · เพศ · สัญชาติ',91),
  ('checklists.manage','masterdata','ข้อมูลหลัก','จัดการเช็คลิสต์ทรัพย์ (A-List / Exclusive)','เทมเพลตงานเพิ่มมูลค่าทรัพย์เด่น — CEO / Listing Support',92),
  ('copy.manage','masterdata','ข้อมูลหลัก','จัดการเทมเพลตคำโฆษณา','คำประกาศโฆษณาทรัพย์ (Headline / โพสต์ / DDproperty) — CEO / Marketing / Listing Support',93),
  ('roles.manage','system','ระบบ','จัดการบทบาท & สิทธิ์',null,100);

insert into roles (id, name, description, is_system, sort_order) values
  ('ceo','CEO','ผู้บริหารสูงสุด — เข้าถึงทุกอย่าง กำหนดบทบาทและสิทธิ์',true,1),
  ('agent','Agent (Sales)','เซลส์ / ดูแลดีลของตัวเอง',false,2),
  ('listing_support','Listing Support','งานสนับสนุนการลงประกาศ/คลังทรัพย์ + มอบหมายดีล',false,3),
  ('marketing','Marketing','การตลาด / โซเชียล / ลงโฆษณา',false,4),
  ('sales_leader','Sales Leader','หัวหน้าทีมขาย',false,5),
  ('admin','Admin','งานธุรการ / รับลีดทุกช่องทาง + มอบหมายดีล (ยังไม่มีผู้ดำรงตำแหน่ง)',false,6),
  ('hr','HR','งานบุคคล / เงินเดือน (ยังไม่มีผู้ดำรงตำแหน่ง)',false,7);

-- CEO = ทุกสิทธิ์ (superadmin)
insert into role_permissions (role_id, permission_key) select 'ceo', key from permissions;

insert into role_permissions (role_id, permission_key) values
  ('agent','leads.view_own'),('agent','leads.edit'),
  ('agent','contacts.view_own'),('agent','contacts.manage'),
  ('agent','listings.view'),('agent','listings.create'),('agent','listings.edit'),
  ('agent','lastmatch.add'),('agent','lastmatch.view_own'),
  ('agent','activity.log'),('agent','performance.view_own'),
  ('agent','targets.stretch'),('agent','leave.request'),

  -- leads.view_all เพิ่ม 2026-08-08: role นี้เป็นคนรับลีดเข้าระบบ + มอบหมายให้เซล แต่เดิม
  -- ไม่มีสิทธิ์ดูลีดเลยสักตัว → สร้างลีดเสร็จแล้วมองไม่เห็นของที่ตัวเองเพิ่งสร้าง
  ('listing_support','leads.create'),('listing_support','leads.assign'),
  ('listing_support','leads.view_all'),
  ('listing_support','contacts.view_all'),
  ('listing_support','listings.view'),('listing_support','listings.edit'),
  ('listing_support','listings.marketing'),('listing_support','projects.edit'),
  ('listing_support','lastmatch.add'),('listing_support','lastmatch.view_all'),
  ('listing_support','reference.manage'),('listing_support','checklists.manage'),
  ('listing_support','copy.manage'),('listing_support','performance.view_own'),
  ('listing_support','targets.stretch'),('listing_support','leave.request'),

  ('marketing','listings.view'),('marketing','listings.marketing'),
  ('marketing','website.manage'),('marketing','copy.manage'),
  ('marketing','performance.view_own'),('marketing','targets.stretch'),
  ('marketing','leave.request'),

  ('sales_leader','leads.view_all'),('sales_leader','leads.create'),
  ('sales_leader','leads.edit'),('sales_leader','leads.assign'),
  ('sales_leader','contacts.view_all'),('sales_leader','contacts.manage'),
  ('sales_leader','listings.view'),('sales_leader','listings.create'),
  ('sales_leader','listings.edit'),('sales_leader','lastmatch.add'),
  ('sales_leader','lastmatch.view_team'),('sales_leader','activity.log'),
  ('sales_leader','performance.view_own'),('sales_leader','performance.view_team'),
  ('sales_leader','targets.set'),('sales_leader','targets.stretch'),
  ('sales_leader','leave.request'),

  ('admin','leads.view_all'),('admin','leads.create'),('admin','leads.edit'),
  ('admin','leads.assign'),('admin','contacts.view_all'),('admin','contacts.manage'),
  ('admin','listings.view'),('admin','leave.request'),

  ('hr','people.manage'),('hr','people.view_sensitive'),
  ('hr','financials.view_comp'),('hr','financials.payroll'),
  ('hr','performance.view_team'),('hr','leave.request'),('hr','leave.manage'),
  ('hr','people.manage_accounts');
-- `system_admin` ไม่ได้อยู่ในไฟล์นี้ (สร้างนอกรอบตอน provision บัญชีจริง, ดู CLAUDE.md) —
-- ถ้า setup ใหม่หมดและสร้าง system_admin ซ้ำ ต้องเพิ่ม role_permissions ให้มันครบทุกตัวเอง

-- user_roles + teams เว้นว่างไว้ — ต้องรอ import main_1_hr ของจริงก่อน
-- (ตอนนี้ในตารางเป็นข้อมูล demo, ทีมจริงยังไม่ยืนยัน)


-- ============================================================
-- 3) TABLE: main_2_owner  (Owner 1 คน -> หลาย listing)
-- ============================================================
create table main_2_owner (
  owner_id    bigint generated always as identity primary key,
  owner_name  text, owner_phone text, owner_line text,
  remark      text,
  created_at  timestamptz default now()
);


-- ============================================================
-- 4) TABLE: main_3_property_detail  (+ auto Project ID : PROJECT-001)
-- ============================================================
create table main_3_property_detail (
  project_id           text primary key,
  project_name_eng     text,  project_name_thai text,
  property_type        text references property_type (name) on update cascade,
  zone                 text references zone (zone_id)       on update cascade,
  total_units          int,   phases int,
  unit_types           text,  material text,  floor_to_ceiling text,  project_age text,
  facilities           text,  common_fee numeric,  juristic text,
  juristic_collect_pct numeric,  extra_parking_fee numeric,
  rental_price_in_project text,  flooding boolean,
  resident_occupation  text,  project_sold_price text,
  pros text, cons text,
  sales_id             text references main_1_hr (employee_code) on update cascade,  -- Sales_id
  date_created         date default current_date,
  updated_at           timestamptz default now(),
  created_at           timestamptz default now()
);

create or replace function set_project_id()
returns trigger language plpgsql as $$
declare next_num int;
begin
  if new.project_id is null or new.project_id = '' then
    select coalesce(max(substring(project_id from '[0-9]+$')::int),0)+1 into next_num from main_3_property_detail;
    new.project_id := 'PROJECT-' || lpad(next_num::text,3,'0');
  end if;
  return new;
end; $$;
drop trigger if exists trg_set_project_id on main_3_property_detail;
create trigger trg_set_project_id before insert on main_3_property_detail
  for each row execute function set_project_id();

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end; $$;
drop trigger if exists trg_main_3_property_detail_updated on main_3_property_detail;
create trigger trg_main_3_property_detail_updated before update on main_3_property_detail
  for each row execute function set_updated_at();


-- ============================================================
-- 5) TABLE: main_4_listing_database  (+ auto Listing ID : HRM5001)
-- ============================================================
create table main_4_listing_database (
  listing_id         text primary key,        -- auto-run
  date_created       date default current_date,
  project_id         text references main_3_property_detail (project_id) on update cascade,  -- โยงโครงการ (listing_name/project_name_eng ดึงจากโครงการนี้ผ่าน v_main_listing)
  listing_status     text references listing_status (name)    on update cascade,
  potential          text references listing_potential (name) on update cascade,  -- Potential (FK)
  sign               boolean default false,
  vdo                boolean default false,
  ddproperty_link    text,
  livinginsider_link text,
  livinginsider_date date,                    -- auto ตอนกรอกลิงก์ครั้งแรก (คิด Days on Market)
  propertyhub_link   text,                    -- (เดิม facebook_link)
  old_price          numeric,  new_price numeric,  update_remark text,
  owner_focus        boolean default false,
  listing_type       text references listing_type (name) on update cascade,
  unit_no            text,
  owner_id           bigint references main_2_owner (owner_id),
  owner_talk_last_date date,  activity_comment text,
  property_type      text references property_type (name)  on update cascade,
  in_out_project     text references in_out_project (name) on update cascade,
  road_soi           text,
  zone               text references zone (zone_id)        on update cascade,
  bed int, bath numeric,
  area_rai numeric, area_ngan numeric, area_wa numeric, area_sqm numeric,
  floor text, building text,
  direction          text references direction (name)     on update cascade,
  view_type          text references view_type (name)     on update cascade,
  unit_position      text references unit_position (name) on update cascade,
  parking int,
  asking_price numeric, rental_price numeric,
  price_remark       text references price_remark (name) on update cascade,
  remark text, link_location text,
  unit_condition     text references unit_condition (name) on update cascade,
  created_by         uuid default auth.uid(),  -- << RLS (แยกไฟล์) — "ใครสร้างแถว"
  -- เซลที่ดูแลทรัพย์หลังนี้ = ตัวตัดสินว่าลีดที่สนใจทรัพย์นี้ไปหาใคร (คนละเรื่องกับ created_by)
  sale_id            text references main_1_hr (employee_code) on update cascade on delete set null,
  shorts_reels_link text, hometour_link text,

  -- ==== 17 คอลัมน์จากชีท Listings (เพิ่ม 2026-08-03) ====
  -- งานการตลาด (CEO ขอ)
  dd_boost date, lv_boost date, fb_repost date,
  marketing_report text, facebook_ad_link text, new_photo_link text,
  -- ลิงก์/ข้อมูลที่ตกหล่น
  hook text, photo_album_link text, link text,
  -- Last Match ที่ผูกกับทรัพย์หลังนี้ (คนละอันกับตาราง main_7_last_match)
  last_match text, last_match_type text, last_match_price numeric, last_match_remark text,
  -- ส่วนกลาง: เก็บเป็น "เรต" เพราะชีทปน 3 หน่วย (45 บาท/ตร.ว./เดือน · 44,000/ปี · เดือนละ 2,024)
  -- ยอดรวมให้เว็บคูณพื้นที่เอาเอง / common_fee_note เก็บข้อความดิบกันข้อมูลหาย
  common_fee_rate numeric,
  common_fee_unit text check (common_fee_unit is null or common_fee_unit in ('per_wa_month','per_sqm_month')),
  common_fee_note text,
  -- อายุ -> เก็บ "ปีที่สร้าง" (ค.ศ.) อายุคำนวณตอนแสดงผล ไม่งั้นข้อมูลผิดเองทุกปี
  built_year int check (built_year is null or built_year between 1900 and 2200),

  updated_at timestamptz default now(),
  created_at timestamptz default now()
);

create or replace function set_listing_id()
returns trigger language plpgsql as $$
declare v_code text; prefix text; next_num int;
begin
  if new.listing_id is null or new.listing_id = '' then
    select code into v_code from property_type where name = new.property_type;
    if v_code is null or new.zone is null then
      raise exception 'ต้องระบุ property_type และ zone ก่อน (property_type=%, zone=%)', new.property_type, new.zone;
    end if;
    prefix := v_code || new.zone;   -- new.zone = Zone ID (ตัวย่อ)
    select coalesce(max(substring(listing_id from length(prefix)+1)::int),0)+1 into next_num
      from main_4_listing_database where left(listing_id, length(prefix)) = prefix;
    new.listing_id := prefix || lpad(next_num::text,3,'0');
  end if;
  return new;
end; $$;
drop trigger if exists trg_set_listing_id on main_4_listing_database;
create trigger trg_set_listing_id before insert on main_4_listing_database
  for each row execute function set_listing_id();

create or replace function set_livinginsider_date()
returns trigger language plpgsql as $$
begin
  if new.livinginsider_link is not null and new.livinginsider_link <> ''
     and new.livinginsider_date is null then
    new.livinginsider_date := current_date;
  end if;
  new.updated_at := now();
  return new;
end; $$;
drop trigger if exists trg_set_livinginsider_date on main_4_listing_database;
create trigger trg_set_livinginsider_date before insert or update on main_4_listing_database
  for each row execute function set_livinginsider_date();


-- ============================================================
-- 6) TABLE: main_5_lead_database  (+ auto Lead-Id : L26-001)
-- ============================================================
create table main_5_lead_database (
  lead_id            text primary key,        -- auto-run
  date_received      date,
  lead_type          text references lead_type (name) on update cascade,
  listing_code       text references main_4_listing_database (listing_id) on update cascade,  -- โยง listing
  listing_name       text,
  lead_name text, phone text, line_id text,
  gender             text references gender (name)      on update cascade,
  nationality        text references nationality (name) on update cascade default 'Thai',
  remark text,
  sales_id           text references main_1_hr (employee_code) on update cascade,  -- โยง HR
  contact_date date,
  contact_time time,
  marketing_channel       text references marketing_channel (name) on update cascade,
  marketing_channel_other text,
  contact_by              text references contact_by (name) on update cascade,
  line_userid text,                          -- ดึงจาก main_1_hr ผ่าน sales_id (ไม่ทำ FK ตรง)
  customer_complain text,
  complain_status    text references complain_status (name) on update cascade,
  complain_remark text,
  created_at timestamptz default now()
);

-- ⚠️ นับเลขจาก main_5 + main_6 ทั้งคู่ (แก้ 2026-08-08) — ทั้งสองตารางใช้ id ชุดเดียวกัน
-- (main_6.lead_id มิเรอร์ main_5.lead_id) ถ้าดูแค่ main_5 จะพังทันทีเมื่อ main_5 ว่างแต่
-- main_6 มีข้อมูล ซึ่งเป็นสถานะจริงหลัง import 2026-08-03 (main_5 = 0 แถว, main_6 = 953)
-- → เลขจะเริ่มใหม่ที่ L26-001 แล้วไปชน lead_id ที่มีอยู่จริงในลีดที่ 7
create or replace function set_lead_database_id()
returns trigger language plpgsql as $$
declare yy text := to_char(now(),'YY'); next_num int;
begin
  if new.lead_id is null or new.lead_id = '' then
    select coalesce(max((split_part(lead_id,'-',2))::int),0)+1 into next_num
    from (
      select lead_id from main_5_lead_database where lead_id like 'L' || yy || '-%'
      union all
      select lead_id from main_6_buyer_crm     where lead_id like 'L' || yy || '-%'
    ) all_leads;
    new.lead_id := 'L' || yy || '-' || lpad(next_num::text,3,'0');
  end if;
  return new;
end; $$;
drop trigger if exists trg_set_lead_database_id on main_5_lead_database;
create trigger trg_set_lead_database_id before insert on main_5_lead_database
  for each row execute function set_lead_database_id();


-- ============================================================
-- 7) TABLE: main_6_buyer_crm  (โยง lead + hr)
-- ============================================================
create table main_6_buyer_crm (
  lead_id          text primary key,          -- Lead ID (ของ CRM)
  date_received    date,
  listing_code     text,
  potential        text references potential (name)      on update cascade,
  lead_status      text references lead_status (name)    on update cascade,
  pipeline_stage   text references pipeline_stage (name) on update cascade,
  bank_loan        text references bank_loan (name)      on update cascade,
  interested       text,                       -- ดึงผ่าน lead_ref ได้
  lead_type        text references lead_type (name) on update cascade,  -- dropdown
  lead_ref         text references main_5_lead_database (lead_id) on update cascade,  -- โยงลีด
  sale_id          text references main_1_hr (employee_code) on update cascade,       -- โยง HR
  lead_name text, phone text, admin_remark text, line_id text,
  budget numeric, progress int,
  last_follow_date date, activity_comment text, commission numeric,
  closing_date date, transfer_date date, case_closing_remark text,
  complete boolean default false, confirm boolean default false,

  -- ==== คอลัมน์ intake ที่ฟอร์มเก็บอยู่แล้ว (เพิ่ม 2026-08-03) ====
  -- เก็บตรงนี้ ไม่ดึงจาก main_5 ผ่าน view เพราะ lead_ref ว่างทุกแถว + main_6 เป็นข้อมูลที่เซลแก้ได้
  -- (main_5 = บันทึกตอนรับลีด ไม่ควรถูกทับ) — ชื่อคอลัมน์ตั้งให้ตรงกับ main_5 ทั้งหมด
  tag_id                  text references lead_tags_ref (id)        on update cascade,  -- แอปเรียก tag
  marketing_channel       text references marketing_channel (name)  on update cascade,  -- แอปเรียก source
  marketing_channel_other text,
  contact_by              text references contact_by (name)         on update cascade,
  gender                  text references gender (name)             on update cascade,
  nationality             text references nationality (name)        on update cascade,
  contact_date date, contact_time time,
  customer_complain       text,
  complain_status         text references complain_status (name)    on update cascade,
  complain_remark         text,
  -- หมายเหตุ: ไม่มี recheck_status — "เซลติดต่อลูกค้าแล้วยัง" derive จาก pipeline_stage
  -- (สเตจไหนก็ตามที่เลย 'Lead' = ติดต่อแล้ว) เก็บเป็นคอลัมน์จะกลายเป็นข้อมูล 2 ชุดที่ขัดกันเอง

  -- ==== ความต้องการของลูกค้า (เพิ่ม 2026-08-08 ตอนต่อฟอร์มเพิ่มลีด) ====
  -- อยู่ main_6 ไม่ใช่ main_5 เพราะเป็นข้อมูลที่เซลแก้ได้เรื่อยๆ (main_5 freeze ตอนรับลีด)
  -- ราคาที่เจ้าของต้องการใช้ budget ช่องเดิม (ฟอร์มใช้เป็นทั้งงบผู้ซื้อ/ราคาเจ้าของอยู่แล้ว)
  interest_zone           text references zone (zone_id)             on update cascade,
  interest_property_type  text references property_type (name)       on update cascade,
  purpose                 text references lead_purpose (name)        on update cascade,  -- ผู้ซื้อ
  sell_reason             text references sell_reason (name)         on update cascade,  -- เจ้าของ

  created_at timestamptz default now()
);


-- ============================================================
-- 8) TABLE: main_7_last_match  (+ auto Last Match ID : Sale_id + เลขรัน)
-- ============================================================
create table main_7_last_match (
  last_match_id     text primary key,
  sale_id           text references main_1_hr (employee_code) on update cascade,
  close_type        text references close_type (name)    on update cascade,
  project_name      text,
  property_type     text references property_type (name) on update cascade,
  zone              text references zone (zone_id)       on update cascade,
  sq_wa numeric, sq_m numeric, bed int, bath numeric,
  last_match_price  numeric, last_match_remark text, buyer_persona text,
  date_created      date default current_date,
  created_at        timestamptz default now()
);

create or replace function set_last_match_id()
returns trigger language plpgsql as $$
declare next_num int;
begin
  if new.last_match_id is null or new.last_match_id = '' then
    if new.sale_id is null or new.sale_id = '' then
      raise exception 'ต้องระบุ sale_id ก่อน (เพื่อสร้าง Last Match ID)';
    end if;
    select coalesce(max(substring(last_match_id from '[0-9]+$')::int),0)+1 into next_num
      from main_7_last_match where sale_id = new.sale_id;
    new.last_match_id := new.sale_id || '-' || lpad(next_num::text,3,'0');
  end if;
  return new;
end; $$;
drop trigger if exists trg_set_last_match_id on main_7_last_match;
create trigger trg_set_last_match_id before insert on main_7_last_match
  for each row execute function set_last_match_id();


-- ============================================================
-- 9) TABLE: main_8_listing_photo
-- ============================================================
create table main_8_listing_photo (
  photo_id    bigint generated always as identity primary key,
  listing_id  text references main_4_listing_database (listing_id) on delete cascade,
  photo_url   text, sort_order int,
  created_at  timestamptz default now()
);


-- ============================================================
-- 9.1) TABLE: main_9_support_log  (log การทำงานของ Support)
-- 1 แถว = 1 การกระทำ (เปลี่ยนสถานะ/จัดการ listing 1 ครั้ง)
-- ============================================================
create table main_9_support_log (
  log_id        bigint generated always as identity primary key,
  listing_id    text references main_4_listing_database (listing_id) on delete cascade,
  support_id    text references main_1_hr (employee_code) on update cascade,  -- ใครทำ (Support)
  action        text,                                          -- ทำอะไร (freeform)
  status_before text references listing_status (name) on update cascade,      -- สถานะก่อนแก้
  status_after  text references listing_status (name) on update cascade,      -- สถานะหลังแก้
  remark        text,
  created_at    timestamptz default now()
);

-- trigger: auto บันทึก log เมื่อ listing_status เปลี่ยน (และตอนสร้าง listing ใหม่)
-- support_id (ใครทำ) = null ไว้ก่อน — DB รู้แค่ auth.uid() (uuid) ยังไม่มี mapping -> main_1_hr.employee_code
-- (ค่อยเติมตอนทำ RLS/auth mapping) ; แอปจะ update support_id เพิ่มทีหลังก็ได้
create or replace function log_listing_status_change()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    if new.listing_status is not null then
      insert into main_9_support_log (listing_id, action, status_before, status_after)
        values (new.listing_id, 'created', null, new.listing_status);
    end if;
  elsif tg_op = 'UPDATE' then
    if new.listing_status is distinct from old.listing_status then
      insert into main_9_support_log (listing_id, action, status_before, status_after)
        values (new.listing_id, 'status change', old.listing_status, new.listing_status);
    end if;
  end if;
  return null;  -- AFTER trigger : return value ไม่ถูกใช้
end; $$;
drop trigger if exists trg_log_listing_status on main_4_listing_database;
create trigger trg_log_listing_status
  after insert or update of listing_status on main_4_listing_database
  for each row execute function log_listing_status_change();


-- ============================================================
-- 9.2) TABLE: main_10_potential_listing  (แยกเฉพาะ listing potential สูง = A List/Exclusive)
-- Hybrid: คอลัมน์ auto ดึงจาก listing (trigger) + คอลัมน์ให้ Support กรอกเอง
-- • เข้าเกณฑ์ (A List/A List + Fb add/Exclusive/Exclusive A) -> upsert เข้ามา
-- • หลุดเกณฑ์ (เช่นเซลเปลี่ยน potential เป็น Normal) -> เก็บ log แล้ว "ลบออก"
-- ============================================================
create table main_10_potential_listing (
  listing_id        text primary key references main_4_listing_database (listing_id) on delete cascade,
  date_a_list       date,                                       -- Date A List (วันที่เข้าเกณฑ์ - auto ตอน insert)
  potential         text references listing_potential (name) on update cascade,  -- auto-sync
  project_name_thai text,                                       -- Project name (ไทย) - auto ดึงจากโครงการ
  unit_condition    text references unit_condition (name) on update cascade,  -- auto ดึงจาก listing
  price             numeric,                                    -- Price - auto (asking_price / new_price)
  sale_id           text references main_1_hr (employee_code) on update cascade,  -- auto จากโซนที่รับผิดชอบ

  -- ===== ส่วนที่ Support กรอกเอง (trigger ไม่แตะ) =====
  template_link     text,                                       -- Template Link
  marketplace       boolean default false,                      -- Market Place
  profile           boolean default false,                      -- Profile
  group_date        date,                                       -- Group (ใส่วันที่เอง)
  group_boost_date  date,                                       -- Group Boost (ใส่วันที่เอง)

  -- ===== ลิงก์ - auto ดึงจาก listing =====
  ddproperty_link   text,
  livinginsider_link text,
  propertyhub_link  text,                                       -- (เดิม facebook_link)

  updated_at        timestamptz default now(),
  created_at        timestamptz default now()
);

-- Log ประวัติเข้า/ออกเกณฑ์ A List (เก็บไว้แม้ลบออกจาก main_10 แล้ว)
create table main_11_potential_listing_log (
  log_id      bigint generated always as identity primary key,
  listing_id  text,                        -- ไม่ทำ FK เพื่อให้ log อยู่ต่อแม้ listing ถูกลบ
  potential   text,                        -- potential ตอนเกิดเหตุการณ์
  action      text,                        -- 'added' | 'removed'
  sale_id     text,
  date_a_list date,
  changed_at  timestamptz default now()
);

-- trigger: sync listing potential สูง เข้า/ออก main_10 + เขียน log
create or replace function sync_potential_listing()
returns trigger language plpgsql as $$
declare
  v_tier      boolean := new.potential in ('A List','A List + Fb add','Exclusive','Exclusive A');
  v_exists    boolean;
  v_sale      text;
  v_proj_thai text;
begin
  select exists(select 1 from main_10_potential_listing where listing_id = new.listing_id) into v_exists;

  if v_tier then
    -- ดึงค่าประกอบแบบ auto
    -- ผู้ดูแลทรัพย์คือตัวจริง; ถ้ายังไม่ระบุค่อยใช้เจ้าภาพโซน
    v_sale := coalesce(new.sale_id, zone_primary_sale(new.zone));
    select project_name_thai into v_proj_thai from main_3_property_detail where project_id = new.project_id;

    insert into main_10_potential_listing (
      listing_id, date_a_list, potential, project_name_thai, unit_condition, price, sale_id,
      ddproperty_link, livinginsider_link, propertyhub_link
    ) values (
      new.listing_id, current_date, new.potential, v_proj_thai, new.unit_condition,
      new.asking_price, v_sale,
      new.ddproperty_link, new.livinginsider_link, new.propertyhub_link
    )
    on conflict (listing_id) do update set
      potential          = excluded.potential,
      project_name_thai  = excluded.project_name_thai,
      unit_condition     = excluded.unit_condition,
      price              = excluded.price,
      sale_id            = excluded.sale_id,
      ddproperty_link    = excluded.ddproperty_link,
      livinginsider_link = excluded.livinginsider_link,
      propertyhub_link   = excluded.propertyhub_link,
      updated_at         = now();
      -- ไม่แตะ date_a_list และคอลัมน์ที่ Support กรอกเอง (template_link/marketplace/profile/group_*)

    if not v_exists then
      insert into main_11_potential_listing_log (listing_id, potential, action, sale_id, date_a_list)
        values (new.listing_id, new.potential, 'added', v_sale, current_date);
    end if;

  else
    -- หลุดเกณฑ์: ถ้ามีอยู่ -> log 'removed' แล้วลบออก
    if v_exists then
      insert into main_11_potential_listing_log (listing_id, potential, action, sale_id, date_a_list)
        select p.listing_id, new.potential, 'removed', p.sale_id, p.date_a_list
        from main_10_potential_listing p where p.listing_id = new.listing_id;
      delete from main_10_potential_listing where listing_id = new.listing_id;
    end if;
  end if;

  return new;
end; $$;
drop trigger if exists trg_sync_potential_listing on main_4_listing_database;
create trigger trg_sync_potential_listing
  after insert or update on main_4_listing_database
  for each row execute function sync_potential_listing();


-- ============================================================
-- 9.3) ตารางที่เว็บแอปต้องใช้  (เพิ่ม 2026-08-03)
-- โครงตรงกับ type ใน haus-crm/lib/{actions,momentum,contacts,leave,notifications}.ts
-- ทุกตารางอ้างพนักงานด้วย employee_code (แอปใช้ชื่อเล่น — map ตอน import)
-- ============================================================

-- ---- catalog กิจกรรม (ตรงกับ ACTION_GROUPS) ----
-- attach = ผูกกับอะไรได้: lead / listing / either / none
create table action_type (
  name        text primary key,
  group_label text not null,
  attach      text not null default 'none' check (attach in ('lead','listing','either','none')),
  sort_order  integer default 0,
  is_active   boolean default true
);
insert into action_type (name, group_label, attach, sort_order) values
  ('Call','ไปป์ไลน์ (ลูกค้า)','lead',10),
  ('Follow','ไปป์ไลน์ (ลูกค้า)','lead',11),
  ('Appoint','ไปป์ไลน์ (ลูกค้า)','lead',12),
  ('Show','ไปป์ไลน์ (ลูกค้า)','lead',13),
  ('Nego','ไปป์ไลน์ (ลูกค้า)','lead',14),
  ('Close','ไปป์ไลน์ (ลูกค้า)','lead',15),
  ('Win','ไปป์ไลน์ (ลูกค้า)','lead',16),
  ('Owner Visit','งานทรัพย์','listing',20),
  ('Survey','งานทรัพย์','listing',21),
  ('ประเมิน','งานทรัพย์','listing',22),
  ('New List','งานทรัพย์','listing',23),
  ('ถ่ายรูป','งานทรัพย์','listing',24),
  ('Reels','งานทรัพย์','listing',25),
  ('ติดป้าย','งานทรัพย์','listing',26),
  ('โอน','งานทรัพย์','listing',27),
  ('ประชุม','ทั่วไป','none',30),
  ('ทำงานหน้าคอม','ทั่วไป','none',31),
  ('Sourcing','ทั่วไป','none',32),
  ('อื่นๆ','ทั่วไป','none',33),
  ('บันทึก','บันทึกโน้ต','either',40);
-- ⚠️ ชีท Actions มี 23 ค่าที่เขียนไม่ตรงกัน (Show/Showing, Reels/ถ่าย Reels) ต้อง map เข้าชุดนี้ตอน import

-- ---- เป้าหมายรายเดือน ----
create table targets (
  id             bigint generated always as identity primary key,
  employee_code  text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  month          text not null,                    -- 'YYYY-MM'
  label          text not null,
  kind           text not null default 'count' check (kind in ('count','baht','check','ratio')),
  target         numeric not null default 0,
  -- source=activity คำนวณสดจาก activities (ไม่ใช้ manual_current)
  -- kind=ratio: manual_current = ตัวเศษ, denominator = ตัวส่วน
  manual_current numeric default 0,
  denominator    numeric,
  source         text not null default 'manual' check (source in ('activity','pipeline','manual','kpi')),
  activity_type  text references action_type (name) on update cascade,
  owner          text not null default 'stretch' check (owner in ('official','stretch')),
  -- จังหวะโฟกัสรายสัปดาห์ (Owner Talk=wk1, Sourcing/Survey=wk2-3, Buyer Follow=wk4)
  focus_week_start integer, focus_week_end integer, focus_label text,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create index idx_targets_emp_month on targets (employee_code, month);

-- ---- แผนวันนี้ ----
-- ติ๊กงานที่ผูก activity_type = เขียน activities (write path เดียวของกิจกรรม หลังเอา FAB ออก)
create table tasks (
  id            bigint generated always as identity primary key,
  employee_code text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  task_date     date not null,
  title         text not null,
  done          boolean default false,
  sort_order    integer default 0,
  task_type     text not null default 'work' check (task_type in ('build','work','personal')),
  notes         text,
  target_id     bigint references targets (id) on delete set null,
  activity_type text references action_type (name) on update cascade,
  related_lead_id    text references main_6_buyer_crm (lead_id)          on update cascade on delete set null,
  related_listing_id text references main_4_listing_database (listing_id) on update cascade on delete set null,
  start_time time, end_time time,
  repeat_freq text check (repeat_freq is null or repeat_freq in ('none','daily','weekdays','weekly','monthly')),
  repeat_weekdays integer[], repeat_day_of_month integer,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create index idx_tasks_emp_date on tasks (employee_code, task_date);

-- ---- บันทึกกิจกรรม (input ของ KPI · ladder เซลใหม่ · timeline · leaderboard) ----
create table activities (
  id             bigint generated always as identity primary key,
  employee_code  text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  action         text not null references action_type (name) on update cascade,
  activity_date  date not null,   -- วันของ "งาน" ไม่ใช่วันที่กด (ติ๊กย้อนหลังต้องลงวันนั้น)
  count          integer not null default 1 check (count > 0),
  remark         text,
  related_lead_id    text references main_6_buyer_crm (lead_id)          on update cascade on delete set null,
  related_listing_id text references main_4_listing_database (listing_id) on update cascade on delete set null,
  -- unique: ติ๊กงานเดิมซ้ำต้องไม่นับซ้ำ / ยกเลิกติ๊กแล้วแถวนี้หายไปด้วย
  task_id        bigint unique references tasks (id) on delete cascade,
  created_at     timestamptz default now()
);
create index idx_activities_emp_date on activities (employee_code, activity_date);
create index idx_activities_lead     on activities (related_lead_id);
create index idx_activities_listing  on activities (related_listing_id);

-- ---- ปุ่มลัดเพิ่มงานรายคน (เดิมอยู่ localStorage) ----
create table user_quick_actions (
  id            bigint generated always as identity primary key,
  employee_code text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  label         text not null,
  task_type     text not null default 'work' check (task_type in ('build','work','personal')),
  activity_type text references action_type (name) on update cascade,
  sort_order    integer default 0
);
create index idx_quick_actions_emp on user_quick_actions (employee_code);

-- ---- ผู้ติดต่อ ----
-- created_by / assigned_to = กติกาความเป็นส่วนตัว (เซลเห็นของตัวเอง เว้นมี contacts.view_all)
-- ทรัพย์ที่ถือ + ความต้องการ ไม่เก็บที่นี่ — derive จาก main_4/main_6
-- ⚠️ ตอน import ต้อง dedupe กับ main_2_owner ด้วยเบอร์โทร
create table contacts (
  id          bigint generated always as identity primary key,
  name        text not null,
  phone       text, line_id text, email text, note text,
  created_by  text references main_1_hr (employee_code) on update cascade on delete set null,
  assigned_to text references main_1_hr (employee_code) on update cascade on delete set null,
  created_at  timestamptz default now(), updated_at timestamptz default now()
);
create index idx_contacts_phone   on contacts (phone);
create index idx_contacts_created on contacts (created_by);

-- 1 คนเป็นได้หลายบทบาท (เจ้าของหลังนึง + ผู้ซื้ออีกหลัง)
create table contact_roles (
  contact_id bigint not null references contacts (id) on delete cascade,
  role       text not null check (role in ('owner','buyer','tenant','landlord')),
  primary key (contact_id, role)
);

-- ---- วันลา ----
create table leave_type (name text primary key);
insert into leave_type (name) values
  ('ลาพักร้อน'),('ลากิจ'),('ลาป่วย'),('ลาคลอด'),('ลาเพื่อทำหมัน'),('อื่นๆ');

-- โควตาระดับบริษัท (ยังไม่มี override รายคน)
-- ⚠️ ตัวเลขชุดนี้เป็น "ขั้นต่ำตามกฎหมาย" ไม่ใช่นโยบายบริษัท — ชีทไม่มีคอลัมน์โควตา
--    หลักฐานว่าผิด: เทียบ 6 วัน/ปี มีพนักงาน 5 จาก 8 คนใช้เกินแล้วในปี 2026 (Golf 17, Pup 10)
--    ต้องขอตัวเลขจริงจาก HR ก่อนใช้งาน
create table leave_allowances (
  type          text primary key references leave_type (name) on update cascade,
  days_per_year integer,          -- null = ไม่นับโควตาปี (ลาคลอด/ทำหมัน)
  note          text
);
insert into leave_allowances (type, days_per_year, note) values
  ('ลาพักร้อน', 6,  'ขั้นต่ำตามกฎหมาย — ยืนยันกับ HR'),
  ('ลากิจ',     3,  'ขั้นต่ำตามกฎหมาย — ยืนยันกับ HR'),
  ('ลาป่วย',    30, 'สูงสุดที่ได้รับค่าจ้าง'),
  ('ลาคลอด',    null, 'ตามกฎหมาย ไม่นับโควตาปี'),
  ('ลาเพื่อทำหมัน', null, 'ตามที่แพทย์กำหนด'),
  ('อื่นๆ',     null, 'ไม่นับโควตา');

-- ชีทต้นทางไม่มีคอลัมน์อนุมัติเลย — CRM เพิ่มขั้นตอนนี้ใหม่ (Ben, 2026-08-01)
-- โควตาหักเฉพาะ approved (ใบที่รออนุมัติต้องไม่กินโควตาไปก่อน)
create table leave_requests (
  id            bigint generated always as identity primary key,
  employee_code text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  submitted_at  timestamptz default now(),
  start_date    date not null,
  end_date      date not null,
  type          text not null references leave_type (name) on update cascade,
  remark        text,
  status        text not null default 'pending' check (status in ('pending','approved','rejected')),
  decided_by    text references main_1_hr (employee_code) on update cascade on delete set null,
  decided_at    timestamptz,
  created_at    timestamptz default now(),
  -- ชีทมีแถววันเริ่มอยู่หลังวันสิ้นสุด (Golf 09/10 -> 20/06) กันไม่ให้เข้ามาอีก
  constraint leave_date_order check (start_date <= end_date)
);
-- ชีทมีแถวซ้ำเป๊ะ 2 แถว (Golf ลาเพื่อทำหมัน 14/08) — กันนับซ้ำตั้งแต่ import
create unique index uq_leave_dedupe on leave_requests (employee_code, start_date, end_date, type);
create index idx_leave_emp on leave_requests (employee_code);

-- ---- แจ้งเตือน ----
-- ไม่มี permission gate: ทุกคนมีกระดิ่ง การกรองแถว (RLS) คือความปลอดภัยทั้งหมด
-- ⚠️ body ของ deal_won มีมูลค่าดีล ถ้า scope ผิด = หลุดตัวเลขเงินที่ financials.view_comp กันไว้
-- ข้อความเก็บเป็นข้อความสำเร็จรูป (ไม่ใช่ template) — แก้คำทีหลังไม่ย้อนไปแถวเก่า
-- ============================================================
-- บันไดขั้นเซลล์ใหม่ (โปรเบชั่น) — CEO แก้ที่ ตั้งค่า → Rank เซลล์ใหม่
-- เดิมอยู่ใน React Provider แบบ in-memory (แก้แล้วรีเฟรชหาย) ย้ายเข้า DB 2026-08-14
-- Rank เรียงตาม sort_order · ผ่าน Rank สุดท้าย = ผ่านโปรเบชั่น
-- ============================================================
-- ============================================================
-- แจ้งเตือนตอนมอบหมายลีด (2026-08-17)
-- policy INSERT ของ notifications เป็น own-row โดยตั้งใจ (กันแจ้งเตือนปลอม) → คนที่มอบลีด
-- ให้คนอื่นเขียนแจ้งเตือนถึงคนนั้นไม่ได้ ซึ่งเป็นจุดประสงค์ทั้งหมดของมัน
-- เลือก trigger แทน RPC เพราะลีดเข้าทาง n8n เป็นหลัก (952/953 มี sale_id มาแต่ต้นทาง)
-- RPC จะครอบเฉพาะตอนคนกดปุ่มในเว็บ → เงียบตอนที่ควรดังที่สุด
--
-- ⚠️ IMPORT ลีดเป็นก้อนเมื่อไหร่ ให้ปิด trigger ก่อน ไม่งั้นยิงแจ้งเตือนพันกว่าใบ:
--     alter table main_6_buyer_crm disable trigger trg_notify_lead_assigned;
-- ============================================================
create or replace function notify_lead_assigned()
returns trigger
language plpgsql
-- ต้องเป็น security definer เพราะเขียนแถวที่ "ผู้รับ != คนที่ทำ" ซึ่ง RLS ปฏิเสธโดยตั้งใจ
security definer
set search_path = public
as $$
declare
  actor_code text; actor_name text; lead_label text;
begin
  -- WHEN ของ trigger อ้าง OLD ไม่ได้ตอน INSERT จึงเช็คตรงนี้: แตะ sale_id แต่ค่าเท่าเดิม = ไม่ได้ย้ายมือ
  if tg_op = 'UPDATE' and new.sale_id is not distinct from old.sale_id then
    return new;
  end if;

  -- ไม่เตือนตัวเอง
  actor_code := current_employee_code();
  if new.sale_id = actor_code then return new; end if;

  -- ผู้รับต้องยัง Active (FK ไม่ได้เช็คสถานะให้)
  if not exists (
    select 1 from main_1_hr
    where employee_code = new.sale_id and coalesce(status,'') ilike 'active%'
  ) then return new; end if;

  select nickname into actor_name from main_1_hr where employee_code = actor_code;
  lead_label := coalesce(nullif(trim(new.lead_name), ''), new.lead_id);

  insert into notifications(employee_code, type, title, body, entity, entity_id, actor)
  values (
    new.sale_id, 'lead_assigned',
    'ได้รับ Lead ใหม่: ' || lead_label,
    case when new.phone is not null then 'เบอร์ ' || new.phone else null end,
    'lead', new.lead_id,
    coalesce(actor_name, 'ระบบ')  -- null = มาจาก n8n / service role
  );
  return new;
end;
$$;
revoke execute on function notify_lead_assigned() from public, anon;

drop trigger if exists trg_notify_lead_assigned on main_6_buyer_crm;
create trigger trg_notify_lead_assigned
after insert or update of sale_id on main_6_buyer_crm
for each row
when (new.sale_id is not null)
execute function notify_lead_assigned();

create table probation_rank (
  id          text primary key,
  name        text not null,
  sort_order  int  not null default 0,
  created_at  timestamptz not null default now()
);

create table rank_criterion (
  id            text primary key,
  rank_id       text not null references probation_rank (id) on delete cascade,
  -- vocabulary ชุดเดียวกับ ประเภทกิจกรรม / KPI — อย่าทำลิสต์แยก
  activity_type text not null references action_type (name) on update cascade,
  target        int  not null check (target > 0),
  -- `window` เป็นคำสงวนของ SQL จึงต้องเติมคำนำหน้า
  count_window  text not null check (count_window in ('total','monthly')),
  sort_order    int  not null default 0
);
create index ix_rank_criterion_rank on rank_criterion (rank_id);

insert into probation_rank(id, name, sort_order) values
  ('r_rookie','Rookie',1), ('r_junior','Junior',2), ('r_pro','Senior',3);
insert into rank_criterion(id, rank_id, activity_type, target, count_window, sort_order) values
  ('c_r1_call','r_rookie','Call',20,'total',1),
  ('c_r1_survey','r_rookie','Survey',5,'total',2),
  ('c_r2_call','r_junior','Call',30,'monthly',1),
  ('c_r2_show','r_junior','Show',5,'total',2),
  ('c_r2_owner','r_junior','Owner Visit',4,'total',3),
  ('c_r3_show','r_pro','Show',10,'total',1),
  ('c_r3_win','r_pro','Win',1,'total',2);

create table notifications (
  id            bigint generated always as identity primary key,
  employee_code text not null references main_1_hr (employee_code) on update cascade on delete cascade,
  type          text not null check (type in (
                  'lead_assigned','lead_stage_changed','deal_won','task_due',
                  'target_milestone','listing_new_in_zone','listing_price_changed')),
  title         text not null,
  body          text,
  entity        text check (entity is null or entity in ('lead','listing','task','target')),
  entity_id     text,
  actor         text,          -- ชื่อเล่นคนที่ทำให้เกิด (ว่าง = ระบบสร้างเอง)
  created_at    timestamptz default now(),
  read_at       timestamptz    -- null = ยังไม่อ่าน
);
create index idx_notifications_emp on notifications (employee_code, created_at desc);

-- ---- audit ----
create table audit_log (
  id          bigint generated always as identity primary key,
  entity      text not null,      -- 'lead' | 'listing' | 'employee' | ...
  entity_id   text not null,
  action      text not null,      -- 'assign' | 'update' | 'delete' | ...
  changed_by  text references main_1_hr (employee_code) on update cascade on delete set null,
  before jsonb, after jsonb, remark text,
  created_at  timestamptz default now()
);
create index idx_audit_entity on audit_log (entity, entity_id, created_at desc);


-- ============================================================
-- 10) VIEW: v_main_listing (Owner phone/line + Zone name + Days on Market)
-- security_invoker = true -> view เคารพสิทธิ์/RLS ของคนที่เรียก (ไม่ใช่ของ superuser)
-- ============================================================
create or replace view v_main_listing
with (security_invoker = true) as
select
  l.*,
  p.project_name_thai as listing_name,       -- ดึงจากโครงการ (แทน text เดิม)
  p.project_name_eng  as project_name_eng,   -- ดึงจากโครงการ
  z.name_thai as zone_name_thai,
  z.name_eng  as zone_name_eng,
  o.owner_name, o.owner_phone, o.owner_line,
  -- เซลที่รับผิดชอบจริง: ของทรัพย์ก่อน ถ้าไม่มีค่อยใช้เจ้าภาพโซน
  coalesce(l.sale_id, zone_primary_sale(l.zone)) as effective_sale_id,
  case when l.livinginsider_date is not null
       then (current_date - l.livinginsider_date) end as days_on_market
from main_4_listing_database l
left join main_3_property_detail p on p.project_id = l.project_id
left join main_2_owner o on o.owner_id = l.owner_id
left join zone       z on z.zone_id  = l.zone;


-- ============================================================
-- 10.1) VIEW: v_support_listing  (คิว Support — เฉพาะ listing ที่รอจัดการ)
-- โชว์เฉพาะ listing_status ∈ (Ready to Post / Cancel / Update / Sold)
-- พอ Support จัดการเสร็จ (เปลี่ยนสถานะเป็นอย่างอื่น เช่น Posted/Cancel Completed/Sold Completed)
-- แถวนั้นก็หลุดออกจาก view อัตโนมัติ
-- ============================================================
create or replace view v_support_listing
with (security_invoker = true) as
select *
from v_main_listing
where listing_status in ('Ready to Post', 'Cancel', 'Update', 'Sold');


-- ============================================================
-- 11) VIEW: v_sale_status  (แดชบอร์ดสรุปผลงานเซลรายคน)
-- นับ/รวมยอดของเซลแต่ละคนจากทุกตารางที่เกี่ยวข้อง
-- listing นับจาก "ทรัพย์ที่ตัวเองดูแล" (main_4.sale_id)
-- ถ้าทรัพย์ยังไม่ระบุเซล จะ fallback ไปเจ้าภาพโซน ยอดจึงไม่หายระหว่างรอ import
-- ============================================================
create or replace view v_sale_status
with (security_invoker = true) as
select
  h.employee_code,
  h.nickname,
  h.first_name_en,
  h.last_name_en,
  h.status                              as employee_status,
  (select string_agg(zs.zone_id, ', ' order by zs.zone_id)
     from zone_sales zs where zs.employee_code = h.employee_code)     as zones,

  -- ลีดที่ได้รับมอบหมาย (main_5_lead_database)
  (select count(*) from main_5_lead_database ld
     where ld.sales_id = h.employee_code)                              as total_leads,

  -- ดีลใน CRM (main_6_buyer_crm)
  (select count(*) from main_6_buyer_crm b
     where b.sale_id = h.employee_code)                               as total_crm,
  (select count(*) from main_6_buyer_crm b
     where b.sale_id = h.employee_code and b.lead_status = 'Win')     as crm_win,
  (select count(*) from main_6_buyer_crm b
     where b.sale_id = h.employee_code and b.complete)                as crm_complete,
  (select coalesce(sum(b.commission),0) from main_6_buyer_crm b
     where b.sale_id = h.employee_code)                               as total_commission,

  -- ทรัพย์ที่ตัวเองดูแล (main_4.sale_id — fallback เจ้าภาพโซนถ้ายังไม่ระบุ)
  (select count(*) from main_4_listing_database l
     where coalesce(l.sale_id, zone_primary_sale(l.zone)) = h.employee_code) as total_listings,

  -- ดีลที่ปิดได้ (main_7_last_match)
  (select count(*) from main_7_last_match m
     where m.sale_id = h.employee_code)                               as total_matches,
  (select coalesce(sum(m.last_match_price),0) from main_7_last_match m
     where m.sale_id = h.employee_code)                               as total_match_value,

  -- ==== Listing Potential : นับ listing ของเซลแยกตาม Potential ====
  (select count(*) from main_4_listing_database l
     where coalesce(l.sale_id, zone_primary_sale(l.zone))=h.employee_code and l.potential='Normal')          as lst_normal,
  (select count(*) from main_4_listing_database l
     where coalesce(l.sale_id, zone_primary_sale(l.zone))=h.employee_code and l.potential='A List')          as lst_a_list,
  (select count(*) from main_4_listing_database l
     where coalesce(l.sale_id, zone_primary_sale(l.zone))=h.employee_code and l.potential='A List + Fb add') as lst_a_list_fb,
  (select count(*) from main_4_listing_database l
     where coalesce(l.sale_id, zone_primary_sale(l.zone))=h.employee_code and l.potential='Exclusive')       as lst_exclusive,
  (select count(*) from main_4_listing_database l
     where coalesce(l.sale_id, zone_primary_sale(l.zone))=h.employee_code and l.potential='Exclusive A')     as lst_exclusive_a,

  -- ==== CRM Potential : นับลีดใน CRM ของเซลแยกตาม Potential ====
  (select count(*) from main_6_buyer_crm b where b.sale_id=h.employee_code and b.potential='A')        as crm_a,
  (select count(*) from main_6_buyer_crm b where b.sale_id=h.employee_code and b.potential='B')        as crm_b,
  (select count(*) from main_6_buyer_crm b where b.sale_id=h.employee_code and b.potential='C')        as crm_c,
  (select count(*) from main_6_buyer_crm b where b.sale_id=h.employee_code and b.potential='New Lead') as crm_new_lead,
  (select count(*) from main_6_buyer_crm b where b.sale_id=h.employee_code and b.potential='Agent')    as crm_agent,

  -- ==== ลูกค้าที่เข้ามาผ่าน Listing : นับลีดตาม Potential ของ listing ที่เขาเข้ามา ====
  -- (main_5_lead_database.listing_code -> main_4_listing_database.listing_id -> potential)
  (select count(*) from main_5_lead_database ld join main_4_listing_database l on l.listing_id=ld.listing_code
     where ld.sales_id=h.employee_code and l.potential='Normal')          as leadvia_normal,
  (select count(*) from main_5_lead_database ld join main_4_listing_database l on l.listing_id=ld.listing_code
     where ld.sales_id=h.employee_code and l.potential='A List')          as leadvia_a_list,
  (select count(*) from main_5_lead_database ld join main_4_listing_database l on l.listing_id=ld.listing_code
     where ld.sales_id=h.employee_code and l.potential='A List + Fb add') as leadvia_a_list_fb,
  (select count(*) from main_5_lead_database ld join main_4_listing_database l on l.listing_id=ld.listing_code
     where ld.sales_id=h.employee_code and l.potential='Exclusive')       as leadvia_exclusive,
  (select count(*) from main_5_lead_database ld join main_4_listing_database l on l.listing_id=ld.listing_code
     where ld.sales_id=h.employee_code and l.potential='Exclusive A')     as leadvia_exclusive_a
from main_1_hr h;


-- ============================================================
-- 11.1) FUNCTION: fn_sale_status(วันเริ่ม, วันจบ)  — สรุปผลงานตามช่วงวันที่กำหนดเอง
-- ใช้: select * from fn_sale_status('2026-07-01','2026-07-31');
-- ============================================================
create or replace function fn_sale_status(p_start date, p_end date)
returns table (
  employee_code    text,
  nickname         text,
  leads            bigint,   -- ลีดที่ได้รับ (date_received อยู่ในช่วง)
  crm              bigint,   -- ดีล CRM ที่เข้ามา (date_received)
  crm_win          bigint,   -- ปิด Win (closing_date)
  commission       numeric,  -- คอมมิชชั่นที่ปิดได้ (closing_date)
  matches          bigint,   -- ดีลที่ปิด (date_created)
  match_value      numeric   -- มูลค่าดีลที่ปิด (date_created)
)
language sql stable
as $$
  select
    h.employee_code,
    h.nickname,
    (select count(*) from main_5_lead_database ld
       where ld.sales_id=h.employee_code and ld.date_received between p_start and p_end),
    (select count(*) from main_6_buyer_crm b
       where b.sale_id=h.employee_code and b.date_received between p_start and p_end),
    (select count(*) from main_6_buyer_crm b
       where b.sale_id=h.employee_code and b.lead_status='Win'
         and b.closing_date between p_start and p_end),
    (select coalesce(sum(b.commission),0) from main_6_buyer_crm b
       where b.sale_id=h.employee_code and b.closing_date between p_start and p_end),
    (select count(*) from main_7_last_match m
       where m.sale_id=h.employee_code and m.date_created between p_start and p_end),
    (select coalesce(sum(m.last_match_price),0) from main_7_last_match m
       where m.sale_id=h.employee_code and m.date_created between p_start and p_end)
  from main_1_hr h;
$$;


-- ============================================================
-- 11.2) VIEW: v_sale_zones  (เซลแต่ละคนดูแลโซนไหนบ้าง — derive จากตาราง zone)
-- แทนคอลัมน์ main_1_hr.zone_sales เดิม (ที่ลบไปแล้ว)
-- ============================================================
create or replace view v_sale_zones
with (security_invoker = true) as
select
  h.employee_code,
  h.nickname,
  count(zs.zone_id)                                  as zone_count,
  string_agg(zs.zone_id,  ', ' order by zs.zone_id)  as zone_ids,    -- เช่น "RM2, RM5, PKS"
  string_agg(z.name_thai, ', ' order by zs.zone_id)  as zone_names,  -- เช่น "พระราม 2, พระราม 5, เพชรเกษม"
  -- โซนที่เป็น "เจ้าภาพ" (ลีดที่ไม่ระบุทรัพย์จะวิ่งมาหาคนนี้)
  string_agg(zs.zone_id, ', ' order by zs.zone_id) filter (where zs.is_primary) as primary_zone_ids
from main_1_hr h
left join zone_sales zs on zs.employee_code = h.employee_code
left join zone       z  on z.zone_id = zs.zone_id
group by h.employee_code, h.nickname;


-- ============================================================
-- ⚠️ RLS ไม่ได้อยู่ในไฟล์นี้ — อ่านก่อนรันซ้ำ
-- ============================================================
-- DB จริงตอนนี้ "เปิด RLS + มี policy demo_read_all (ให้ anon อ่านทุกแถว)" ทุกตาราง
-- แต่คำสั่งพวกนั้น "ไม่ได้อยู่ในไฟล์นี้" (ถูกรันแยกไว้)
--
-- แปลว่าถ้ารันไฟล์นี้ซ้ำบน project เปล่า จะได้ตารางที่ RLS ปิด = anon เขียนได้ด้วย
-- (แย่กว่า demo_read_all ที่อ่านได้อย่างเดียว) ต้องรันคำสั่งนี้ตามหลังทุกครั้ง:
--
--   do $$ declare t record; begin
--     for t in select tablename from pg_tables where schemaname='public' loop
--       execute format('alter table %I enable row level security', t.tablename);
--       execute format('drop policy if exists demo_read_all on %I', t.tablename);
--       execute format('create policy demo_read_all on %I for select to anon, authenticated using (true)', t.tablename);
--     end loop; end $$;
--
-- demo_read_all เป็นของชั่วคราวสำหรับเดโม — ตกลงกันว่า "ปิดพร้อมตอน auth เสร็จ" (Ben, 2026-08-03)
-- ⛔ ห้าม import ข้อมูล HR จริงก่อนปิด (เงินเดือน/เลขบัตร ปชช./เลขบัญชี จะเปิดสาธารณะ)

-- ============================================================
-- เสร็จแล้ว — 54 ตาราง + 4 view + 5 function, FK เชื่อมครบ
-- ตาราง main ใส่เลขนำหน้าแล้ว: main_1_hr ... main_11_potential_listing_log (เรียงกลุ่มใน Supabase)
-- auto ID: employee_code / listing_id / lead_id / project_id / last_match_id
-- Support: v_support_listing (view คิวงาน) + main_9_support_log + main_10_potential_listing (auto+กรอกเอง)
-- Auth/RBAC: main_1_hr.auth_user_id + permissions/roles/role_permissions/user_roles/teams
--   function ที่ RLS จะใช้: current_employee_code() · my_permissions() · has_perm(text) ·
--   visible_employee_codes()   (+ fn_sale_status(start,end) สำหรับรายงาน)
-- Import ตัวอย่าง: main_6_buyer_crm <- samples/buyer_crm_sample.csv ,
--                  main_5_lead_database <- samples/lead_database_sample.csv
-- ============================================================
