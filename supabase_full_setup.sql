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
drop table if exists main_10_potential_listing cascade;
drop table if exists main_9_support_log     cascade;
drop table if exists main_8_listing_photo     cascade;
drop table if exists main_7_last_match        cascade;
drop table if exists main_6_buyer_crm         cascade;
drop table if exists main_5_lead_database     cascade;
drop table if exists main_4_listing_database  cascade;
drop table if exists main_3_property_detail        cascade;
drop table if exists main_2_owner             cascade;
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

create table zone (
  seq              bigint generated always as identity,   -- เลขรันข้างหน้า
  zone_id          text primary key,                      -- Zone ID (ตัวย่อ) ใช้ประกอบ Listing ID
  name_eng         text,
  name_thai        text,
  sale_id_assigned text,                                  -- Sale_id_Assigned -> main_1_hr (FK เพิ่มท้ายไฟล์)
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


-- ============================================================
-- 2) TABLE: main_1_hr  (+ auto Employee Code)
-- ============================================================
create table main_1_hr (
  employee_code   text primary key,        -- auto-run
  status          text references employee_status (name) on update cascade,
  division        text,
  position        text references job_position (name)    on update cascade,
  second_position text references second_position (name) on update cascade,
  zone_sales      text,                    -- Zone(Sales) << แปะไว้ก่อน
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
  created_at      timestamptz default now()
);

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

-- zone.sale_id_assigned -> main_1_hr (ต้องรอ main_1_hr ก่อน จึงเพิ่มตรงนี้)
alter table zone add constraint fk_zone_sale
  foreign key (sale_id_assigned) references main_1_hr (employee_code) on update cascade;


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
  listing_name       text,                    -- << ดึงจาก main_3_property_detail ได้
  project_id         text references main_3_property_detail (project_id) on update cascade,  -- โยงโครงการ
  listing_status     text references listing_status (name)    on update cascade,
  potential          text references listing_potential (name) on update cascade,  -- Potential (FK)
  sign               boolean default false,
  vdo                boolean default false,
  ddproperty_link    text,
  livinginsider_link text,
  livinginsider_date date,                    -- auto ตอนกรอกลิงก์ครั้งแรก (คิด Days on Market)
  facebook_link      text,
  old_price          numeric,  new_price numeric,  update_remark text,
  owner_focus        boolean default false,
  project_name_eng   text,                    -- << ดึงจาก main_3_property_detail ได้
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
  created_by         uuid default auth.uid(),  -- << RLS (แยกไฟล์)
  shorts_reels_link text, hometour_link text,
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

create or replace function set_lead_database_id()
returns trigger language plpgsql as $$
declare yy text := to_char(now(),'YY'); next_num int;
begin
  if new.lead_id is null or new.lead_id = '' then
    select coalesce(max((split_part(lead_id,'-',2))::int),0)+1 into next_num
      from main_5_lead_database where lead_id like 'L' || yy || '-%';
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


-- ============================================================
-- 9.2) TABLE: main_10_potential_listing  (แยกเฉพาะ listing potential สูง)
-- Hybrid: auto ดึงเข้ามาเมื่อ potential ∈ (A List / A List + Fb add / Exclusive / Exclusive A)
--         + มีคอลัมน์ให้ Support กรอกเอง (headline/support_note/remark) — ไว้ทำหัวข้อแยกทีหลัง
-- หมายเหตุ: ตอนนี้ "ไม่ลบออกอัตโนมัติ" ถ้า potential เปลี่ยนออกจากเกณฑ์ (กันข้อมูลที่กรอกเองหาย)
-- ============================================================
create table main_10_potential_listing (
  listing_id   text primary key references main_4_listing_database (listing_id) on delete cascade,
  potential    text references listing_potential (name) on update cascade,  -- auto-sync จาก listing
  -- ===== ส่วนที่ Support กรอกเอง (จะมีหัวข้อแยกเพิ่มภายหลัง) =====
  headline     text,
  support_note text,
  remark       text,
  updated_at   timestamptz default now(),
  created_at   timestamptz default now()
);

-- trigger: เมื่อ listing มี potential เข้าเกณฑ์ -> upsert เข้า main_10_potential_listing
create or replace function sync_potential_listing()
returns trigger language plpgsql as $$
begin
  if new.potential in ('A List','A List + Fb add','Exclusive','Exclusive A') then
    insert into main_10_potential_listing (listing_id, potential)
      values (new.listing_id, new.potential)
    on conflict (listing_id)
      do update set potential = excluded.potential, updated_at = now();
  end if;
  return new;
end; $$;
drop trigger if exists trg_sync_potential_listing on main_4_listing_database;
create trigger trg_sync_potential_listing
  after insert or update of potential on main_4_listing_database
  for each row execute function sync_potential_listing();


-- ============================================================
-- 10) VIEW: v_main_listing (Owner phone/line + Zone name + Days on Market)
-- security_invoker = true -> view เคารพสิทธิ์/RLS ของคนที่เรียก (ไม่ใช่ของ superuser)
-- ============================================================
create or replace view v_main_listing
with (security_invoker = true) as
select
  l.*,
  z.name_thai as zone_name_thai,
  z.name_eng  as zone_name_eng,
  o.owner_name, o.owner_phone, o.owner_line,
  case when l.livinginsider_date is not null
       then (current_date - l.livinginsider_date) end as days_on_market
from main_4_listing_database l
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
-- listing นับจากโซนที่เซลรับผิดชอบ (zone.sale_id_assigned)
-- ============================================================
create or replace view v_sale_status
with (security_invoker = true) as
select
  h.employee_code,
  h.nickname,
  h.first_name_en,
  h.last_name_en,
  h.status                              as employee_status,
  h.zone_sales,

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

  -- listing ในโซนที่รับผิดชอบ (main_4_listing_database + zone)
  (select count(*) from main_4_listing_database l
     join zone z on z.zone_id = l.zone
     where z.sale_id_assigned = h.employee_code)                      as total_listings,

  -- ดีลที่ปิดได้ (main_7_last_match)
  (select count(*) from main_7_last_match m
     where m.sale_id = h.employee_code)                               as total_matches,
  (select coalesce(sum(m.last_match_price),0) from main_7_last_match m
     where m.sale_id = h.employee_code)                               as total_match_value,

  -- ==== Listing Potential : นับ listing ของเซลแยกตาม Potential ====
  (select count(*) from main_4_listing_database l join zone z on z.zone_id=l.zone
     where z.sale_id_assigned=h.employee_code and l.potential='Normal')          as lst_normal,
  (select count(*) from main_4_listing_database l join zone z on z.zone_id=l.zone
     where z.sale_id_assigned=h.employee_code and l.potential='A List')          as lst_a_list,
  (select count(*) from main_4_listing_database l join zone z on z.zone_id=l.zone
     where z.sale_id_assigned=h.employee_code and l.potential='A List + Fb add') as lst_a_list_fb,
  (select count(*) from main_4_listing_database l join zone z on z.zone_id=l.zone
     where z.sale_id_assigned=h.employee_code and l.potential='Exclusive')       as lst_exclusive,
  (select count(*) from main_4_listing_database l join zone z on z.zone_id=l.zone
     where z.sale_id_assigned=h.employee_code and l.potential='Exclusive A')     as lst_exclusive_a,

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
-- เสร็จแล้ว — 35 ตาราง + 3 view + 1 function (fn_sale_status), FK เชื่อมครบ
-- ตาราง main ใส่เลขนำหน้าแล้ว: main_1_hr ... main_10_potential_listing (เรียงกลุ่มใน Supabase)
-- auto ID: employee_code / listing_id / lead_id / project_id / last_match_id
-- Support: v_support_listing (view คิวงาน) + main_9_support_log + main_10_potential_listing (auto+กรอกเอง)
-- ยังค้าง: RLS (แยกข้อมูล listing ตาม created_by) — ทำแยกไฟล์
-- Import ตัวอย่าง: main_6_buyer_crm <- buyer_crm_sample.csv ,
--                  main_5_lead_database <- lead_database_sample.csv
-- ============================================================
