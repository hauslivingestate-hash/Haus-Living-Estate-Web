# CLAUDE.md — Haus Living Estate Database

> ไฟล์นี้สรุปงานทั้งหมดของโปรเจกต์ **อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง**
> ผู้ใช้สื่อสารเป็นภาษาไทย — ตอบเป็นไทย, โค้ด/ชื่อคอลัมน์เป็นอังกฤษ

## ภาพรวมโปรเจกต์
ฐานข้อมูล **Supabase (Postgres)** + เว็บแอป CRM (Next.js) สำหรับธุรกิจอสังหาฯ "Haus Living Estate"
ฝั่ง DB เป็น **ไฟล์ SQL + CSV** เอาไปรัน/import ใน Supabase เอง
เว็บแอปอยู่ใน `haus-crm/` — **เป็น git repo แยกต่างหาก + ถูก gitignore ใน repo แม่** (ดูหัวข้อ "เว็บแอป CRM" ท้ายไฟล์)

## โครงสร้างโฟลเดอร์ (จัดใหม่ 2026-08-03)
```
Haus-Web-Wp.Ben/
├── CLAUDE.md              ไฟล์นี้ — อ่านก่อนเริ่มงานทุกครั้ง
├── db/
│   ├── supabase_full_setup.sql   ไฟล์หลัก รันทีเดียวครบ (36 ตาราง + 4 view + 1 function)
│   └── samples/                  CSV ตัวอย่าง (buyer_crm, lead_database)
├── docs/                  เอกสาร/PDF (gitignore *.pdf)
├── import/                ⬅ วาง CSV ที่ export จาก Google Sheets ไว้ที่นี่ (ยังว่าง)
├── memory/                โน้ตความจำของโปรเจกต์
└── haus-crm/              เว็บแอป (git repo แยก + gitignore ใน repo แม่)
```

### วิธีรัน SQL
1. Supabase → SQL Editor → วาง `db/supabase_full_setup.sql` ทั้งไฟล์ → Run (ไฟล์มี `drop ... cascade` ต้นไฟล์ รันซ้ำได้ แต่ลบข้อมูลเดิม)
2. (ถ้าต้องการ) Table Editor → Import CSV จาก `db/samples/` เข้าตารางที่ตรงกัน

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

### 🔴 ที่เจอตอนรับช่วงต่อ (เช็ค DB จริงแล้ว 2026-08-03)
- [x] **สะพาน `auth.uid()` → `employee_code`** — ทำแล้ว 2026-08-03: `main_1_hr.auth_user_id` (uuid unique → auth.users) + function `current_employee_code()` (security definer). ยังไม่มีผลจนกว่าจะมีบัญชี login. ยังขาด helper อีก 2 ตัวที่ต้องทำตอนทำ RLS: `has_perm()`, `visible_employee_codes()` (own/team/all)
- [x] **RBAC ย้ายเข้า DB แล้ว** 2026-08-03 — `permissions` (35) · `roles` (7) · `role_permissions` · `user_roles` · `teams` + `main_1_hr.team_id`. seed ตรงกับ `SEED_ROLES` ใน [lib/rbac.ts](haus-crm/lib/rbac.ts) เป๊ะ (ceo 35 · agent 13 · listing_support 15 · marketing 7 · sales_leader 17 · admin 8 · hr 7)
- [x] **helper ครบแล้ว**: `current_employee_code()` · `my_permissions()` · `has_perm(text)` · `visible_employee_codes()` (own/team/all) — ทุกตัว `security definer` + grant เฉพาะ `authenticated`
- [x] **ต่อ auth ในแอปแล้ว** — `@supabase/ssr` + [middleware.ts](haus-crm/middleware.ts) (refresh session + กัน route) + [LoginForm](haus-crm/components/LoginForm.tsx) ใช้ `signInWithPassword` จริง + ปุ่มออกจากระบบใน Sidebar + `RbacProvider` รับ session
- [x] **สร้างบัญชี login แล้ว 2026-08-03 — 9 บัญชี** (พนักงาน Active 8 + `E-001` Admin). ทดสอบแล้วทั้งสาย: login → `current_employee_code()` → `my_permissions()` → `visible_employee_codes()` ถูกต้องทุกคน
  - สร้างผ่าน SQL (`auth.users` + `auth.identities`) เพราะไม่มี service_role key ในเครื่อง
  - ⚠️ **กับดัก:** GoTrue อ่าน `confirmation_token`/`recovery_token`/`email_change_token_new`/`email_change` เป็น string ธรรมดา ถ้าเป็น NULL จะ login ไม่ได้ ขึ้น `Database error querying schema` — 4 คอลัมน์นี้**ไม่มี default** ต้องใส่ `''` เอง (ถ้าสร้างบัญชีเพิ่มในอนาคตต้องระวัง)
  - เพิ่ม role **`system_admin`** (ทุกสิทธิ์) แยกจาก `ceo` ตั้งใจ — `ceo` เป็นตำแหน่งจริงของ Stone ถ้าเอาไปให้บัญชีแอดมินด้วย ทุกรายงานจะนับว่ามี CEO 2 คน
  - `E-001` เป็นแถวพนักงานปลอมสำหรับบัญชีแอดมิน (จำเป็น เพราะสิทธิ์ทุกอย่างวิ่งผ่าน `employee_code`) — `second_position` = null จึงไม่โผล่ในรายชื่อเซล
  - Pai (ลาออก) **ไม่มีบัญชี**
- [ ] 🔑 **`NEXT_PUBLIC_AUTH_ENFORCED` ยังปิดอยู่** — พร้อมเปิดแล้ว (บัญชีครบ) แต่พอเปิดคือ **ต้อง login ถึงจะเข้าเว็บได้ทุกคน** รวมเดโมที่ CEO ดู. เปิดที่ Vercel → Environment Variables = `1` แล้ว redeploy
- [ ] 🔴 **ยังไม่มีหน้าเปลี่ยนรหัสผ่านในแอป** — ตอนนี้รหัสตั้งโดยแอดมิน ผู้ใช้เปลี่ยนเองไม่ได้ ต้องทำก่อนใช้จริง (`supabase.auth.updateUser({password})`)
- [ ] **ยังไม่มีหน้าจัดการบัญชีสำหรับ Admin** — ตั้ง/รีเซ็ตรหัสให้คนอื่นต้องมี server route ที่ถือ `service_role` key (ห้าม `NEXT_PUBLIC_`) + gate ด้วย `people.manage`
- [ ] **`lib/queries.ts` ยังใช้ anon client ที่ไม่มี session** ([lib/supabase.ts](haus-crm/lib/supabase.ts)) → ตอนทำ RLS จริงต้องย้ายไป [lib/supabase/server.ts](haus-crm/lib/supabase/server.ts) ไม่งั้นทุกหน้าที่กรองตามสิทธิ์จะว่างเปล่า **และหน้าจะกลายเป็น dynamic** (ทิ้ง ISR 30 วิ) ซึ่งถูกต้องแล้ว — หน้าที่ cache ไว้ให้คนนึงห้ามเสิร์ฟให้อีกคน
- [ ] **`demo_read_all` = ช่องโหว่** — ทุกตารางมี policy เดียวคือให้ `anon` อ่านได้หมด และ anon key ฝังอยู่ในโค้ดหน้าเว็บ → ใครก็อ่าน `main_1_hr` (เงินเดือน/บัตร ปชช./บัญชีธนาคาร) ได้. **ห้าม import HR จริงก่อนปิดอันนี้**
  - **ตัดสินใจแล้ว (Ben, 2026-08-03): ปิดพร้อมตอน auth เสร็จ ไม่ปิดก่อน** (เพราะเดโมที่ CEO ดูจะพัง และตอนนี้ยังเป็นข้อมูลปลอม) → **ต้องเตือน Ben ทุกครั้งที่เริ่มงาน auth**
- [ ] **ไม่มี policy INSERT/UPDATE/DELETE เลยสักตาราง** → พอต่อ write path จะโดน 403 ทุกจุด ต้องเขียน policy คู่กันไปเสมอ
- [x] **17 คอลัมน์จากชีท Listings** — เพิ่มแล้ว 2026-08-03 (`main_4` 47 → **64 คอลัมน์**, `v_main_listing` 55 → **72**): `dd_boost` `lv_boost` `fb_repost` `marketing_report` `facebook_ad_link` `new_photo_link` `hook` `photo_album_link` `link` `last_match` `last_match_type` `last_match_price` `last_match_remark` `common_fee_rate`+`common_fee_unit`+`common_fee_note` `built_year`
  - **ส่วนกลางเก็บเป็นเรต** (`per_wa_month`/`per_sqm_month`) ไม่ใช่ยอดรวม — ชีทปน 3 หน่วย ต้องแปลงตอน import + เก็บข้อความดิบไว้ใน `common_fee_note`
  - **`built_year` = ปี ค.ศ. ที่สร้าง** ไม่ใช่จำนวนปี — ฟอร์มกรอกทรัพย์ต้องเปลี่ยนคำถามเป็น "สร้างปีไหน"
  - `last_match_type` ยังไม่ทำ FK → `close_type` รอดูค่าจริงในชีทก่อน (กัน import ล้ม)
- [x] **คอลัมน์ intake ของ `main_6_buyer_crm`** — เพิ่มแล้ว 2026-08-03 (26 → **37 คอลัมน์**) + ตารางใหม่ `lead_tags_ref` (seed 4 แท็ก รอ CEO ตั้งจริง): `tag_id` `marketing_channel`+`marketing_channel_other` `contact_by` `gender` `nationality` `contact_date`/`contact_time` `customer_complain`/`complain_status`/`complain_remark`
  - **เลือกเก็บตรง ๆ ไม่ดึงจาก main_5 ผ่าน view** เพราะ `lead_ref` ว่าง 10/10 แถว + main_5 = บันทึกตอนรับลีด (ไม่ควรถูกเซลแก้ทับ)
  - **ไม่มี `recheck_status`** — derive จาก `pipeline_stage` (เลย 'Lead' = ติดต่อแล้ว) เก็บเป็นคอลัมน์จะได้ข้อมูล 2 ชุดที่ขัดกันเอง
  - แอปเรียก `source` = คอลัมน์ `marketing_channel` (ตั้งชื่อให้ตรง main_5 ทั้ง DB)
- [ ] **`zone`**: ตัดสินใจแล้วว่า**ไม่เพิ่ม** `sales_sheet`/`location`/วันที่ จากชีท HR. แต่ชีทมี ~30 โซน DB มี 23 → import แล้วต้องเช็คกฎ "ตัวย่อโซนห้ามเป็นคำนำหน้าของอีกโซน" ใหม่ (เพราะ `zone_id` ประกอบเป็น listing_id)
- [ ] ⚠️ **`db/supabase_full_setup.sql` ไม่มีคำสั่ง RLS/policy** — DB จริงเปิด RLS + `demo_read_all` ไว้ แต่รันจากที่อื่น. รันไฟล์ซ้ำบน project เปล่าจะได้ตาราง **RLS ปิด = anon เขียนได้** (แย่กว่าเดิม) → มีสคริปต์ปิดท้ายไฟล์ให้รันตามแล้ว
- [x] **ตารางที่แอปต้องใช้ — สร้างครบแล้ว 2026-08-03** (รวมทั้ง DB **54 ตาราง**): `action_type` (seed 20 กิจกรรม) · `activities` · `tasks` · `targets` · `user_quick_actions` · `contacts` + `contact_roles` · `leave_type` + `leave_allowances` + `leave_requests` · `notifications` · `audit_log` (+ RBAC/teams/lead_tags_ref ที่ทำก่อนหน้า)
  - `activities.task_id` **unique** → ติ๊กงานซ้ำไม่นับซ้ำ, ยกเลิกติ๊กแล้วแถวหายตาม
  - `leave_requests` มี check `start_date <= end_date` + unique (employee,start,end,type) → กัน error 2 อย่างที่มีอยู่ในชีท
  - `contacts` ไม่เก็บทรัพย์ที่ถือ/ความต้องการ (derive จาก main_4/main_6) — ตอน import ต้อง dedupe กับ `main_2_owner` ด้วยเบอร์โทร
- [ ] **ยังไม่ได้ทำ**: `summary_*` (rollup แดชบอร์ด — ต้องมีข้อมูลจริงก่อน) · checklist ทรัพย์ · เทมเพลตคำโฆษณา · ladder เซลใหม่ (3 อันหลังเป็น feature แยก มีเอกสารของตัวเองใน `haus-crm/*_FEATURE.md`)
- [x] **import HR Sheet แล้ว 2026-08-03** — พนักงานจริง 9 คน (ทับ demo 6 คนที่รหัสซ้ำกัน) · โซน 29 · `zone_sales` 30 แถว · ใบลา 20 · `user_roles` 8 คน
  - **ข้าม Nut** (ไม่มี employee_code = PK ว่างไม่ได้ + ลาออกแล้ว ไม่มีข้อมูลอื่นเลย)
  - `date_started` **ว่างทุกคน** (ชีทไม่มี) → กระทบ ladder เซลใหม่ + โควตาลาปีแรก ต้องกรอกในเว็บทีหลัง
  - commission แปลงเป็นเรตแล้ว: Sales `0.6`/`0.5` · Support `0.006` (ชีทเขียน 0.6% ยืนยันแล้วว่าถูก)
  - birthday ในชีทมี 3 รูปแบบ (`27 มีนาคม 2537` · `11/2/2536` · `20 Aug 1992`) แปลง พ.ศ.→ค.ศ. แล้ว มีแค่ 4 คนที่กรอก
  - **ไม่ใส่ role `sales_leader` ให้ใคร + `teams` ยังว่าง** — ชีท HR ไม่มีข้อมูลว่าใครเป็นหัวหน้าทีม รอ CEO กำหนด (ของเดิมในแอปที่ใส่ Pup/Game เป็นหัวหน้าเป็นการเดาตอนออกแบบ)
  - ⚠️ **ทรัพย์/ลีด demo 10 แถวตอนนี้ชี้ไปที่คนจริงแล้ว** (รหัสซ้ำกันพอดี) — จะถูกทับตอน import ชีททรัพย์

### เดิม
- [ ] **RLS** — แยกข้อมูล `main_4_listing_database` ตาม `created_by` (auth.uid()) → **ผู้ใช้ขอแปะไว้ก่อน** ยังไม่ทำ ต้องคุยเรื่องสิทธิ์ (ใครเห็นของใคร)
- [ ] `main_5_lead_database.line_userid` — ตั้งใจให้ดึงจาก `main_1_hr.line_userid` ผ่าน sales_id (ยังไม่ทำ FK ตรง — เป็นค่า derived)
- [x] **Zone assignment — เปลี่ยนหลักคิดแล้ว 2026-08-03 (Ben)**: **"ทรัพย์" เป็นตัวตัดสินว่าใครดูแล** ไม่ใช่โซน → เพิ่ม `main_4_listing_database.sale_id` (เซลที่ดูแลบ้านหลังนั้น), ลีดวิ่งตามรหัสทรัพย์ที่ลูกค้าสนใจ
  - โซนจึงมีหลายเซลได้แล้ว → ตาราง `zone_sales(zone_id, employee_code, is_primary)` **แทน `zone.sale_id_assigned` ที่ลบทิ้งแล้ว** (ของจริง: พระราม 3 = Pup + Mhow)
  - `is_primary` = เจ้าภาพโซน (โซนละไม่เกิน 1 คน — บังคับด้วย partial unique index) ใช้เป็น**ค่าสำรอง** 2 กรณี: ลีดที่ไม่ระบุทรัพย์ · ทรัพย์ใหม่ที่ยังไม่ระบุเซล → helper `zone_primary_sale(zone_id)`
  - `v_main_listing` เพิ่มคอลัมน์ `effective_sale_id` = `coalesce(sale_id, zone_primary_sale(zone))`
  - `v_sale_status.total_listings` เปลี่ยนจาก "ทรัพย์ในโซนที่ดูแล" → **"ทรัพย์ที่ตัวเองดูแล"** (แม่นกว่า + ไม่นับซ้ำเมื่อโซนมีหลายคน)
  - ⚠️ **ฝั่งแอปยังไม่ได้แก้** — `lib/zones.ts` + `ZonesAdmin` ยังเป็น 1 โซน 1 เซล (ยังเป็น sample in-memory) ต้องแก้ตอน Phase 3
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

## เว็บแอป CRM (haus-crm) + Deploy Vercel
เว็บแอป CRM อยู่ที่โฟลเดอร์ `haus-crm/` — **Next.js 15 (App Router) + React 19 + Tailwind v4 + Supabase JS**

### สถานะ: รับช่วงต่อจากเฟสออกแบบ (2026-08-03)
แอปเวอร์ชันเก่า (5 หน้า) **ถูกทับด้วยเวอร์ชัน design-first เต็ม (23 routes) แล้ว** — ของเก่ายังกู้ได้จาก git tag **`v1-legacy`**

- **เอกสารส่งมอบอยู่ในโฟลเดอร์แอป** อ่านตามลำดับนี้: [DATA_MODEL.md](haus-crm/DATA_MODEL.md) (บล็อก HANDOVER บนสุด) → [HANDOVER_CHECKLIST.md](haus-crm/HANDOVER_CHECKLIST.md) → [CEO_FEEDBACK_R1.md](haus-crm/CEO_FEEDBACK_R1.md)
- **UI เสร็จหมด แต่ยังไม่ต่อของจริง**: ไม่มี auth (หน้า `/login` เป็นดีไซน์), ทุก state เก็บใน React Provider (refresh แล้วหาย), ทุกปุ่ม save เป็น stub, อ่านจริงจาก Supabase แค่ `v_main_listing` / `main_6_buyer_crm` / `v_sale_status`
- **RBAC ใน `lib/rbac.ts` = สเปกที่ RLS ต้องทำตาม** แต่ตอนนี้แค่ซ่อนเมนูฝั่ง browser ยังไม่ป้องกันอะไรจริง
- **ลำดับงาน**: identity bridge (`auth.uid()` ↔ `main_1_hr.employee_code`) → auth → import จาก Google Sheets (ครั้งเดียว ไม่มี two-way sync) → write path ทีละหน้า → RLS
- **การตัดสินใจเรื่อง auth (Ben, 2026-08-03)**: login ด้วย **อีเมลส่วนตัว** (`main_1_hr.email` ไม่ใช่ `work_email`) และ **Admin ตั้งรหัสผ่านให้ user ได้** → ต้องมี server route ที่เรียก Supabase Admin API ด้วย `service_role` key (เก็บฝั่ง server เท่านั้น ห้าม `NEXT_PUBLIC_`) แล้ว gate ด้วย `people.manage`
- **เป็น git repo แยก** (remote: `github.com/hauslivingestate-hash/haus-crm`) — repo แม่ gitignore โฟลเดอร์นี้ไว้ ต้อง `cd haus-crm` ก่อนทำ git ของแอป
- **Deploy = import repo เข้า Vercel** (Hobby plan) → auto-deploy ทุกครั้งที่ push `main`. env var ตั้งใน Vercel ได้แต่ **ไม่จำเป็น** เพราะ...
- **Supabase config ใส่เป็น fallback ในโค้ดแล้ว** ([lib/supabase.ts](haus-crm/lib/supabase.ts)) — url + publishable(anon) key ฝังไว้ (ปลอดภัย เพราะเป็น public key + RLS ป้องกัน) แอปเลยรันได้เองไม่ต้องตั้ง env. ถ้าตั้ง `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY` ใน Vercel จะ override ค่า fallback

### ข้อควรระวังตอน deploy (เจอมาแล้ว)
- ⚠️ **Vercel Hobby + private repo บล็อก deploy ถ้า commit author ไม่ใช่เจ้าของบัญชี** → ต้อง commit ด้วยอีเมล `hauslivingestate@gmail.com` (ตั้ง git identity ของ repo haus-crm ไว้แล้ว: `git config user.email hauslivingestate@gmail.com`)
- ⚠️ **ห้ามรัน `npm audit fix --force`** ในแอปนี้ → มันจะ downgrade Next.js กลับ 9.x พังทั้งแอป
- `npm audit` เตือน 3 high (next / postcss / sharp) — เป็นของที่ **ฝังมากับ Next.js เอง** (build-time) แก้เองไม่ได้ รอ Next.js อัป

### ประวัติงาน (2026-08-03) — รับช่วงต่อ
- ทับ `haus-crm/` ด้วยแอปเวอร์ชัน design-first เต็ม (23 routes) — ของเก่าอยู่ที่ git tag `v1-legacy`
- จัดโฟลเดอร์แม่ใหม่: `db/`, `db/samples/`, `docs/`, `import/`
- เช็คสคีมาจริงบน Supabase → บันทึกไว้ในหัวข้อ TODO 🔴 ด้านบน

### ประวัติงาน (2026-07-07)
- อัป **Next.js 15.1.6 → 15.5.20** ปิดช่องโหว่ CVE-2025-66478
- แก้ปัญหา Vercel บล็อก deploy (commit author) → ตั้ง git identity เป็น hauslivingestate@gmail.com
- แก้ server-side crash (env var หายบน Vercel) → ใส่ Supabase config fallback ในโค้ด (build + รันจริงผ่าน `/`, `/listings` = 200)
