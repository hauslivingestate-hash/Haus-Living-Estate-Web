# CLAUDE.md — Haus Living Estate Database

> ไฟล์นี้สรุปงานทั้งหมดของโปรเจกต์ **อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง**
> ผู้ใช้สื่อสารเป็นภาษาไทย — ตอบเป็นไทย, โค้ด/ชื่อคอลัมน์เป็นอังกฤษ

## ภาพรวมโปรเจกต์
ออกแบบฐานข้อมูล **Supabase (Postgres)** สำหรับธุรกิจอสังหาฯ "Haus Living Estate"
งานทั้งหมดเป็น **ไฟล์ SQL + CSV** เอาไปรัน/import ใน Supabase เอง (ไม่มีแอป/โค้ดแอปในโปรเจกต์นี้)

## ไฟล์ในโปรเจกต์
| ไฟล์ | หน้าที่ |
|---|---|
| `supabase_full_setup.sql` | **ไฟล์หลักไฟล์เดียว** — รันทีเดียวได้ครบทั้งระบบ (36 ตาราง + 3 view + 1 function) |
| `buyer_crm_sample.csv` | ข้อมูลตัวอย่าง import เข้า `main_6_buyer_crm` |
| `lead_database_sample.csv` | ข้อมูลตัวอย่าง import เข้า `main_5_lead_database` |

### วิธีรัน
1. Supabase → SQL Editor → วาง `supabase_full_setup.sql` ทั้งไฟล์ → Run (ไฟล์มี `drop ... cascade` ต้นไฟล์ รันซ้ำได้ แต่ลบข้อมูลเดิม)
2. (ถ้าต้องการ) Table Editor → Import CSV เข้าตารางที่ตรงกัน

## โครงสร้าง (ในไฟล์ supabase_full_setup.sql)
**ตารางหลัก (main_N_* — ใส่เลขนำหน้าให้เรียงกลุ่มใน Supabase):**
- `main_1_hr` — พนักงาน
- `main_2_owner` — เจ้าของทรัพย์ (1 คน → หลาย listing)
- `main_3_property_detail` — ข้อมูลโครงการ
- `main_4_listing_database` — ประกาศทรัพย์
- `main_5_lead_database` — ลีดต้นทาง (รับจากฟอร์ม n8n)
- `main_6_buyer_crm` — CRM pipeline ฝั่งผู้ซื้อ
- `main_7_last_match` — ดีลที่ปิดได้ (standalone)
- `main_8_listing_photo` — รูปของ listing (หลายรูป/listing)
- `main_9_support_log` — log การทำงานของ Support. **auto-log** ผ่าน trigger `log_listing_status_change` เมื่อสร้าง listing (action='created') หรือ listing_status เปลี่ยน (action='status change', status_before/after). **support_id (ใครทำ) = null ไว้ก่อน** เพราะ DB รู้แค่ auth.uid() ยังไม่มี mapping → employee_code (รอทำตอน RLS)
- `main_10_potential_listing` — listing potential สูง (A List/Exclusive...) แบบ hybrid: auto ดึงเข้า+อัปเดต+ลบออก (trigger) เมื่อ potential เข้า/หลุดเกณฑ์ + Support กรอกเอง (template_link/marketplace/profile/group_date/group_boost_date). คอลัมน์ auto: date_a_list, project_name_thai, unit_condition, price, sale_id, ddproperty/livinginsider/propertyhub_link
- `main_11_potential_listing_log` — log ประวัติเข้า/ออกเกณฑ์ A List (action = added/removed) เก็บไว้แม้ลบออกจาก main_10 แล้ว (ไม่ทำ FK)

**Lookup tables (dropdown):** ทุกตัวใช้ `name` เป็น PK (เก็บ/โชว์เป็น "ชื่อ" ไม่ใช่เลข)
gender, nationality, potential, lead_status, pipeline_stage, bank_loan, lead_type,
complain_status, marketing_channel, contact_by, employee_status, job_position,
second_position, listing_status, listing_potential, listing_type, property_type (มี code),
in_out_project, zone (มี zone_id/ตัวย่อ + name), direction, view_type, unit_position,
price_remark, unit_condition, close_type

**View + Function:**
- `v_main_listing` — listing + ชื่อโซน + owner phone/line + Days on Market (คำนวณ)
- `v_support_listing` — คิวงาน Support: กรอง `v_main_listing` เฉพาะ `listing_status ∈ (Ready to Post/Cancel/Update/Sold)` → พอ Support เปลี่ยนสถานะเป็นอย่างอื่น แถวหลุดออกเอง
- `v_sale_status` — แดชบอร์ดผลงานเซลรายคน (all-time) + breakdown ตาม Potential (คอลัมน์ `zones` derive จากตาราง zone)
- `v_sale_zones` — เซลแต่ละคนดูแลโซนไหนบ้าง (zone_count, zone_ids, zone_names) derive จาก `zone.sale_id_assigned`
- `fn_sale_status(start,end)` — สรุปผลงานเซลตามช่วงวันที่กำหนดเอง

## Convention / การตัดสินใจที่ตกลงกันไว้ (สำคัญ — ทำต่อให้เหมือนเดิม)
- **Lookup = name เป็น PK** เสมอ (ให้ dropdown โชว์ชื่อ ไม่ใช่ตัวเลข) + FK ใช้ `on update cascade`
- **ตาราง main ใส่เลขนำหน้า** `main_1_..main_10_` (เรียงกลุ่มใน Supabase Table Editor) — รูปแบบ `main_N_ชื่อ` ยังเป็น identifier ปกติ ไม่ต้อง quote ตอนพิมพ์ query. **ตาราง lookup ไม่ใส่เลข.** เพิ่ม main ใหม่ให้รันเลขต่อ
- **รวมทุกอย่างเป็นไฟล์เดียว** `supabase_full_setup.sql` (ผู้ใช้ชอบไฟล์เดียวรันจบ)
- ต้นไฟล์มี `drop table if exists ... cascade` ทั้งหมด (setup ครั้งแรก) + รองรับชื่อเก่า
- **วันที่**: เก็บเป็น `date` (YYYY-MM-DD) — ไปแปลงเป็น DD/MM/YYYY ที่หน้าเว็บ (ไม่เก็บเป็น text)
- **View ต้องใส่ `with (security_invoker = true)`** เสมอ (กัน warning + เคารพ RLS)
- ผู้ใช้ชอบให้ **ถามก่อนถ้าไม่ชัวร์** และชอบสรุปเป็นตาราง + ลบไฟล์ที่ไม่ใช้ทิ้ง

## Auto-ID (trigger รันให้เอง ไม่ต้องกรอก)
| ตาราง | คอลัมน์ | รูปแบบ | logic |
|---|---|---|---|
| main_1_hr | employee_code | `S-001` | Sales→S, Support→SP, ไม่งั้นตาม position (CEO→C, CTO→CT, CFO→CF, Listing Support→LS, Marketing→MK), เลขรันแยกตาม prefix |
| main_4_listing_database | listing_id | `HRM5001` | โค้ด property_type (H/C/T/L/A/E/O/G) + zone_id(ตัวย่อ) + เลขรัน 3 หลัก (ไม่มีขีด) |
| main_5_lead_database | lead_id | `L26-001` | L + ปี 2 หลัก + เลขรัน (รีเซ็ตรายปี) |
| main_3_property_detail | project_id | `PROJECT-001` | เลขรันตรงๆ |
| main_7_last_match | last_match_id | `S-001-001` | sale_id + เลขรัน (แยกตาม sale) — ต้องใส่ sale_id ก่อน |

## FK ที่เชื่อมแล้ว
- ทุก sale (sale_id/sales_id/sale_id_assigned) → `main_1_hr.employee_code` (เป็น text)
- `main_6_buyer_crm.lead_ref` → main_5_lead_database.lead_id (buyer_crm 1 แถว = 1 ลีด)
- `main_4_listing_database.project_id` → main_3_property_detail.project_id
- `main_5_lead_database.listing_code` → main_4_listing_database.listing_id
- `main_9_support_log.listing_id` → main_4_listing_database , `.support_id` → main_1_hr , `.status_before/after` → listing_status
- `main_10_potential_listing` → main_4_listing_database (auto sync ผ่าน trigger `sync_potential_listing`: insert/update/delete + เขียน log) , `.sale_id` → main_1_hr , `.unit_condition` → unit_condition , `.potential` → listing_potential
- `main_11_potential_listing_log` — ไม่ทำ FK (เก็บประวัติแม้ listing ถูกลบ)
- gender/nationality เป็น lookup ใช้ร่วมหลายตาราง

## งานที่ยังค้าง (TODO)
- [ ] **RLS** — แยกข้อมูล `main_4_listing_database` ตาม `created_by` (auth.uid()) → **ผู้ใช้ขอแปะไว้ก่อน** ยังไม่ทำ ต้องคุยเรื่องสิทธิ์ (ใครเห็นของใคร)
- [ ] `main_5_lead_database.line_userid` — ตั้งใจให้ดึงจาก `main_1_hr.line_userid` ผ่าน sales_id (ยังไม่ทำ FK ตรง — เป็นค่า derived)
- [x] **Zone assignment**: เซล 1 คนดูแลหลายโซนได้ (1 โซน = 1 เซล) รองรับด้วย `zone.sale_id_assigned`. **ลบ `main_1_hr.zone_sales` ทิ้งแล้ว** → ใช้ view `v_sale_zones` แทน (v_sale_status ก็เปลี่ยนมาใช้คอลัมน์ `zones` derive แล้ว)
- [x] `main_4` **ลบคอลัมน์ text** `listing_name`/`project_name_eng` แล้ว → ดึงจากโครงการผ่าน `v_main_listing` (listing_name = property_detail.project_name_thai, project_name_eng = project_name_eng)
- [x] `main_10_potential_listing`: ทำ auto insert/update/**ลบออก**เมื่อหลุดเกณฑ์ + เก็บ log (main_11) แล้ว + คอลัมน์ตามสเปคแล้ว
- [ ] เปลี่ยน `facebook_link` → `propertyhub_link` แล้วใน main_4 + main_10 (ถ้ามี sample/แอปที่อ้าง facebook_link ต้องอัปเดตด้วย)
- [x] `main_10.price` auto = `asking_price` / `sale_id` auto = เซลที่ดูแลโซนของ listing (`zone.sale_id_assigned`)

## หมายเหตุ/ข้อควรระวัง
- **Listing ID ไม่มีตัวคั่น** → ตัวย่อ Zone ห้ามเป็น "คำนำหน้า" ของอีกโซน (ปัจจุบัน 23 โซนเช็กแล้วปลอดภัย)
- มี **potential 2 ชุด** คนละความหมาย: lookup `potential` (CRM: A/B/C/New Lead/Agent) กับ `listing_potential` (Normal/A List/Exclusive...)
- `v_sale_status` กว้าง 23 คอลัมน์ (breakdown เยอะ) — ถ้าจะแยกย่อยค่อยทำ view เพิ่ม
- sample CSV: `sale_id`/`listing_code` ถูกล้างค่าไว้ (กันชน FK เพราะ main_1_hr/listing ยังว่าง)
- **v_support_listing ต่อยอดจาก v_main_listing** → ถ้าแก้คอลัมน์ v_main_listing เช็ก view นี้ด้วย
