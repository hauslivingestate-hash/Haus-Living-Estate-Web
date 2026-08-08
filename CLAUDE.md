# CLAUDE.md — Haus Living Estate Database

> ไฟล์นี้สรุปงานทั้งหมดของโปรเจกต์ **อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง**
> ผู้ใช้สื่อสารเป็นภาษาไทย — ตอบเป็นไทย, โค้ด/ชื่อคอลัมน์เป็นอังกฤษ

## ภาพรวมโปรเจกต์
ฐานข้อมูล **Supabase (Postgres)** + เว็บแอป CRM (Next.js) สำหรับธุรกิจอสังหาฯ "Haus Living Estate"
ฝั่ง DB เป็น **ไฟล์ SQL + CSV** เอาไปรัน/import ใน Supabase เอง
เว็บแอปอยู่ใน `haus-crm/` — **เป็น git repo แยกต่างหาก + ถูก gitignore ใน repo แม่** (ดูหัวข้อ "เว็บแอป CRM" ท้ายไฟล์)

---

## 📌 สถานะปัจจุบัน — อ่านตรงนี้ก่อน (อัปเดต 2026-08-08)

**ระบบขึ้นของจริงแล้ว** ไม่ใช่เดโมอีกต่อไป — ข้อมูลจริงเข้าครบ + ต้อง login ถึงใช้ได้ + RLS ปิดครบแล้ว + **มี write path จุดแรกแล้ว** + **มีหน้าจัดการบัญชีผู้ใช้แล้ว**

| ด้าน | สถานะ |
|---|---|
| ข้อมูล | ✅ import จากชีทครบ — ทรัพย์ **511** · ลีด **953** · โครงการ **308** · เจ้าของ **452** · กิจกรรม **2,334** · Last Match **56** · พนักงาน **10** · โซน **30** |
| Login | ✅ ใช้งานจริง — **9 บัญชี** (พนักงาน 8 + Admin) · บังคับ login แล้ว · มีหน้าเปลี่ยนรหัส `/account` · **CEO/HR สร้าง/รีเซ็ตรหัสให้คนอื่นได้แล้วที่ ตั้งค่า → บัญชีผู้ใช้** |
| สิทธิ์ | ✅ RBAC อยู่ใน DB — **36 สิทธิ์** · 8 บทบาท · ผูกกับพนักงานจริงแล้ว |
| DB | ✅ 54 ตาราง · เงินเดือน/PII ล็อกแล้ว · +2 function (`create_owner` ดู Phase 5 ข้อ 1, `people.manage_accounts` เป็น permission ไม่ใช่ function — ดู Phase 7) |
| ความปลอดภัย | ✅ **RLS Phase 4 ปิดครบแล้ว** — `demo_read_all` + anon ถูกถอนหมด (ดูรายละเอียดใต้ Phase 4) |
| ⚠️ การบันทึก | 🟡 **เริ่มแล้ว 2/6 — แก้ทรัพย์ + แก้ลีด/แท็ก/ข้อร้องเรียนเขียนจริงแล้ว** ที่เหลือ (เพิ่มลีด/มอบหมาย/เพิ่มทรัพย์/ติ๊กงาน) ยัง stub (ดู Phase 5) |

### งานถัดไปตามลำดับ (ดูรายละเอียดเต็มที่ 🗺️ แผนเฟส ด้านล่าง)
1. **Phase 5 (Write path)** — ต่อปุ่ม save ทุกหน้า: ~~แก้ทรัพย์~~ ✅ → ~~แก้ลีด/เปลี่ยนสเตจ~~ ✅ → **เพิ่มลีด (ถัดไป)** → มอบหมายลีด → เพิ่มทรัพย์ → ติ๊กงาน `/today`
2. **Phase 6** — เชื่อมหน้าที่ยังอ่านจาก seed ในโค้ด (~9 หน้า: `/` `/today` `/contacts` `/projects` `/last-match` `/team` `/leave` `/new-sales` `/website`) ให้ query DB จริง
3. หน้าตั้งค่าโซนในเว็บยังเป็น 1 โซน 1 เซล ต้องแก้ให้รองรับหลายคน (DB รองรับแล้วผ่าน `zone_sales`)
4. ~~หน้าจัดการบัญชีสำหรับ Admin~~ ✅ เสร็จ 2026-08-08 — ดู Phase 7

### 3 เรื่องที่ต้องรู้ก่อนแตะอะไร
1. **อย่าเชื่อตัวเลขใน `haus-crm/DATA_MODEL.md`** — ประเมินขนาดข้อมูลต่ำไป 3–8 เท่า และบอกว่า `Created By` เป็น Stone ทั้งหมด (ผิด กระจายครบ 6 คน)
2. **ชีทต้นทางกรอกผิดช่องหลายจุด** — ถ้าต้อง import อะไรเพิ่ม ให้โปรไฟล์ข้อมูลก่อนเสมอ อย่าเชื่อหัวคอลัมน์ (ดูรายละเอียดใต้หัวข้อ Import)
3. **การมอบหมายงานยึดที่ "ทรัพย์" ไม่ใช่ "โซน"** — `main_4.sale_id` คือตัวจริง โซนเป็นแค่ตัวสำรอง

### รอจากคน
- **HR**: `date_started` ของพนักงานทุกคน (ชีทไม่มี → ladder เซลใหม่ + โควตาลาปีแรกใช้ไม่ได้) · โควตาวันลาจริง (ที่ใส่ไว้เป็นขั้นต่ำตามกฎหมาย ซึ่งผิดแน่ เพราะ 5/8 คนใช้เกินแล้ว)
- **CEO**: ใครเป็นหัวหน้าทีม (ยังไม่มีใครถือ role `sales_leader`, ตาราง `teams` ว่าง) · แท็ก Lead จริง (ตอนนี้ seed ไว้ 4 อัน)
- **Ben**: ปิด **Vercel Deployment Protection** ถึงจะเปิดเว็บจาก URL สาธารณะได้ (ตอนนี้ Vercel ตีกลับก่อนถึงแอป)

---

## โครงสร้างโฟลเดอร์ (จัดใหม่ 2026-08-03)
```
Haus-Web-Wp.Ben/
├── CLAUDE.md              ไฟล์นี้ — อ่านก่อนเริ่มงานทุกครั้ง
├── db/
│   ├── supabase_full_setup.sql   ไฟล์หลัก รันทีเดียวครบ (36 ตาราง + 4 view + 1 function)
│   ├── rls_policies.sql          RLS ทั้งระบบ (Phase 4) — รันหลัง full_setup + หลังมีตาราง RBAC
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

## 🗺️ แผนเฟส — เหลืออะไรบ้าง (อัปเดต 2026-08-03)

ลำดับเดิมที่ตกลงไว้: **identity bridge → auth → import → RLS → write path → เชื่อมหน้าที่เหลือ**

| เฟส | งาน | สถานะ |
|---|---|---|
| 1 | สะพาน `auth.uid()` ↔ `employee_code` + RBAC ใน DB | ✅ เสร็จ 2026-08-03 |
| 2 | Auth จริง (login/session/บังคับ + หน้าเปลี่ยนรหัส) | ✅ เสร็จ 2026-08-03 |
| 3 | Import จากชีท (ครั้งเดียว ไม่มี two-way sync) | ✅ เสร็จ 2026-08-03 |
| 4 | **RLS ทั้งระบบ + ถอน anon** | ✅ เสร็จ 2026-08-03 |
| **5** | **Write path — ต่อปุ่ม save ทุกหน้า** | 🟡 **เริ่มแล้ว 1/6 — แก้ทรัพย์เขียนจริงแล้ว 2026-08-07** |
| **6** | **เชื่อมหน้าที่ยังเป็นข้อมูลตัวอย่าง (~17 routes)** | 🔴 ยังไม่เริ่ม |
| **7** | **งานแอดมิน/ops ที่ยังไม่มีที่ทำ** | 🟡 บางส่วน |
| **8** | **ฟีเจอร์แยก (มีเอกสารของตัวเอง)** | ⬜ ยังไม่เริ่ม |

### เฟส 5 — Write path (ต่อปุ่ม save) 🟡 เริ่มแล้ว 2/6
**ทุกปุ่มบันทึกเคยเป็น stub** state อยู่ใน React Provider รีเฟรชแล้วหาย — **ข้อ 1 เขียนจริงแล้ว 2026-08-07 · ข้อ 2 เขียนจริงแล้ว 2026-08-08** (รายละเอียดข้อ 2 ที่ 🔖 ค้างอยู่ตรงนี้ ด้านบน)
- ✅ **ข่าวดี: policy ฝั่ง DB พร้อมแล้ว** — เฟส 4 เขียน insert/update/delete ครบทุกตาราง ต่อ write ได้เลยไม่โดน 403 (ยกเว้น edge case `main_2_owner` insert ใหม่ที่ต้องผ่าน RPC `create_owner` — ดูด้านบน)
- เรียงตามความคุ้ม: ~~แก้ทรัพย์ (`ListingEditSheet`)~~ ✅ → ~~แก้ลีด/เปลี่ยนสเตจ (`LeadEditSheet` + แท็ก + ข้อร้องเรียน)~~ ✅ → **เพิ่มลีด (`LeadIntakeFab`) — ถัดไป** → มอบหมายลีด (`/assign`) → เพิ่มทรัพย์ (`ListingIntakeButton`) → ติ๊กงาน `/today` (เขียน `tasks` + `activities`)
- ทุกจุดต้องเขียน `audit_log` ด้วย (`changed_by` = ตัวเอง ไม่งั้น policy ปฏิเสธ) — pattern อยู่ใน [lib/mutations/listings.ts](haus-crm/lib/mutations/listings.ts) และ [lib/mutations/leads.ts](haus-crm/lib/mutations/leads.ts) แล้ว ก็อบโครงได้เลย
- ~~`main_6_buyer_crm.tag_id` มีคอลัมน์แล้วแต่แอปยังเก็บแท็กใน `NewLeadsProvider`~~ ✅ เขียนจริงแล้ว (ข้อ 2)

### เฟส 6 — เชื่อมหน้าที่ยังเป็นข้อมูลตัวอย่าง 🔴
`/` แดชบอร์ด · `/today` แผนวันนี้ · `/contacts` · `/projects` · `/last-match` · `/team` · `/leave` · `/new-sales` · `/website` — ทั้งหมดยังอ่านจาก seed ใน `lib/*.ts`
- **ตารางปลายทางมีครบแล้วทุกตัว** (สร้างไว้ 2026-08-03) เหลือแค่เปลี่ยน `lib/*.ts` ให้ query จริงผ่าน `lib/supabase/server.ts`
- `/contacts` ต้อง **import + dedupe กับ `main_2_owner` ด้วยเบอร์โทร** (ตาราง `contacts` ยัง 0 แถว)
- `/` แดชบอร์ดต้องมี `summary_*` rollup ก่อน (ยังไม่ได้ทำ)
- `lib/zones.ts` + `ZonesAdmin` ยังเป็น 1 โซน 1 เซล ต้องแก้ให้ตรง `zone_sales` (many-to-many + `is_primary`)

### เฟส 7 — แอดมิน/ops 🟡
- [x] **หน้าจัดการบัญชี** (สร้าง/รีเซ็ตรหัสให้คนอื่น) — เสร็จ 2026-08-08 ที่ `/settings` → "บัญชีผู้ใช้" ([AccountsManager](haus-crm/components/AccountsManager.tsx) + [lib/mutations/accounts.ts](haus-crm/lib/mutations/accounts.ts) + [lib/supabase/admin.ts](haus-crm/lib/supabase/admin.ts)) gate ด้วย permission ใหม่ `people.manage_accounts` (**CEO / HR / system_admin เท่านั้น** — Ben ตัดสินใจเจาะจงว่าไม่ใช่ `admin` business role และไม่ใช่ `people.manage` เดิมที่กว้างกว่า) — ทดสอบจริงผ่าน `browser-automation` แล้ว: สร้างบัญชีให้ Pai + รีเซ็ตรหัส Mhow ผ่านหน้านี้ ยืนยัน login ได้จริง แล้วลบ/คืนค่าทดสอบทั้งหมด (ลบ auth user ของ Pai ผ่าน Admin REST ตรง คืนอีเมลเดิมจากไฟล์ import, รีเซ็ตรหัส Mhow กลับเป็นของเดิม) — **ต้องตั้ง `SUPABASE_SERVICE_ROLE_KEY` ใน Vercel ด้วยก่อน production จะใช้ได้จริง** (ตอนนี้ตั้งไว้แค่ `.env.local` ในเครื่อง)
- **`teams` ยังว่าง + ไม่มีใครเป็น `sales_leader`** — รอ CEO กำหนดหัวหน้าทีม (กระทบ `visible_employee_codes()` → ตอนนี้ "ทีม" = ตัวเองคนเดียว)
- **`date_started` ว่างทุกคน** (ชีทไม่มี) — กระทบ ladder เซลใหม่ + โควตาลาปีแรก ต้องกรอกในเว็บ
- ทิศ/ตำแหน่ง/อายุ/ส่วนกลาง ที่ import ปล่อยว่างไว้ (ชีทกรอกเลื่อนช่อง) รอกรอกใหม่ในเว็บ

### เฟส 8 — ฟีเจอร์แยก (มีเอกสารของตัวเองใน `haus-crm/*_FEATURE.md`) ⬜
checklist ทรัพย์ A-List/Exclusive · เทมเพลตคำโฆษณา · ladder เซลใหม่ (probation) · เว็บพอร์ทัลลูกค้า

---

## 🔖 ค้างอยู่ตรงนี้ — อ่านก่อนทำต่อ (2026-08-08)

### ✅ เสร็จ 2026-08-08: Phase 5 ข้อ 2 — เขียนจริงหน้าลีด (แก้ลีด + แท็ก + ข้อร้องเรียน)
Ben เลือกเอาครบทั้ง 3 จุดเขียนของหน้าลีดในรอบเดียว (ไม่ใช่แค่ฟอร์มแก้ไขหลัก) — ใหญ่กว่าที่ชื่อ "แก้ลีด" ฟังดู เพราะแท็ก+ข้อร้องเรียนผูกกับ `NewLeadsProvider` (store กลางที่ตาราง `/leads` ก็ใช้ร่วม) ไม่ใช่แค่คอมโพเนนต์เดียว

**ไฟล์ที่แก้ (ใน `haus-crm/`):**
- **[lib/mutations/leads.ts](haus-crm/lib/mutations/leads.ts) (ใหม่)** — `"use server"` `updateLead` (8 ฟิลด์หลัก) · `setLeadTag` · `setLeadComplaint` — pattern เดียวกับ `lib/mutations/listings.ts` ทุกตัวเช็คสิทธิ์ + re-fetch แถวจริงก่อน diff + เขียน `audit_log`
- **[lib/queries.ts](haus-crm/lib/queries.ts)** — `CrmRow`/`getCrm()`/`getLead()` ไม่เคย select `tag_id`/`customer_complain`/`complain_status`/`complain_remark` เลยตั้งแต่แรก ต้องเพิ่มก่อนถึงจะมีค่าจริงส่งลง component แทน seed ได้
- **[lib/leads.ts](haus-crm/lib/leads.ts)** — `COMPLAINT_STATUSES` แก้จากไทย (`เปิด`/`กำลังแก้ไข`/`ปิด`) เป็นอังกฤษ (`Open`/`In Progress`/`Resolved`/`Closed`) ให้ตรง lookup table จริงใน DB (มี FK) — ค่าเดิมจะชน FK violation ทันทีถ้าเขียนจริง
- **[components/LeadEditSheet.tsx](haus-crm/components/LeadEditSheet.tsx)** — `submit()` เรียก `updateLead` จริง (เดิม `console.log`)
- **[components/LeadTagRow.tsx](haus-crm/components/LeadTagRow.tsx)** (หน้า detail) + **[components/LeadsBrowser.tsx](haus-crm/components/LeadsBrowser.tsx)** (ตาราง, 3 จุดที่เคยเรียก `tagOf()`) — เปลี่ยนมาอ่าน `tag_id` จริงจาก `crm`/`lead` prop แทน seed สุ่ม · ตารางมี optimistic local override (`tagOverride`) กัน UI กระตุกตอนติ๊กแท็ก แล้ว `router.refresh()` sync ความจริงกลับมา
- **[components/LeadAdminPanel.tsx](haus-crm/components/LeadAdminPanel.tsx)** — รับ complaint fields เป็น prop แทน `processOf()` เพิ่ม textarea "รายละเอียดข้อร้องเรียน" ผูก `customer_complain` (คอลัมน์มีมาตั้งแต่ 2026-08-03 แต่ UI เดิมไม่มีช่องกรอกเลย) มีปุ่ม "บันทึก" แยก (เดิม auto-save ทุก keystroke ลง provider เฉยๆ)
- **[app/(app)/leads/[id]/page.tsx](haus-crm/app/(app)/leads/[id]/page.tsx)** — ส่ง `tag_id`/complaint fields ลง 2 คอมโพเนนต์ข้างบน
- **[components/NewLeadsProvider.tsx](haus-crm/components/NewLeadsProvider.tsx)** — ลบ `tagOf`/`setTag`/`processOf`/`setProcess`/`tags`/`process` ทิ้ง (ตายแล้ว) เหลือ `addLead`/`assign`/`historyOf` ไว้สำหรับ Phase 5 ข้อ 3-4

**พบระหว่างทำ (บันทึกไว้ ไม่ใช่บั๊กที่งานนี้สร้าง)**: role `listing_support` มี `leads.assign` แต่ไม่มีทั้ง `leads.view_all`/`leads.view_own` — ถ้าเข้า `/leads/[id]` ตรงๆ (ไม่ผ่าน `/assign`) RLS SELECT อาจบล็อกไม่เห็นลีดเลย มีมาตั้งแต่ก่อนงานนี้

**ทดสอบแล้ว**: login เป็น Mhow (S-004, agent) → แก้ budget ลีดของตัวเอง (`L26-018`) + ตั้งแท็ก → เช็ค DB + `audit_log` ตรง (`changed_by='S-004'`) → login เป็น E-001 (system_admin) → เปิดข้อร้องเรียน กรอกรายละเอียด+สถานะ+หมายเหตุ → บันทึก → เช็ค DB ตรง (`complain_status='In Progress'`, `changed_by='E-001'`) → ปิดข้อร้องเรียนคืน (ทุกฟิลด์กลับเป็น null) → **คืนค่า budget/tag_id ของ `L26-018` กลับเป็น null ด้วย SQL ตรง** (ไม่มี UI ล้างค่าฟิลด์เหล่านี้ให้ในฟอร์ม)

**ขั้นต่อไปตอนกลับมาทำ**: ถาม Ben ว่าจะ commit/push เลยไหม → Phase 5 ข้อ 3 (เพิ่มลีด, `LeadIntakeFab`) ต่อ

---

### ✅ เสร็จ 2026-08-08: หน้าจัดการบัญชีผู้ใช้ (สร้าง/รีเซ็ตรหัสผ่าน) — CEO/HR เท่านั้น
Ben สั่งเพิ่มระหว่างคุยกันว่าเหลืออะไรบ้าง — ครั้งแรกบอก "Admin และ CEO" แล้วเปลี่ยนเป็น "HR และ CEO" (role `hr` มีอยู่แล้วในระบบแต่ยังไม่มีคนถือ) และสั่งเพิ่มการสร้างบัญชีใหม่เข้าไปด้วย ไม่ใช่แค่รีเซ็ต

**ไฟล์ที่แก้ (ใน `haus-crm/`):**
- **[lib/supabase/admin.ts](haus-crm/lib/supabase/admin.ts) (ใหม่)** — `createAdminClient()` service-role client ตัวแรกของแอป (`import "server-only"` กันเผลอ import จาก client component — ต้องลง `npm install server-only` เพิ่ม) lazy-read env เพื่อไม่ให้ build พังตอนยังไม่ตั้งค่า
- **[lib/accounts.ts](haus-crm/lib/accounts.ts) (ใหม่)** — `getAccounts()` อ่าน `main_1_hr` ทุกแถว (`p_select using(true)` อยู่แล้ว ไม่ใช่ช่องโหว่ใหม่) คืน `hasAccount` boolean ไม่ส่ง `auth_user_id` ดิบออกไป client
- **[lib/mutations/accounts.ts](haus-crm/lib/mutations/accounts.ts) (ใหม่)** — `resetUserPassword` + `createUserAccount` เช็ค `people.manage_accounts` ก่อนทุกครั้งผ่าน session client แล้วค่อยเรียก `createAdminClient().auth.admin.*` เขียน `audit_log` ทั้งคู่ (ไม่เก็บรหัสผ่านเด็ดขาด)
- **[components/AccountsManager.tsx](haus-crm/components/AccountsManager.tsx) (ใหม่)** — list พนักงานใน `/settings` → section "บัญชีผู้ใช้" ต่อแถว: มีบัญชีแล้ว → ปุ่มรีเซ็ตรหัส, ยังไม่มี → ปุ่มสร้างบัญชี (กรอกอีเมล+รหัสเริ่มต้น)
- แก้ `SettingsView.tsx` / `settings/page.tsx` / `lib/nav.ts` (เติม perm ในเมนู "ตั้งค่า") / `lib/rbac.ts` (เอกสาร permission + เติมให้ role `hr`)

**Permission ใหม่**: `people.manage_accounts` (กลุ่ม `people`) — grant ให้ `ceo`, `hr`, `system_admin` เท่านั้น **ไม่ให้ `admin`** (business role ที่ยังไม่มีคนถือ, Ben ไม่ได้หมายถึงตัวนี้) ทั้ง migration ตรง (`add_people_manage_accounts_permission`, apply บน production แล้ว) และ `db/supabase_full_setup.sql` (สำหรับ setup ใหม่ในอนาคต — `system_admin` ไม่ได้อยู่ในไฟล์ setup เพราะสร้างนอกรอบตอน provision บัญชีจริง ต้องจำ insert เองถ้า setup ใหม่)

**สิ่งที่ค้นพบระหว่างวางแผน (สำคัญถ้าจะเพิ่ม permission ใหม่อีกในอนาคต)**: บัญชี "Admin" (E-001) ที่ใช้ทดสอบกันอยู่ใช้ role **`system_admin`** ไม่ใช่ role `admin` — `system_admin` มี 35/35 สิทธิ์ (ตอนนี้ 36/36) **แบบ insert ตายตัวตอนสร้างบัญชี ไม่ใช่ wildcard** ต่างจาก `ceo` ที่ตอน seed ครั้งแรกใช้ `select 'ceo', key from permissions` (แต่หลัง seed ก็กลายเป็น insert ตายตัวเหมือนกัน) — **permission ใหม่ทุกตัวต้อง insert ให้ `system_admin` ตรงๆ ไม่งั้นจะไม่ได้สิทธิ์อัตโนมัติ แม้จะตั้งใจให้เป็น "ทุกสิทธิ์เสมอ"**

**วิธีทดสอบที่ใช้**: login เป็น E-001 จริงผ่าน `browser-automation` → สร้างบัญชีให้ Pai (SP-003, ลาออก, ไม่เคยมีบัญชี) ด้วยอีเมลทดสอบ → เช็ค `main_1_hr.auth_user_id` ผูกจริง + `audit_log` มีแถว `action='create_account'` ถูกต้อง → รีเซ็ตรหัสผ่าน Mhow เป็นรหัสชั่วคราว → **login จริงด้วยรหัสใหม่ยืนยันว่าใช้ได้** → รีเซ็ตกลับเป็นรหัสเดิมผ่านฟีเจอร์เดียวกัน → ลบบัญชีทดสอบของ Pai ด้วย Admin REST API ตรง (`DELETE /auth/v1/admin/users/{id}` ผ่านสคริปต์ one-off ที่ลบทิ้งหลังรันเสร็จ — `@supabase/supabase-js` เรียกไม่ได้จาก plain `node` บน Node 20 เพราะ realtime client ต้องการ native `WebSocket` ซึ่งมีแค่ Node 22+ ใช้ REST ตรงเลี่ยงปัญหานี้ได้) → คืนอีเมลเดิมของ Pai (`Elvin.satayu@gmail.com`, เจอจากไฟล์ `import/HR Sheet - Employee Lists.csv` เพราะตอนแรกลืมจดค่าก่อนทับ)

**ยังไม่ทำ (บันทึกไว้กันลืม)**:
- **`SUPABASE_SERVICE_ROLE_KEY` ตั้งไว้แค่ `.env.local` ในเครื่อง** — ต้องไปตั้งใน Vercel ด้วย (Settings → Environment Variables) ไม่งั้น production เรียกฟีเจอร์นี้ไม่ได้เลย (throw error ชัดเจนแทนที่จะพังเงียบๆ ตามที่ออกแบบไว้ แต่ก็ยังใช้งานไม่ได้อยู่ดีจนกว่าจะตั้งค่า)
- ยังไม่ได้ทดสอบ negative case (เรียก `resetUserPassword`/`createUserAccount` ตรงๆ ตอน login เป็นคนไม่มีสิทธิ์) แบบ live — เชื่อตาม pattern เดียวกับ `updateListing` ที่ทดสอบแล้วใน Phase 5 ข้อ 1 (permission check ก่อนแตะ DB เสมอ) แต่ยังไม่ได้ exploit-test ฟีเจอร์นี้ตรงๆ
- ไม่มีปุ่มลบบัญชี (auth) ในหน้านี้ — ถ้าต้องการ offboard คนออกจริงต้องทำ SQL ตรงหรือเพิ่มฟีเจอร์แยก

**ขั้นต่อไปตอนกลับมาทำ**: ถาม Ben ว่าจะ commit/push เลยไหม (เหมือนรอบ Phase 5 ข้อ 1) → เตือนให้ตั้ง `SUPABASE_SERVICE_ROLE_KEY` ใน Vercel → กลับไปทำ Phase 5 ข้อ 2 ต่อ

### ✅ เสร็จ 2026-08-08 (ต่อเนื่องจากด้านบน): ปิดหน้า `/account` (เปลี่ยนรหัสผ่านตัวเอง) เหลือแค่ CEO/HR/Admin
Ben เห็นหน้า `/account` บน production (login เป็น Golf ธรรมดา) แล้วสั่งให้เอาออกยกเว้น 3 ตำแหน่งที่แก้บัญชีคนอื่นได้อยู่แล้ว — ใช้ permission ตัวเดียวกับด้านบน (`people.manage_accounts`) เป็นตัวกรอง ไม่ได้สร้างใหม่

**ไฟล์ที่แก้:**
- **[app/(app)/account/page.tsx](haus-crm/app/(app)/account/page.tsx)** — เพิ่ม `if (!auth.permissions.includes("people.manage_accounts")) redirect("/")` (เดิมคอมเมนต์บอกไว้ตรงๆ ว่า "No permission gate: every account owns itself" — ทับ logic เดิมนั้นตามที่ Ben สั่ง)
- **[components/Sidebar.tsx](haus-crm/components/Sidebar.tsx)** — ซ่อนลิงก์ "บัญชีของฉัน" ทั้ง 2 จุด (การ์ดผู้ใช้แบบธรรมดา + dropdown ของคนที่มี `roles.manage`) ด้วยเช็คสิทธิ์เดียวกัน — **ปุ่ม "ออกจากระบบ" ไม่กระทบ** เพราะเป็นปุ่มแยกอยู่แล้วในทั้ง 2 เลย์เอาต์ ไม่ได้ผูกกับหน้า `/account`

**ผลที่ตามมาที่ Ben ควรรู้**: ตอนนี้มีแค่ **Stone (CEO)** กับ **E-001 (Admin/system_admin)** ที่เปลี่ยนรหัสผ่านตัวเองได้ — **role `hr` ยังไม่มีคนถือ** เลยไม่มีใครใช้สิทธิ์นี้ในทางปฏิบัติอีกคน จนกว่าจะมีคนได้รับมอบ role นี้จริง พนักงานที่เหลือทั้งหมด (Agent/Listing Support/Marketing) ลืมรหัสผ่านแล้วต้องให้ Stone หรือ Admin (E-001) รีเซ็ตให้ผ่าน `/settings` → บัญชีผู้ใช้ แทนที่จะเปลี่ยนเองได้

**ทดสอบแล้ว**: login เป็น Mhow (agent) → ไม่เห็นลิงก์ "บัญชีของฉัน" ใน sidebar + ยิง URL `/account` ตรงๆ โดน redirect กลับ `/` ทันที · login เป็น E-001 → เห็นลิงก์ปกติ + เข้าหน้าได้ + เห็นฟอร์มเปลี่ยนรหัสผ่านปกติ

---

### ✅ เสร็จ 2026-08-07: Phase 5 ข้อ 1 — เขียนจริงหน้าแก้ไขทรัพย์ (`ListingEditSheet`)
**นี่คือ write ตัวแรกของทั้งแอป** — ตอนก่อนหน้านี้ทั้งโค้ดเบสไม่มี `.insert()/.update()/.delete()` หรือ `"use server"` เลยสักที่ ยังไม่ push ไปยัง git

**ไฟล์ที่แก้ (ใน `haus-crm/`, ยังไม่ commit):**
- **[lib/mutations/listings.ts](haus-crm/lib/mutations/listings.ts) (ใหม่)** — `"use server"` export `updateListing(listingId, patch)`. แก้ `main_4_listing_database` โดยตรง (ไม่ใช่ view) — ดึงแถวปัจจุบันสดจาก DB ก่อนเทียบ diff (ไม่เชื่อ client) แบ่งฟิลด์เป็น `core`/`marketing` ตาม `LISTING_FIELDS` map (คุมทั้ง type-coerce และสิทธิ์แก้) เขียน `audit_log` ทุกครั้งที่มีการเปลี่ยนจริง แล้ว `revalidatePath` 3 หน้า (`/listings` `/listings/[id]` `/company-listings`)
- **[components/ListingEditSheet.tsx](haus-crm/components/ListingEditSheet.tsx)** — `submit()` เรียก `updateListing` จริงแล้ว (ไม่ใช่ `console.log` stub) มี busy/error state แบบเดียวกับ `AccountSettings.tsx` · ฟิลด์ "โครงการ" (`project_name_eng`) ล็อกแก้ไม่ได้ตามที่ Ben ตัดสินใจ (กระทบทุก listing ในโครงการเดียวกัน) · เจ้าของไม่ต้อง disable อะไร — กรอกตอนไม่มี `owner_id` แล้วบันทึกจะสร้างเจ้าของใหม่ให้เอง

**ปิดช่องโหว่ไปด้วยระหว่างทาง**: `main_4` UPDATE policy ไม่กรองคอลัมน์ (role `marketing` เดิมมีทางแก้ราคาได้ถ้ามีจุดเข้าฟอร์มนี้) — `updateListing` กรองเองที่ชั้นแอปผ่าน `LISTING_FIELDS[key].group` (core ต้อง `listings.edit`, marketing ต้อง `listings.marketing`) ทดสอบแล้วว่า field ที่ไม่มีสิทธิ์ถูกกรองทิ้งเงียบๆ ไม่ถึง DB

**🐛 บั๊กที่เจอระหว่างทดสอบจริง (ทั้งคู่แก้แล้ว):**
1. **RLS ของ `main_2_owner` บล็อกการสร้างเจ้าของใหม่** — `INSERT ... RETURNING owner_id` (ที่ supabase-js ทำเวลาใช้ `.insert().select()`) โดน SELECT policy เช็คด้วย และ SELECT policy ให้เห็นเฉพาะเจ้าของที่ **มี listing ผูกอยู่แล้ว** — เจ้าของที่เพิ่งสร้างยังไม่ผูกกับใคร เลยมองไม่เห็นตัวเอง ชน 42501 ทุกครั้ง (ทดสอบเจอจริงกับ Mhow/S-004 ผ่าน browser-automation ก่อนจะแก้)
   **แก้**: เพิ่ม SQL function `create_owner(name,phone,line) returns bigint` (`security definer`, เช็คสิทธิ์เองเหมือน INSERT policy เดิมทุกประการ) — apply เป็น migration `add_create_owner_rpc` แล้วบน production. `updateListing` เรียกผ่าน `.rpc('create_owner', ...)` แทน `.insert().select()`
2. **`router.refresh()` ทำให้ข้อความ "บันทึกแล้ว" หายเกือบทันที** — `useEffect` ที่ reset draft ตอนเปิดชีท (`if (open) { setF/setDone/setError }`) มี `listing` เป็น dependency ด้วย พอ `router.refresh()` ทำให้ parent ส่ง `listing` prop ใหม่มา (ข้อมูลสดจาก DB) effect รันซ้ำและล้าง `done` ทิ้งทันที
   **แก้**: เปลี่ยน dependency เหลือแค่ `[open]` — reset เฉพาะตอนชีท**เปิด** ไม่ใช่ทุกครั้งที่ `listing` prop เปลี่ยนระหว่างเปิดอยู่

**วิธีทดสอบที่ใช้** (ยืนยันว่าเขียนจริง ไม่ใช่แค่ UI ขึ้นข้อความ): login จริงเป็น Mhow (S-004, role agent) ผ่าน `browser-automation` skill (สคริปต์ custom ผ่าน `--script`, ต้องใช้ path แบบ `/C:/Users/...` ถึงจะไม่ชน bug ของ `browser.mjs` เอง — `scriptPath.startsWith('/')` เท่านั้นที่ import ตรงๆ ไม่พังบน Windows) → แก้ทรัพย์ `HPHU106` จริง → เช็คด้วย Supabase MCP ว่า `main_4_listing_database` + `main_2_owner` + `audit_log` เปลี่ยนตรงตามที่กด รวมถึงเช็คว่า trigger เดิม (`trg_set_livinginsider_date` ตั้ง `updated_at` ให้เอง, `trg_log_listing_status_change` เขียน `main_9_support_log`) ยังทำงานอยู่ใต้ RLS ปกติ — **ทดสอบเสร็จแล้วลบ/คืนค่าข้อมูลทดสอบทั้งหมด** (remark/listing_status คืนค่าเดิมผ่าน UI, เจ้าของทดสอบลบด้วย SQL ตรงเพราะ UI ยังไม่มีปุ่มลบเจ้าของ)

**ยังไม่ทำ (บันทึกไว้กันลืม)**:
- ยังไม่ backfill `main_9_support_log.support_id` (เป็น null เหมือนเดิม — ต้อง query แบบ heuristic ถ้าจะทำ แยกเป็นงานเดี่ยว)
- Phase 5 ข้อ 2-6 (แก้ลีด/เพิ่มลีด/มอบหมาย/เพิ่มทรัพย์/ติ๊กงาน) ยังไม่เริ่ม — ใช้ pattern เดียวกับข้อ 1 ได้เลย (server action ใน `lib/mutations/*.ts` + re-fetch แถวจริงก่อน diff + audit_log + revalidatePath)

**อัปเดต**: commit/push ทั้ง `haus-crm` และ repo แม่แล้วในวันเดียวกัน (2026-08-07) — ดูหัวข้อ "หน้าจัดการบัญชีผู้ใช้" ด้านบนสำหรับงานล่าสุดถัดจากนี้

---

### ✅ แก้แล้ว 2026-08-05: บั๊กหน้า `/leads` — "Application error: a client-side exception has occurred"
สาเหตุจริง**ไม่ใช่**เรื่อง chunk ค้าง/deploy เก่าอย่างที่เดาไว้รอบก่อน (ลอง Ctrl+Shift+R แล้วยังพัง) — เป็นบั๊กจริงในโค้ด:

**สาเหตุ**: [lib/tags.ts](haus-crm/lib/tags.ts) ฟังก์ชัน `seedTagForLead()` (ตัวสุ่มแท็กแบบ deterministic ที่ยังไม่ได้ต่อ `tag_id` จริงจาก DB) ใช้ `h >> 3` (signed right shift) กับ hash ที่เป็น unsigned 32-bit — พอ hash ≥ 2^31 จะได้ index ติดลบ ทำให้ `tags[index]` เป็น `undefined` แล้วพังตอนอ่าน `.id` ต่อ → "Cannot read properties of undefined (reading 'id')"
ดึงข้อมูลลีดจริงทั้ง 953 แถวจาก Supabase มารันฟังก์ชันนี้ตรงๆ พบว่า **294/953 lead_id ชนบั๊กนี้พอดี** — แก้เป็น `h >>> 3` (unsigned shift) แล้วรันซ้ำ 0 error

**แก้ไปด้วย 2 commit** ใน `haus-crm` (push แล้ว, deploy ขึ้น production เรียบร้อย):
1. `lib/tags.ts:69` — `>>` → `>>>` (ตัวจริง)
2. `components/Sidebar.tsx:127` — `roles.find(r => r.id === id)` → `r?.id === id` (กันไว้เพิ่ม จุดเดียวในแอปที่อ่าน `.id` แบบไม่กัน แม้พิสูจน์ไม่ได้ว่าเป็นสาเหตุจริง)

**บทเรียน**: เดา root cause จากอ่านโค้ดอย่างเดียวไม่พอ — ตัวที่ยืนยันได้จริงคือดึง **real data จาก Supabase มารันฟังก์ชัน logic ตรงๆ นอกเว็บ** (ไม่ต้องพึ่ง login/browser) เจอ error ตรงเป๊ะทันที ควรทำเป็นขั้นแรกๆ เวลาเจอบั๊กที่เกี่ยวกับข้อมูลจริง แทนที่จะไล่อ่านโค้ดหรือจำลอง session

### 🟡 ค้างจากรอบนี้ (ไม่เร่ง)
- **role `marketing` ยังแก้ราคาทรัพย์ได้ผ่าน DB โดยตรง (RLS)** — RLS กรองแถวไม่ได้กรองคอลัมน์ ยังจริงอยู่ในระดับ DB (ต้องทำ RPC เฉพาะคอลัมน์การตลาดถ้าจะปิดที่ต้นทาง) **แต่ผ่าน `updateListing` (Phase 5 ข้อ 1) ปิดแล้วที่ชั้นแอป** — เส้นทางเขียนอื่นในอนาคต (ถ้ามี) ต้องกรองเองซ้ำแบบเดียวกัน อย่าลืม
- **`v_sale_status` เป็น security_invoker** → เซลเห็นเลขตัวเอง คนอื่นเป็น 0 ถ้า Ben อยากได้กระดานผลงานทั้งทีมต้องทำ view แยกแบบ security definer
- **หน้า "ทรัพย์" จะว่างสำหรับ Marketing/Admin/HR** (ไม่ได้ดูแลทรัพย์เอง) — ตั้งใจตามดีไซน์ แต่ถ้า support อยากเห็นทั้งหมดในหน้าแรกด้วย แก้ที่ `getMyListings()` บรรทัดเดียว
- ~~ยังไม่มีหน้าจัดการบัญชีสำหรับ Admin~~ ✅ เสร็จ 2026-08-08 — ดู Phase 7

## งานที่ยังค้าง (TODO)

### ✅ Import ข้อมูลจริงเสร็จแล้ว (2026-08-03) — สคริปต์: [import/run_import.py](import/run_import.py)
| ตาราง | แถว | หมายเหตุ |
|---|---|---|
| main_3_property_detail | 308 | Project ID มาจากชีทครบ |
| main_2_owner | 452 | ยุบซ้ำด้วย (ชื่อ+เบอร์) |
| main_4_listing_database | 511 | ผูกโครงการได้ 489 · มีเซลดูแลครบ 511 · มีเจ้าของ 465 |
| main_6_buyer_crm | 953 | ผูกทรัพย์ได้ 882 |
| main_7_last_match | 56 | ข้ามแถว Test 3 |
| activities | 2,334 | ข้าม 26 แถวที่ Action กรอกเป็นข้อความมั่ว |
| main_10_potential_listing | 210 | trigger สร้างเองจาก potential |

**ชีทมีปัญหา "กรอกผิดช่อง" 2 จุด — ต้องรู้ก่อนแก้อะไรต่อ:**
- **buyer_focus เหลื่อม 1 ช่องทั้งชีท** (คอลัมน์ 2–7): หัวเขียน `Admin Remark|Potential|Lead Status|สนใจ|Lead Name|Phone` แต่ข้อมูลจริงคือ `Potential|Lead Status|สนใจ|Lead Name|Phone|Admin Remark` → สคริปต์จับคู่ใหม่ตามความหมาย (ยืนยัน 953/953)
- **listings**: `ทิศ/ตำแหน่ง/อายุ/ส่วนกลาง` กรอกเลื่อนกันเกือบทั้งชีท (ตำแหน่งเก็บค่าทิศ 347 แถว · ส่วนกลางเก็บค่าตำแหน่ง 421 แถว) → **Ben สั่งให้เอาเฉพาะค่าที่อยู่ถูกช่องจริง** (ทิศ 58 · ตำแหน่ง 37 · อายุ 53 · ส่วนกลาง 57) ที่เหลือปล่อยว่าง รอกรอกใหม่ในเว็บ

**อย่างอื่นที่ทำระหว่าง import:** จับคู่โครงการด้วย**ชื่อไทย** (ชีททรัพย์ใส่ชื่อไทยในช่อง "Project Name (Eng)" จับด้วยอังกฤษได้ 1/508) · `hook` เอามาจาก `Buyer Persona` · Listing ID ซ้ำ 2 ตัวขยับเลข (HKAL058→060, LRP2036→037) · เพิ่มโซน `PKD` (Pak-kred) · เพิ่มกิจกรรม Owner Talk/Update Price/เซ็นสัญญา · `Visit→Owner Visit`, `Showing→Show`, `Closing→Close` · **`dd_boost/lv_boost/fb_repost` เปลี่ยนเป็น boolean** (ชีทเป็น TRUE/FALSE ไม่ใช่วันที่)

⚠️ **เอกสารเดิม (DATA_MODEL.md) ประเมินขนาดข้อมูลต่ำไปมาก** — บอก 109 ทรัพย์/176 ลีด/39 โครงการ/289 actions แต่ของจริง 511/953/308/2360 และ `Created By` **ไม่ได้เป็น Stone ทั้งหมด** (กระจายครบ 6 คน) อย่าเชื่อตัวเลขในเอกสารนั้น

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
- [x] 🔑 **เปิด auth แล้ว 2026-08-03** — `AUTH_ENFORCED` default = **เปิด** (ปิดได้ด้วย `NEXT_PUBLIC_AUTH_ENFORCED=0`). ตั้ง default ในโค้ดไม่ใช่ที่ Vercel เพราะ `NEXT_PUBLIC_*` ฝังตอน build อยู่แล้ว + โปรเจกต์นี้เคยเจอ env var หายบน host
  - ทดสอบด้วยเบราว์เซอร์จริงแล้ว: login เป็น Q → เข้า `/` ได้ · sidebar ขึ้น "Q · Agent (Sales)" · **ไม่มีปุ่ม "ดูในมุมมอง"** (ไม่มี `roles.manage`) · เมนูเหลือเฉพาะของ agent (ไม่มี ตั้งค่า/ทีม/เว็บพอร์ทัล) · `/account` 200 · console error 0
  - ทุกหน้ากลายเป็น **dynamic** (ทิ้ง ISR 30 วิ) เพราะ layout อ่าน session — ถูกต้องแล้ว หน้าที่ cache ให้คนนึงห้ามเสิร์ฟให้อีกคน
- [x] **หน้าเปลี่ยนรหัสผ่าน** — `/account` ([AccountSettings](haus-crm/components/AccountSettings.tsx)) เข้าจากเมนูผู้ใช้ใน sidebar. **เช็ครหัสเดิมก่อนเปลี่ยนเสมอ** (Supabase ไม่บังคับ ทำให้คอมที่ลืม logout เปลี่ยนรหัสเจ้าของบัญชีได้)
- [x] **หน้าจัดการบัญชีสำหรับ Admin** — เสร็จ 2026-08-08 ดู Phase 7
- [x] **ย้าย `lib/queries.ts` ไป session-aware client แล้ว 2026-08-03** ([lib/supabase/server.ts](haus-crm/lib/supabase/server.ts)) — **ลบ `lib/supabase.ts` (anon client ไร้ session) ทิ้งแล้ว** ไม่ได้แค่เลิกใช้ เพราะถ้าปล่อยไว้ call site ต่อไปที่หยิบไปใช้จะได้ผลลัพธ์ว่างเปล่าเงียบ ๆ แทนที่จะ error
- [x] **ปิดรูรั่วเงินเดือน/PII แล้ว 2026-08-03** — RLS กรองได้แค่ "แถว" กรอง "คอลัมน์" ไม่ได้ จึงใช้ **GRANT ระดับคอลัมน์**: ถอน `select` ทั้งตารางจาก `anon`+`authenticated` แล้ว grant กลับเฉพาะคอลัมน์ที่ไม่อ่อนไหว
  - **ไม่ให้ใครแตะผ่าน API เลย**: `salary` `commission` `id_card_no` `kbank_account` `payslip_drive` `agreement_files`
  - ดูได้ทางเดียวคือ view **`v_employee_private`** ที่เช็ค `has_perm()` ทีละคอลัมน์ (ไม่มีสิทธิ์ = ได้ `null`) · anon เข้าไม่ได้เลย
  - ⚠️ view นี้**ตั้งใจไม่ใส่ `security_invoker`** (ต่างจาก view อื่นทั้งโปรเจกต์) เพราะต้องรันด้วยสิทธิ์เจ้าของถึงจะอ่านคอลัมน์ที่เพิ่งถอนสิทธิ์ได้
  - ทดสอบแล้ว: anon ขอ `salary` → 42501 permission denied · anon ขอ `select=*` → denied · Admin เห็นเงินเดือน · agent (Q) เห็นเป็น null
- [x] ✅ **RLS Phase 4 — รันบน production แล้ว 2026-08-03**: [db/rls_policies.sql](db/rls_policies.sql) (82 policy / 54 ตาราง) รันซ้ำได้ ท้ายไฟล์มี query ตรวจผล (ต้องได้ 0 แถว)
  - **ลำดับที่ใช้จริง (สำคัญถ้าต้องทำซ้ำที่อื่น)**: สร้าง policy ใหม่ให้ครบทุกตารางก่อน → เช็คว่าไม่มีตารางตกหล่น → **ค่อยถอน `demo_read_all` + anon เป็นขั้นสุดท้าย** เพราะ policy เป็น permissive (OR กัน) จึงไม่มีช่วงที่แอปอ่านอะไรไม่ได้เลย
  - **ผลทดสอบ** (จำลอง session ด้วย `set local request.jwt.claims` แล้ว rollback): anon ยิง REST ได้ `42501` ทุกตาราง/วิว/rpc · **Q (agent)** เห็นทรัพย์ 511 · ลีด **169 จาก 953** (ของตัวเองล้วน) · last match 16 · กิจกรรม 471 · ใบลา 2 · **E-001 (admin)** เห็นครบ 511/953/56/2334/20 · **Pui (marketing)** เห็นทรัพย์ 511 แต่ลีด/last match/กิจกรรม = 0
  - **ทดสอบด้านลบผ่านหมด**: agent ฮุบลีดคนอื่น 0 แถว · ลบทรัพย์ 0 · แก้ชื่อคนอื่น 0 · ลบ A-List log 0 · เพิ่ม role ให้ตัวเอง → `42501` · เงินเดือนคนอื่นใน `v_employee_private` = null
  - **trigger ยังทำงานใต้ RLS** — ทดสอบ agent แก้ `listing_status` + ดัน `potential` เป็น A List: support_log 511→512 · main_10 210→211 · main_11 210→211 แล้ว rollback (ยืนยันข้อมูลกลับมาเท่าเดิมครบทุกตาราง)
  - เพิ่มเติมที่ทำพร้อมกัน: `revoke execute` helper 5 ตัวจาก anon (ปิด `/rest/v1/rpc/*`) + ตรึง `search_path` ของ trigger function 11 ตัว (advisor 0011)
  - ⚠️ `rls_auto_enable()` ที่ advisor เตือน — **ของ Supabase เอง อย่าแตะ** (event trigger บังคับเปิด RLS ให้ตารางใหม่ เรียกผ่าน REST ไม่ได้จริง)
  - สิ่งที่ไฟล์นี้ทำ: ลบ `demo_read_all` + `admin_write` ทุกตาราง · **`revoke all ... from anon` ทุกตาราง/วิว** (ไม่ใช่แค่ปิด policy — ให้ขอมาแล้วได้ 42501 ชัด ๆ แทน `[]` เงียบ ๆ) · สร้าง select/insert/update/delete ครบทุกตารางโดยอิง `has_perm()` + `visible_employee_codes()` ตัวเดียวกับที่ UI ใช้
  - ขอบเขตที่ตั้งไว้: **ทรัพย์ = ของบริษัท** ใครมี `listings.view` เห็นหมด · **ลีด/CRM = ของใครของมัน** (`leads.view_own` → `sale_id = ตัวเอง`) · **last match** own/team/all ครบ 3 ชั้น · **แผนงาน/ปุ่มลัด/แจ้งเตือน** ส่วนตัวล้วน · `audit_log` เขียนได้ในนามตัวเอง **ไม่มี update/delete โดยตั้งใจ**
  - ⚠️ **main_9/10/11 ต้องเปิดกว้างเท่าสิทธิ์แก้ทรัพย์** เพราะ trigger (`log_listing_status_change`, `sync_potential_listing`) **ไม่ใช่ security definer** → รันด้วยสิทธิ์คนแก้ทรัพย์ ถ้า policy แคบกว่า การแก้ทรัพย์จะล้มทั้งรายการ
  - ⚠️ **ยังกัน role `marketing` แก้ราคาไม่ได้** — RLS กรองแถวไม่ได้กรองคอลัมน์ และ column grant ผูกกับ role `authenticated` ทั้งก้อน (แยกรายคนไม่ได้) ทางแก้จริงคือทำ RPC เฉพาะคอลัมน์การตลาด
  - ⚠️ **หลังรัน `v_sale_status` จะเปลี่ยนพฤติกรรม** — เป็น `security_invoker` → เซลจะเห็นตัวเลขของตัวเองจริง คนอื่นเป็น 0 (ถูกต้องแล้ว แต่ผิดจากที่เคยเห็นก่อนหน้า)
- [x] **17 คอลัมน์จากชีท Listings** — เพิ่มแล้ว 2026-08-03 (`main_4` 47 → **64 คอลัมน์**, `v_main_listing` 55 → **72**): `dd_boost` `lv_boost` `fb_repost` `marketing_report` `facebook_ad_link` `new_photo_link` `hook` `photo_album_link` `link` `last_match` `last_match_type` `last_match_price` `last_match_remark` `common_fee_rate`+`common_fee_unit`+`common_fee_note` `built_year`
  - **ส่วนกลางเก็บเป็นเรต** (`per_wa_month`/`per_sqm_month`) ไม่ใช่ยอดรวม — ชีทปน 3 หน่วย ต้องแปลงตอน import + เก็บข้อความดิบไว้ใน `common_fee_note`
  - **`built_year` = ปี ค.ศ. ที่สร้าง** ไม่ใช่จำนวนปี — ฟอร์มกรอกทรัพย์ต้องเปลี่ยนคำถามเป็น "สร้างปีไหน"
  - `last_match_type` ยังไม่ทำ FK → `close_type` รอดูค่าจริงในชีทก่อน (กัน import ล้ม)
- [x] **คอลัมน์ intake ของ `main_6_buyer_crm`** — เพิ่มแล้ว 2026-08-03 (26 → **37 คอลัมน์**) + ตารางใหม่ `lead_tags_ref` (seed 4 แท็ก รอ CEO ตั้งจริง): `tag_id` `marketing_channel`+`marketing_channel_other` `contact_by` `gender` `nationality` `contact_date`/`contact_time` `customer_complain`/`complain_status`/`complain_remark`
  - **เลือกเก็บตรง ๆ ไม่ดึงจาก main_5 ผ่าน view** เพราะ `lead_ref` ว่าง 10/10 แถว + main_5 = บันทึกตอนรับลีด (ไม่ควรถูกเซลแก้ทับ)
  - **ไม่มี `recheck_status`** — derive จาก `pipeline_stage` (เลย 'Lead' = ติดต่อแล้ว) เก็บเป็นคอลัมน์จะได้ข้อมูล 2 ชุดที่ขัดกันเอง
  - แอปเรียก `source` = คอลัมน์ `marketing_channel` (ตั้งชื่อให้ตรง main_5 ทั้ง DB)
- [ ] **`zone`**: ตัดสินใจแล้วว่า**ไม่เพิ่ม** `sales_sheet`/`location`/วันที่ จากชีท HR. แต่ชีทมี ~30 โซน DB มี 23 → import แล้วต้องเช็คกฎ "ตัวย่อโซนห้ามเป็นคำนำหน้าของอีกโซน" ใหม่ (เพราะ `zone_id` ประกอบเป็น listing_id)
- [ ] ⚠️ **`db/supabase_full_setup.sql` ไม่มีคำสั่ง RLS/policy** — รันไฟล์นั้นเดี่ยว ๆ บน project เปล่าจะได้ตาราง **RLS ปิด = anon เขียนได้** → **ต้องรัน [db/rls_policies.sql](db/rls_policies.sql) ตามทุกครั้ง** (ไฟล์นั้นต้องรันหลังตาราง RBAC มีข้อมูลแล้ว เพราะทุก policy อ้าง `has_perm()`)
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
- [x] **ขอบเขตหน้าทรัพย์ — Ben ตัดสินใจ 2026-08-03**: หน้า **"ทรัพย์" = เฉพาะที่ตัวเองดูแล** (`effective_sale_id`) · หน้า **"ทรัพย์ทั้งบริษัท" = ทุกแถว แต่เบอร์/ไลน์เจ้าของถูกตัดที่ RLS** (ไม่ใช่แค่ไม่โชว์คอลัมน์ — เดิมข้อมูลถึงเบราว์เซอร์ + ยิง REST ได้ครบ 452 ราย)
  - กรองหน้าแรกทำที่ **แอป (`getMyListings()`) ไม่ใช่ RLS** เพราะหน้าทรัพย์ทั้งบริษัทอ่านตารางเดียวกันและต้องเห็นครบ (มีไว้หา Co-Agent)
  - `contacts.view_all` ยังเห็นเจ้าของครบ (support/หัวหน้า/CEO) — ทดสอบแล้ว agent 89/452 · support 452 · marketing 0 · แถวทรัพย์ 511 ครบทุกคน
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
- ⚠️ **เอกสาร 3 ไฟล์นั้นเขียนไว้ตอนเฟสออกแบบ — หลายอย่างล้าสมัยแล้ว** (ขนาดข้อมูล · "ไม่มี auth" · "ทุก state อยู่ใน memory") ให้เชื่อ CLAUDE.md ไฟล์นี้ก่อน แล้วใช้ 3 ไฟล์นั้นดู**เหตุผลเบื้องหลังการออกแบบ** ซึ่งยังใช้ได้อยู่
- **สิ่งที่ต่อของจริงแล้ว**: auth + session + สิทธิ์จาก DB · `/account` เปลี่ยนรหัส · อ่านข้อมูลจริงจาก `v_main_listing` / `main_6_buyer_crm` / `v_sale_status`
- **สิ่งที่ยังเป็นของปลอม**: ทุกปุ่ม save (นอกจากเปลี่ยนรหัสผ่าน) · store ในหน้า ตั้งค่า/กิจกรรม/วันลา ยังเก็บใน React Provider (refresh แล้วหาย)
- **RBAC ใน `lib/rbac.ts` = สเปก** ตอนนี้ย้ายเข้า DB แล้ว (ตาราง `roles`/`permissions`/`user_roles`) แต่ **ฝั่งแอปยังกรองแค่เมนู** — การป้องกันจริงต้องรอ RLS
- **การตัดสินใจเรื่อง auth (Ben, 2026-08-03)**: login ด้วย **อีเมลส่วนตัว** (`main_1_hr.email` ไม่ใช่ `work_email`) และ **Admin ตั้งรหัสผ่านให้ user ได้** → ต้องมี server route ที่เรียก Supabase Admin API ด้วย `service_role` key (เก็บฝั่ง server เท่านั้น ห้าม `NEXT_PUBLIC_`) แล้ว gate ด้วย `people.manage` (ยังไม่ได้ทำ)
- **เป็น git repo แยก** (remote: `github.com/hauslivingestate-hash/haus-crm`) — repo แม่ gitignore โฟลเดอร์นี้ไว้ ต้อง `cd haus-crm` ก่อนทำ git ของแอป
- **Deploy = import repo เข้า Vercel** (Hobby plan) → auto-deploy ทุกครั้งที่ push `main`. env var ตั้งใน Vercel ได้แต่ **ไม่จำเป็น** เพราะ...
- **Supabase config ใส่เป็น fallback ในโค้ดแล้ว** ([lib/supabase.ts](haus-crm/lib/supabase.ts)) — url + publishable(anon) key ฝังไว้ (ปลอดภัย เพราะเป็น public key + RLS ป้องกัน) แอปเลยรันได้เองไม่ต้องตั้ง env. ถ้าตั้ง `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY` ใน Vercel จะ override ค่า fallback

### URL ที่ใช้จริง + Deployment Protection
- **URL สำหรับทีม: `https://haus-crm-iota.vercel.app`** (production alias ของโปรเจกต์)
  - ⚠️ **`haus-crm.vercel.app` ไม่ใช่ของเรา** — เป็นโปรเจกต์ของคนอื่นบน Vercel อย่าเอาไปแชร์
  - ลิงก์ที่ก๊อปจากหน้า dashboard ของ Vercel (`haus-<hash>-...`) ใช้แชร์ไม่ได้เหมือนกัน ให้ส่ง `haus-crm-iota` เท่านั้น
- **Vercel Authentication (SSO) = Standard Protection** เปลี่ยนแล้ว 2026-08-03 (เดิม `all_except_custom_domains` → **`preview`**)
  - production เข้าได้โดยไม่ต้องมีบัญชี Vercel (ไปเจอหน้า login ของแอปแทน) · preview ของ branch อื่นยังถูกล็อกไว้
  - ⚠️ **แปลว่าด่านเดียวที่กันคนนอกตอนนี้คือหน้า login ของแอป** — เดิมมี Vercel SSO บังอีกชั้น ตอนนี้ไม่มีแล้ว จึงต้องรัน `db/rls_policies.sql` ให้จบ

### ข้อควรระวังตอน deploy (เจอมาแล้ว)
- ⚠️ **Vercel Deployment Protection เปิดอยู่** (2026-08-03) → เปิด URL แล้วเด้งไป `vercel.com/sso-api` **ตั้งแต่ก่อนถึงแอป** แม้แต่หน้า `/login` — ไม่ใช่บั๊กของเรา. ปิดที่ Settings → Deployment Protection → Vercel Authentication = Disabled (ปิดได้แล้วเพราะแอปมี login ของตัวเอง). URL ที่มี `-git-main-` เป็น deployment ของ branch ไม่ใช่ production
- ⚠️ **Vercel Hobby + private repo บล็อก deploy ถ้า commit author ไม่ใช่เจ้าของบัญชี** → ต้อง commit ด้วยอีเมล `hauslivingestate@gmail.com` (ตั้ง git identity ของ repo haus-crm ไว้แล้ว: `git config user.email hauslivingestate@gmail.com`)
- ⚠️ **ห้ามรัน `npm audit fix --force`** ในแอปนี้ → มันจะ downgrade Next.js กลับ 9.x พังทั้งแอป
- `npm audit` เตือน 3 high (next / postcss / sharp) — เป็นของที่ **ฝังมากับ Next.js เอง** (build-time) แก้เองไม่ได้ รอ Next.js อัป

### ประวัติงาน (2026-08-03) — รับช่วงต่อ
ทำในเซสชันเดียว เรียงตามลำดับ:

1. **จัดบ้าน** — ทับ `haus-crm/` ด้วยแอป design-first เต็ม 23 routes (ของเก่าอยู่ที่ git tag `v1-legacy`) · จัดโฟลเดอร์แม่เป็น `db/` `docs/` `import/` · push ขึ้น GitHub ทั้ง 2 repo
2. **เช็คของจริง** — เช็คสคีมา Supabase แล้วพบว่าเอกสารส่งมอบคลาดเคลื่อนหลายจุด (15 คอลัมน์ที่ "แค่แก้ view" จริง ๆ ไม่มีใน base table เลย)
3. **เติมสคีมา** — 17 คอลัมน์ทรัพย์ + 11 คอลัมน์ CRM + `lead_tags_ref` + 12 ตารางที่แอปต้องใช้ (activities/tasks/targets/contacts/leave/notifications/audit) + RBAC 5 ตาราง
4. **เปลี่ยนหลักคิดการมอบหมาย** — จาก "โซนตัดสิน" เป็น **"ทรัพย์ตัดสิน"** (`main_4.sale_id`) → โซนมีหลายเซลได้ (`zone_sales`) ลบ `zone.sale_id_assigned` ทิ้ง
5. **Auth** — `@supabase/ssr` + middleware + LoginForm จริง + `/account` เปลี่ยนรหัส + สิทธิ์มาจาก DB
6. **Import ชีท HR** — พนักงาน 9 · โซน 29 · ใบลา 20 · บทบาท
7. **สร้างบัญชี 9 บัญชี** + เปิดบังคับ login + ทดสอบด้วยเบราว์เซอร์จริง
8. **ปิดรูรั่วเงินเดือน/PII** ด้วย GRANT ระดับคอลัมน์ + view `v_employee_private`
9. **Import ชีทหลัก** — 511 ทรัพย์ · 953 ลีด · 308 โครงการ · 2,334 กิจกรรม (เจอชีทกรอกผิดช่อง 2 จุด แก้ระหว่าง import)
10. **เปลี่ยนวันที่ทั้งแอปเป็น DD/MM/YYYY** (ค.ศ.) · เพิ่ม Vercel MCP ใน `.mcp.json`

**บทเรียนที่ควรจำ:** เอกสารส่งมอบเขียนไว้ดีแต่ข้อมูลเก่า — ทุกครั้งที่จะเชื่ออะไรจากเอกสาร **ให้ยิงเช็คของจริงก่อน** (เช็คสคีมา / โปรไฟล์ CSV) เพราะรอบนี้ผิดทั้งขนาดข้อมูล ชนิดคอลัมน์ และเจ้าของทรัพย์

### ประวัติงาน (2026-07-07)
- อัป **Next.js 15.1.6 → 15.5.20** ปิดช่องโหว่ CVE-2025-66478
- แก้ปัญหา Vercel บล็อก deploy (commit author) → ตั้ง git identity เป็น hauslivingestate@gmail.com
- แก้ server-side crash (env var หายบน Vercel) → ใส่ Supabase config fallback ในโค้ด (build + รันจริงผ่าน `/`, `/listings` = 200)
