# CLAUDE.md — Haus Living Estate Database

> ไฟล์นี้สรุปงานทั้งหมดของโปรเจกต์ **อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง**
> ผู้ใช้สื่อสารเป็นภาษาไทย — ตอบเป็นไทย, โค้ด/ชื่อคอลัมน์เป็นอังกฤษ

## ภาพรวมโปรเจกต์
ออกแบบฐานข้อมูล **Supabase (Postgres)** สำหรับธุรกิจอสังหาฯ "Haus Living Estate"
งานทั้งหมดเป็น **ไฟล์ SQL + CSV** เอาไปรัน/import ใน Supabase เอง (ไม่มีแอป/โค้ดแอปในโปรเจกต์นี้)

## ไฟล์ในโปรเจกต์
| ไฟล์ | หน้าที่ |
|---|---|
| `supabase_full_setup.sql` | **ไฟล์หลักไฟล์เดียว** — รันทีเดียวได้ครบทั้งระบบ (27 ตาราง + 2 view + 1 function) |
| `buyer_crm_sample.csv` | ข้อมูลตัวอย่าง import เข้า `main_buyer_crm` |
| `lead_database_sample.csv` | ข้อมูลตัวอย่าง import เข้า `main_lead_database` |

### วิธีรัน
1. Supabase → SQL Editor → วาง `supabase_full_setup.sql` ทั้งไฟล์ → Run (ไฟล์มี `drop ... cascade` ต้นไฟล์ รันซ้ำได้ แต่ลบข้อมูลเดิม)
2. (ถ้าต้องการ) Table Editor → Import CSV เข้าตารางที่ตรงกัน

## โครงสร้าง (ในไฟล์ supabase_full_setup.sql)
**ตารางหลัก (main_*):**
- `main_hr` — พนักงาน
- `main_lead_database` — ลีดต้นทาง (รับจากฟอร์ม n8n)
- `main_buyer_crm` — CRM pipeline ฝั่งผู้ซื้อ
- `main_listing_database` — ประกาศทรัพย์
- `main_owner` — เจ้าของทรัพย์ (1 คน → หลาย listing)
- `property_detail` — ข้อมูลโครงการ
- `main_last_match` — ดีลที่ปิดได้ (standalone)
- `main_listing_photo` — รูปของ listing (หลายรูป/listing)

**Lookup tables (dropdown):** ทุกตัวใช้ `name` เป็น PK (เก็บ/โชว์เป็น "ชื่อ" ไม่ใช่เลข)
gender, nationality, potential, lead_status, pipeline_stage, bank_loan, lead_type,
complain_status, marketing_channel, contact_by, employee_status, job_position,
second_position, listing_status, listing_potential, listing_type, property_type (มี code),
in_out_project, zone (มี zone_id/ตัวย่อ + name), direction, view_type, unit_position,
price_remark, unit_condition, close_type

**View + Function:**
- `v_main_listing` — listing + ชื่อโซน + owner phone/line + Days on Market (คำนวณ)
- `v_sale_status` — แดชบอร์ดผลงานเซลรายคน (all-time) + breakdown ตาม Potential
- `fn_sale_status(start,end)` — สรุปผลงานเซลตามช่วงวันที่กำหนดเอง

## Convention / การตัดสินใจที่ตกลงกันไว้ (สำคัญ — ทำต่อให้เหมือนเดิม)
- **Lookup = name เป็น PK** เสมอ (ให้ dropdown โชว์ชื่อ ไม่ใช่ตัวเลข) + FK ใช้ `on update cascade`
- **รวมทุกอย่างเป็นไฟล์เดียว** `supabase_full_setup.sql` (ผู้ใช้ชอบไฟล์เดียวรันจบ)
- ต้นไฟล์มี `drop table if exists ... cascade` ทั้งหมด (setup ครั้งแรก) + รองรับชื่อเก่า
- **วันที่**: เก็บเป็น `date` (YYYY-MM-DD) — ไปแปลงเป็น DD/MM/YYYY ที่หน้าเว็บ (ไม่เก็บเป็น text)
- **View ต้องใส่ `with (security_invoker = true)`** เสมอ (กัน warning + เคารพ RLS)
- ผู้ใช้ชอบให้ **ถามก่อนถ้าไม่ชัวร์** และชอบสรุปเป็นตาราง + ลบไฟล์ที่ไม่ใช้ทิ้ง

## Auto-ID (trigger รันให้เอง ไม่ต้องกรอก)
| ตาราง | คอลัมน์ | รูปแบบ | logic |
|---|---|---|---|
| main_hr | employee_code | `S-001` | Sales→S, Support→SP, ไม่งั้นตาม position (CEO→C, CTO→CT, CFO→CF, Listing Support→LS, Marketing→MK), เลขรันแยกตาม prefix |
| main_listing_database | listing_id | `HRM5001` | โค้ด property_type (H/C/T/L/A/E/O/G) + zone_id(ตัวย่อ) + เลขรัน 3 หลัก (ไม่มีขีด) |
| main_lead_database | lead_id | `L26-001` | L + ปี 2 หลัก + เลขรัน (รีเซ็ตรายปี) |
| property_detail | project_id | `PROJECT-001` | เลขรันตรงๆ |
| main_last_match | last_match_id | `S-001-001` | sale_id + เลขรัน (แยกตาม sale) — ต้องใส่ sale_id ก่อน |

## FK ที่เชื่อมแล้ว
- ทุก sale (sale_id/sales_id/sale_id_assigned) → `main_hr.employee_code` (เป็น text)
- `main_buyer_crm.lead_ref` → main_lead_database.lead_id (buyer_crm 1 แถว = 1 ลีด)
- `main_listing_database.project_id` → property_detail.project_id
- `main_lead_database.listing_code` → main_listing_database.listing_id
- gender/nationality เป็น lookup ใช้ร่วมหลายตาราง

## งานที่ยังค้าง (TODO)
- [ ] **RLS** — แยกข้อมูล `main_listing_database` ตาม `created_by` (auth.uid()) → **ผู้ใช้ขอแปะไว้ก่อน** ยังไม่ทำ ต้องคุยเรื่องสิทธิ์ (ใครเห็นของใคร)
- [ ] `main_lead_database.line_userid` — ตั้งใจให้ดึงจาก `main_hr.line_userid` ผ่าน sales_id (ยังไม่ทำ FK ตรง — เป็นค่า derived)
- [ ] `main_hr.zone_sales` (Zone ของ sales) — ยังแปะเป็น text รอทำตาราง Zone assignment แยก
- [ ] Property_detail: `listing_name`/`project_name_eng` ใน listing ดึงจากโครงการผ่าน project_id ได้แล้ว (ยังเก็บ text คู่ไว้)

## หมายเหตุ/ข้อควรระวัง
- **Listing ID ไม่มีตัวคั่น** → ตัวย่อ Zone ห้ามเป็น "คำนำหน้า" ของอีกโซน (ปัจจุบัน 23 โซนเช็กแล้วปลอดภัย)
- มี **potential 2 ชุด** คนละความหมาย: lookup `potential` (CRM: A/B/C/New Lead/Agent) กับ `listing_potential` (Normal/A List/Exclusive...)
- `v_sale_status` กว้าง 23 คอลัมน์ (breakdown เยอะ) — ถ้าจะแยกย่อยค่อยทำ view เพิ่ม
- sample CSV: `sale_id`/`listing_code` ถูกล้างค่าไว้ (กันชน FK เพราะ main_hr/listing ยังว่าง)
