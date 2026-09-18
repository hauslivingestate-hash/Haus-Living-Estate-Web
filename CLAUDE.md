# CLAUDE.md — Haus Living Estate Database

> ไฟล์นี้สรุปงานทั้งหมดของโปรเจกต์ **อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง**
> ผู้ใช้สื่อสารเป็นภาษาไทย — ตอบเป็นไทย, โค้ด/ชื่อคอลัมน์เป็นอังกฤษ

## ภาพรวมโปรเจกต์
ฐานข้อมูล **Supabase (Postgres)** + เว็บแอป CRM (Next.js) สำหรับธุรกิจอสังหาฯ "Haus Living Estate"
ฝั่ง DB เป็น **ไฟล์ SQL + CSV** เอาไปรัน/import ใน Supabase เอง
เว็บแอปอยู่ใน `haus-crm/` — **เป็น git repo แยกต่างหาก + ถูก gitignore ใน repo แม่** (ดูหัวข้อ "เว็บแอป CRM" ท้ายไฟล์)

---

## 📌 สถานะปัจจุบัน — อ่านตรงนี้ก่อน (อัปเดต 2026-08-13)

**ระบบขึ้นของจริงแล้ว** ไม่ใช่เดโมอีกต่อไป — ข้อมูลจริงเข้าครบ + ต้อง login ถึงใช้ได้ + RLS ปิดครบแล้ว + **มี write path จุดแรกแล้ว** + **มีหน้าจัดการบัญชีผู้ใช้แล้ว**

> ✅ **2026-09-18: สลับ Supabase ไปโปรเจกต์สิงคโปร์ `mmsornnhtkvcjqsynxic` แล้ว** (haus-crm `848c91d`)
> `full_cutover.ps1` → `NONE - identical` (271 วิ) · `rls_test.sql` ตรงกับฐานเก่าทุกบรรทัด · `compare.ps1` รอบ 2 ก่อน push ก็ยัง identical (ไม่มีใครเขียนระหว่างย้าย) · bundle production มีแต่ ref ใหม่
> 🔴 **ฐานเก่า `jpufhxzvqfrdcblfmrmu` ห้ามแตะอีก** — migration/ข้อมูลที่ลงฐานเก่าหลังนี้จะหายไปกับฐานที่ไม่มีใครอ่าน · `.mcp.json` ทั้ง 2 ที่ชี้ ref ใหม่แล้ว ต้อง authorize ใหม่ที่ `/mcp` · `SUPABASE_SERVICE_ROLE_KEY` ใน `.env.local` เป็น `sb_secret_` แบบใหม่แล้ว
> ✅ 2026-09-18: ปิด "Allow new users to sign up" แล้ว (`/auth/v1/settings` → `disable_signup: true`) · production `/login` 200 + bundle มีแต่ ref ใหม่ · `haus-crm/.mcp.json` บน GitHub ชี้ ref ใหม่แล้ว
> ✅ 2026-09-18: Ben login production ผ่าน (Benz เข้าฐานใหม่จริง 17:28) · ลบ `haus-migration.env` + `%TEMP%\haus-migration-dump` แล้ว → **รัน `db/migrate_project/*` หรือ psql ตรงอีกต้องสร้างไฟล์ env ใหม่** (ขอรหัส DB จาก Ben)
> ⬜ ค้าง: บอกทีมกลับมาใช้งาน · Ben Poovaviranon ต้อง `git pull` + แก้ `.mcp.json` ของตัวเอง · ไม่ได้ตั้ง `OPENAI_API_KEY` (Ben: ไม่เป็นไร) · เก็บโปรเจกต์เก่าไว้ 1–2 สัปดาห์ · `import/run_import.py` ยังชี้ฐานเก่า (ไม่เร่ง)

| ด้าน | สถานะ |
|---|---|
| ข้อมูล | ✅ import จากชีทครบ + อัปเดตเพิ่ม 2026-08-26 และ 2026-09-18 — ทรัพย์ **568** · ลีด **1,181** · โครงการ **329** · เจ้าของ **500** · กิจกรรม **2,967** · Last Match **62** (มีราคา 40) · พนักงาน **10** · โซน **30** |
| Login | ✅ ใช้งานจริง — **9 บัญชี** (พนักงาน 8 + Admin) · บังคับ login แล้ว · มีหน้าเปลี่ยนรหัส `/account` · **CEO/HR สร้าง/รีเซ็ตรหัสให้คนอื่นได้แล้วที่ ตั้งค่า → บัญชีผู้ใช้** |
| สิทธิ์ | ✅ RBAC อยู่ใน DB — **36 สิทธิ์** · 8 บทบาท · ผูกกับพนักงานจริงแล้ว |
| DB | ✅ **~64 ตาราง · 5 view · 16 function** — ดูรายการเต็มใต้ 📋 คลังตารางปัจจุบัน · เงินเดือน/PII ล็อกแล้ว · ⚠️ **`db/supabase_full_setup.sql` ตกยุค ขาด 5 ตาราง** (ดูหัวข้อเดียวกัน) |
| ความปลอดภัย | ✅ **RLS Phase 4 ปิดครบแล้ว** — `demo_read_all` + anon ถูกถอนหมด (ดูรายละเอียดใต้ Phase 4) |
| ✅ การบันทึก | ✅ **Phase 5 ปิดครบ 6/6 แล้ว 2026-08-13** — ทุกปุ่ม save เขียน DB จริง · +ใบลา/ประวัติพนักงาน (2026-08-14) |

### 📋 คิวงาน ณ 2026-09-17 (เรียงตามลำดับที่ตกลงกับ Ben)
| # | งาน | สถานะ |
|---|---|---|
| 1 | **ย้าย Supabase — ส่วนเตรียมการ** (สคริปต์รองรับไฟล์ Storage + ประวัติ migration · ซ้อมผ่าน `NONE - identical`) | ✅ เสร็จ 2026-09-17 (`8a4774c`) |
| 2 | **นัด Ben Poovaviranon หยุด apply migration** ช่วงสลับ | ✅ ไม่มี migration ใหม่ตั้งแต่ 09-17 (ยังเป็น 99) |
| 3 | **บอกทีมหยุดบันทึกข้อมูล ~10 นาที** | ✅ ยืนยันด้วย `compare.ps1` ว่าไม่มีการเขียนระหว่างย้าย |
| 4 | **ตั้ง env ใน Vercel** 3 ตัวของโปรเจกต์ใหม่ | ✅ Ben ตั้งแล้ว 2026-09-18 · `OPENAI_API_KEY` ไม่ตั้ง (Ben: เป็นตัวแถม) |
| 5 | **สลับจริง** (`full_cutover.ps1` → แก้โค้ด 6 จุด → push → Ben เช็ค production) | ✅ สลับแล้ว 2026-09-18 (`848c91d`) · ⬜ รอ Ben login เช็ค |
| 6 | **อัปเดตข้อมูลจากชีทอีกรอบ** (ไฟล์ `import/18-09*.csv`) | ✅ ลงฐานใหม่แล้ว 2026-09-18 — ดู 🔖 2026-09-18 |

**ข้อ 6 — อ่านก่อนเริ่ม import รอบหน้า** (บทเรียนจากรอบ 2026-08-26 ซึ่งอยู่ในหัวข้อ 🔖 ของมันเอง):
- 🔴 **`Project ID` ในชีทไม่นิ่ง** เป็นสูตรอิงตำแหน่งแถว → **จับคู่โครงการด้วย `project_name_thai` เท่านั้น** ห้าม insert ทับด้วยเลขจากชีท (Listing ID / Lead ID นิ่ง ใช้ได้)
- 🔴 **ถ้า import ลีดเป็นก้อน ต้อง `alter table main_6_buyer_crm disable trigger trg_notify_lead_assigned;` ก่อน** ไม่งั้นยิงแจ้งเตือนพันกว่าใบ
- **ทางที่ Ben เลือกไว้เดิมคือ insert เฉพาะของใหม่ ไม่แตะของเดิม** เพราะพนักงานแก้ข้อมูลผ่านเว็บจริงมาตลอด
- ⚠️ **ทำก่อนหรือหลังสลับก็ได้ แต่ต้องรู้ว่าลงฐานไหน** — ลงก่อนสลับ = ฐานเก่า (สคริปต์ย้ายจะพาไปเอง ไม่ต้องทำซ้ำ) · ลงหลังสลับ = ฐานใหม่ · **ห้ามลงคร่อมช่วงสลับ**
- ⚠️ ชีทต้นทางเคยกรอกผิดช่องหลายจุด → **โปรไฟล์ข้อมูลก่อนเสมอ อย่าเชื่อหัวคอลัมน์**

### งานถัดไปตามลำดับ (ดูรายละเอียดเต็มที่ 🗺️ แผนเฟส ด้านล่าง)
1. ~~**Phase 5 (Write path)**~~ ✅ **เสร็จครบ 2026-08-13** — แก้ทรัพย์ · แก้ลีด/เปลี่ยนสเตจ · เพิ่มลีด · มอบหมายลีด · เพิ่มทรัพย์ · ติ๊กงาน `/today`
2. **Phase 6 (7/8)** — เหลือ **`/` แดชบอร์ด** (Ben สั่งพักไว้ก่อน 2026-08-14 — ดูสรุปทางเลือกใต้หัวข้อแดชบอร์ด) · **`/website`** (เป็นฟีเจอร์ Phase 8)
3. ~~หน้าตั้งค่าโซนยังเป็น 1 โซน 1 เซล~~ ✅ เสร็จ 2026-08-14 (`deca0f6`)
4. ~~หน้าจัดการบัญชีสำหรับ Admin~~ ✅ เสร็จ 2026-08-08 — ดู Phase 7

### 3 เรื่องที่ต้องรู้ก่อนแตะอะไร
1. **อย่าเชื่อตัวเลขใน `haus-crm/DATA_MODEL.md`** — ประเมินขนาดข้อมูลต่ำไป 3–8 เท่า และบอกว่า `Created By` เป็น Stone ทั้งหมด (ผิด กระจายครบ 6 คน)
2. **ชีทต้นทางกรอกผิดช่องหลายจุด** — ถ้าต้อง import อะไรเพิ่ม ให้โปรไฟล์ข้อมูลก่อนเสมอ อย่าเชื่อหัวคอลัมน์ (ดูรายละเอียดใต้หัวข้อ Import)
3. **การมอบหมายงานยึดที่ "ทรัพย์" ไม่ใช่ "โซน"** — `main_4.sale_id` คือตัวจริง โซนเป็นแค่ตัวสำรอง

### รอจากคน
- **HR**: `date_started` ของพนักงานทุกคน (ชีทไม่มี → ladder เซลใหม่ + โควตาลาปีแรกใช้ไม่ได้) · โควตาวันลาจริง (ที่ใส่ไว้เป็นขั้นต่ำตามกฎหมาย ซึ่งผิดแน่ เพราะ 5/8 คนใช้เกินแล้ว)
- **CEO**: ใครเป็นหัวหน้าทีม (ยังไม่มีใครถือ role `sales_leader`, ตาราง `teams` ว่าง) · แท็ก Lead จริง (ตอนนี้ seed ไว้ 4 อัน)
- ~~**Ben**: ปิด Vercel Deployment Protection~~ ✅ ไม่ค้างแล้ว — เปลี่ยนเป็น Standard Protection ตั้งแต่ 2026-08-03 (เช็คซ้ำ 2026-08-10: `haus-crm-iota.vercel.app/login` ตอบ 200 ไม่เด้ง SSO)
- ~~**Ben**: ตั้ง `SUPABASE_SERVICE_ROLE_KEY` ใน Vercel~~ ✅ เสร็จ 2026-08-10 (+ redeploy แล้ว — ดูรายละเอียดใต้หัวข้อหน้าจัดการบัญชี)

---

## โครงสร้างโฟลเดอร์ (จัดใหม่ 2026-08-03)
```
Haus-Web-Wp.Ben/
├── CLAUDE.md              ไฟล์นี้ — อ่านก่อนเริ่มงานทุกครั้ง
├── db/
│   ├── supabase_full_setup.sql   ไฟล์หลัก รันทีเดียวครบ (36 ตาราง + 4 view + 1 function)
│   ├── rls_policies.sql          RLS ทั้งระบบ (Phase 4) — รันหลัง full_setup + หลังมีตาราง RBAC
│   ├── migrate_project/          สคริปต์ย้าย Supabase โปรเจกต์ → โปรเจกต์ (2026-09-10) ดูหัวข้อ 🔖 2026-09-10
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
| **5** | **Write path — ต่อปุ่ม save ทุกหน้า** | ✅ **เสร็จครบ 6/6 (2026-08-07 → 2026-08-13)** |
| **6** | **เชื่อมหน้าที่ยังเป็นข้อมูลตัวอย่าง (~8 routes)** | 🟡 **7/8** — `/projects` `/last-match` `/contacts` (08-13) · `/leave` `/team` `/new-sales` + ตั้งค่า→โซน/Rank (08-14) |
| **7** | **งานแอดมิน/ops ที่ยังไม่มีที่ทำ** | 🟡 บางส่วน |
| **8** | **ฟีเจอร์แยก (มีเอกสารของตัวเอง)** | ⬜ ยังไม่เริ่ม |

### เฟส 5 — Write path (ต่อปุ่ม save) ✅ เสร็จครบ 6/6
**ทุกปุ่มบันทึกเคยเป็น stub** state อยู่ใน React Provider รีเฟรชแล้วหาย — **ข้อ 1 เสร็จ 2026-08-07 · ข้อ 2 เสร็จ 2026-08-08 · ข้อ 3-5 เสร็จ 2026-08-10/11 · ข้อ 6 เสร็จ 2026-08-13** (รายละเอียดที่ 🔖 ค้างอยู่ตรงนี้ ด้านบน) · **store in-memory ยุค design-first ตายหมดแล้ว** (`NewLeadsProvider` ลบทิ้งทั้งไฟล์)
- ✅ **ข่าวดี: policy ฝั่ง DB พร้อมแล้ว** — เฟส 4 เขียน insert/update/delete ครบทุกตาราง ต่อ write ได้เลยไม่โดน 403 (ยกเว้นเคสที่ต้องอ่านค่าที่ DB สร้างกลับมา ซึ่งต้องผ่าน RPC — `create_owner`, `create_lead`)
- ครบแล้ว: ~~แก้ทรัพย์ (`ListingEditSheet`)~~ ✅ → ~~แก้ลีด/เปลี่ยนสเตจ (`LeadEditSheet` + แท็ก + ข้อร้องเรียน)~~ ✅ → ~~เพิ่มลีด (`LeadIntakeFab`)~~ ✅ → ~~มอบหมายลีด (`/assign` + แมปชื่อ→รหัสอัตโนมัติ)~~ ✅ → ~~เพิ่มทรัพย์ (`ListingIntakeButton`)~~ ✅ → ~~ติ๊กงาน `/today` (เขียน `tasks` + `activities` + `targets` + `user_quick_actions`)~~ ✅
- ⚠️ **2 pattern ที่ต้องใช้กับ write path ทุกจุดต่อจากนี้** (เจอตอนข้อ 6): **ต้อง try/catch รอบ server action เสมอ** (reject ≠ `{ok:false}` — ถ้าไม่ catch จอจะโกหกว่าบันทึกแล้ว) · **ต้องคง busy ไว้จนกว่า `router.refresh()` จะลง** ด้วย `useTransition` (ไม่งั้นคลิกถัดไปทำงานกับ render เก่า)
- ทุกจุดต้องเขียน `audit_log` ด้วย (`changed_by` = ตัวเอง ไม่งั้น policy ปฏิเสธ) — pattern อยู่ใน [lib/mutations/listings.ts](haus-crm/lib/mutations/listings.ts) และ [lib/mutations/leads.ts](haus-crm/lib/mutations/leads.ts) แล้ว ก็อบโครงได้เลย
- ~~`main_6_buyer_crm.tag_id` มีคอลัมน์แล้วแต่แอปยังเก็บแท็กใน `NewLeadsProvider`~~ ✅ เขียนจริงแล้ว (ข้อ 2)

### เฟส 6 — เชื่อมหน้าที่ยังเป็นข้อมูลตัวอย่าง 🟡
เหลือ 2 หน้า: `/` แดชบอร์ด · `/website` (~~`/today`~~ ✅ พร้อม Phase 5 ข้อ 6 · ~~`/projects`~~ ~~`/last-match`~~ ~~`/contacts`~~ ✅ 08-13 · ~~`/leave`~~ ~~`/team`~~ ✅ 08-14) — ใช้ [lib/plan.ts](haus-crm/lib/plan.ts) หรือ [lib/queries.ts](haus-crm/lib/queries.ts) เป็นแม่แบบได้
- ⚠️ **RLS หลายตารางเป็น own-row → คอลัมน์ที่โชว์ค่าของ "คนอื่น" จะโกหกเงียบ ๆ** เจอมาแล้ว 3 ตาราง: `activities` · `user_roles` · `tasks`/`targets` — **แยกให้ออกระหว่าง "0" กับ "คุณไม่มีสิทธิ์เห็น"** ถ้าเห็นไม่ได้ให้เป็น `null` → "—" หรือซ่อนทั้งคอลัมน์ อย่าปล่อยเป็น 0/ว่าง
- **`/` แดชบอร์ด — Ben สั่งพักไว้ก่อน (2026-08-14)** [app/(app)/page.tsx](haus-crm/app/(app)/page.tsx) เป็นหน้า "เร็วๆ นี้" · `components/dashboard/*` + `lib/dashboard.ts` ยังอยู่ครบ
  - 🔴 **ตัวขวางจริงคือ ไม่มีตัวเลขรายได้ใน Supabase เลย** — `main_7_last_match.last_match_price` **ว่าง 0 จาก 56 แถว** · แดชบอร์ดตัวนี้พอร์ตมาจาก HAUS V2 โดยมี "รายได้" เป็นแกนกลาง ถ้าเปิดตอนนี้ **5 จาก 6 บล็อกในหน้าภาพรวมเป็น ฿0**
  - ✅ **อัปเดต 2026-08-24: ตัวเลขมีอยู่แล้วในชีท** (`_raw_close_case` → `summary_revenue`) แค่ไม่เคยถูก import → **ไม่ต้องกรอกมือ 56 ดีล** ดูรายละเอียด + คำเตือนเรื่อง "รายได้ = คอมมิชชั่น ไม่ใช่ราคาบ้าน" ที่หัวข้อ 🔖 อ่านก่อน (2026-08-24) ด้านบน
  - เป้าทีม (`teams.revenue_goal`) กับเป้า KPI (`targets`) ก็ว่างทั้งคู่
  - **สิ่งที่มีครบพอจะทำแดชบอร์ดได้ทันที**: กิจกรรม 2,334 แถว (10 เดือน) · ลีดใหม่รายเดือน 953/953 · ไปป์ไลน์ 835 (Call 521 → Show 149 → Win 21) · ทรัพย์ + ราคาประกาศ 491/511 · จำนวนดีลปิด 50
  - **3 ทางที่กางให้ Ben ดูแล้ว**: (ก) ทำใหม่ให้แกนเป็นกิจกรรม/ไปป์ไลน์แทนรายได้ (ข) กรอกราคาปิด 56 ดีลก่อนแล้วเปิดของเดิม (ค) เปิดของเดิมเลยแล้วยอมให้ว่าง — **Ben เลือกพักไว้ก่อน**
  - 🆕 **ทางที่ 4 (เพิ่ง 2026-08-24)**: import จากชีทที่แดชบอร์ดตัวจริงใช้อยู่ แล้วทำ view ตาม `summary_*` ทั้ง 12 ตัว — **ยังไม่ได้ตัดสิน ต้องถาม Ben ว่าจะให้ haus-crm แทนที่ตัวเดิม หรือให้ 2 ตัวอยู่คู่กัน**
  - ⚠️ ไม่ว่าจะเลือกทางไหน `activities` เป็น own-row → **แดชบอร์ด "ทีม" จะเห็นแค่ของตัวเอง** ต้องทำ view `security definer` เพิ่ม
- ~~**`/new-sales` ติดที่ `date_started`**~~ ✅ เสร็จ 2026-08-14
- **ตารางปลายทางมีครบแล้วทุกตัว** (สร้างไว้ 2026-08-03) เหลือแค่เปลี่ยน `lib/*.ts` ให้ query จริงผ่าน `lib/supabase/server.ts`
- ⚠️ **หน้าที่เป็น "ของส่วนตัว" ต้องกรอง `employee_code` เองในโค้ด อย่าพึ่ง RLS** — policy หลายตัวเปิดให้ `roles.manage`/`performance.view_team` ด้วย (เจอจริงตอนต่อ `/today`)
- `TODAY` ใน `lib/momentum.ts` (`@deprecated`) ยังมี 8 ไฟล์อ้างอยู่ — ลบได้เมื่อหน้า leave/new-sales/notifications/probation ต่อ DB เสร็จ
- ~~`/contacts` ต้อง import + dedupe~~ ✅ **ไม่ import แล้ว** — อ่านสดจาก `main_2_owner` + `main_6_buyer_crm` (Ben ตัดสินใจ 2026-08-13 ดูด้านบน)
- ~~`lib/zones.ts` + `ZonesAdmin` ยังเป็น 1 โซน 1 เซล~~ ✅ เสร็จ 2026-08-14

### เฟส 7 — แอดมิน/ops 🟡
- [x] **หน้าจัดการบัญชี** (สร้าง/รีเซ็ตรหัสให้คนอื่น) — เสร็จ 2026-08-08 ที่ `/settings` → "บัญชีผู้ใช้" ([AccountsManager](haus-crm/components/AccountsManager.tsx) + [lib/mutations/accounts.ts](haus-crm/lib/mutations/accounts.ts) + [lib/supabase/admin.ts](haus-crm/lib/supabase/admin.ts)) gate ด้วย permission ใหม่ `people.manage_accounts` (**CEO / HR / system_admin เท่านั้น** — Ben ตัดสินใจเจาะจงว่าไม่ใช่ `admin` business role และไม่ใช่ `people.manage` เดิมที่กว้างกว่า) — ทดสอบจริงผ่าน `browser-automation` แล้ว: สร้างบัญชีให้ Pai + รีเซ็ตรหัส Mhow ผ่านหน้านี้ ยืนยัน login ได้จริง แล้วลบ/คืนค่าทดสอบทั้งหมด (ลบ auth user ของ Pai ผ่าน Admin REST ตรง คืนอีเมลเดิมจากไฟล์ import, รีเซ็ตรหัส Mhow กลับเป็นของเดิม) — ✅ **ตั้ง `SUPABASE_SERVICE_ROLE_KEY` ใน Vercel + redeploy แล้ว 2026-08-10 · ใช้งานได้จริงบน production แล้ว** (ดูวิธียืนยันใต้หัวข้อวันที่ 2026-08-10)
- **`teams` ยังว่าง + ไม่มีใครเป็น `sales_leader`** — รอ CEO กำหนดหัวหน้าทีม (กระทบ `visible_employee_codes()` → ตอนนี้ "ทีม" = ตัวเองคนเดียว)
- **`date_started` ว่างทุกคน** (ชีทไม่มี) — กระทบ ladder เซลใหม่ + โควตาลาปีแรก ต้องกรอกในเว็บ
- ทิศ/ตำแหน่ง/อายุ/ส่วนกลาง ที่ import ปล่อยว่างไว้ (ชีทกรอกเลื่อนช่อง) รอกรอกใหม่ในเว็บ

### เฟส 8 — ฟีเจอร์แยก (มีเอกสารของตัวเองใน `haus-crm/*_FEATURE.md`) ⬜
checklist ทรัพย์ A-List/Exclusive · เทมเพลตคำโฆษณา · ladder เซลใหม่ (probation) · เว็บพอร์ทัลลูกค้า

---

## 🔖 อ่านก่อน (2026-09-18) — import ชีทรอบ 3 ลง**ฐานใหม่ (สิงคโปร์)** แล้ว

ไฟล์ `import/18-09Database Sheets - *.csv` 5 ไฟล์ · สคริปต์ [import/build_0918.py](import/build_0918.py) (diff กับ DB สด → SQL ก้อนเดียวใน transaction · ซ้อมแบบ rollback ก่อนรันจริง · รันผ่าน psql ด้วย `db/migrate_project/env.ps1` → `Use-New`)
- **`buyer_focus` = `Active Lead` ชีทเดียวกัน** (หัว 24 ช่องตรงกันเป๊ะ · ลีดทุกตัวใน buyer_focus อยู่ใน Active Lead ใหม่ครบ ที่ต่างคือค่าที่อัปเดตตามเวลา) → **ใช้แค่ `Active Lead` ต่อไป** · ยังเหลื่อม 1 ช่อง (คอลัมน์ 2–7) เหมือนเดิม
- ก่อนลง: **ตั้งแต่ 26 ส.ค. ยังไม่มีใครสร้างลีด/ทรัพย์/โครงการ/Last Match ผ่านเว็บเลย** และกิจกรรมใน DB ไม่มีแถวไหนที่ชีทไม่มี → insert-only ไม่ชนอะไร

| ตาราง | +เพิ่ม | หมายเหตุ |
|---|---|---|
| โครงการ | +6 | `PROJECT-340..345` (จับคู่ด้วยชื่อไทย) · 17 แถวในชีทไม่มี Project ID = ข้ามเหมือน 2 รอบก่อน |
| เจ้าของ | +19 | จาก 21 ชื่อ มีอยู่แล้ว 2 |
| ทรัพย์ | +24 | `HPHU114` ไม่มีโครงการ (หมู่บ้านบุษบา ไม่มี Project ID ในชีท) → **ชื่อทรัพย์ว่างในเว็บ** |
| ลีด | +123 | `L26-1101..1223` · `L26-1181`/`1182` ใช้ id ซ้ำกับคนละคน → แถวที่ 2 เป็น `-2` · ข้าม `LEAD-01` (แถวทดสอบ BEN001) · ปิด `trg_notify_lead_assigned` ระหว่างลง (แจ้งเตือน 484 เท่าเดิม) |
| Last Match | +6 | Q-17..20 · Mhow-25/26 · ข้าม Test 14 + แถว Stone ไม่มี ID 12 (ข้อมูลเลื่อนช่อง) |
| กิจกรรม | +321 | ส.ค. 65 · ก.ย. 256 · แก้พิมพ์ผิด `Reel`→Reels `Viait`→Owner Visit · ข้าม 8 แถวที่ Action เป็นข้อความมั่ว |

- 🔴 **ชีท All Listings รอบนี้เลื่อนช่อง** — มีคอลัมน์ข้อมูลว่างเกินมา 1 ช่องหลัง `Bath` แต่หัวไม่มี → ตั้งแต่ ไร่ ถึงท้ายแถวอยู่ขวาหัวของตัวเอง 1 ช่อง (ราคาไปอยู่ "Rental Price" · เซลไปอยู่ "Days on Market" · Marketing Report หลุดท้ายแถว) · สคริปต์จัดใหม่ + **assert ว่าต้องเลื่อนแบบนี้เท่านั้น** ถ้าชีทถูกแก้แล้วจะหยุดเอง ไม่เลื่อนกลับผิดทาง
- 🐛 **เจอสาเหตุที่ `main_7_last_match.last_match_price` ว่างมาตลอด**: ชีทเขียน `฿3,600,000` แล้ว `num()` ของ `run_import.py` อ่าน ฿ ไม่ออก → ทิ้งเป็น null ทั้ง 56 แถว · **เติมย้อนหลังเฉพาะแถวที่ยังว่าง 34 แถว** (อีก 21 ชีทก็ไม่มีราคา · 1 แถวมีคนกรอกผ่านเว็บแล้ว ไม่ทับ) → มีราคา 40/62 · ⚠️ นี่คือ "ราคาบ้านที่ปิด" ไม่ใช่คอมมิชชั่น (ดู 🔖 2026-08-24)
- ⚠️ **id ลีดจะชนกันได้ในอนาคต**: ชีทออกเลขต่อที่ `L26-1224` · `create_lead` ในเว็บก็ออก max+1 = `L26-1224` เหมือนกัน → ถ้ามีคนเพิ่มลีดผ่านเว็บก่อน import รอบหน้า ลีดจากชีทกับจากเว็บจะได้ id เดียวกัน (สคริปต์เทียบด้วย id จะคิดว่าเป็นคนเดียวกันแล้วข้าม)
  - ✍️ **Ben (2026-09-18): ปล่อยไว้** — ช่วงนี้ทีมยังกรอกลีดในชีท · พอย้ายไปใช้เว็บเต็มตัวจะเลิกใช้ชีท ปัญหาหายเอง
  - ➡️ **import รอบถัดไปต้องเช็คก่อนเสมอ**: มีลีดที่สร้างผ่านเว็บ (`created_at` หลังรอบล่าสุด) ไหม · ถ้ามีและรหัสชนกับชีท → เทียบชื่อ+เบอร์ แล้วออกรหัสใหม่ให้ตัวจากชีท อย่าข้ามทิ้ง

## 🔖 อ่านก่อน (2026-09-10) — ย้าย Supabase ไปโปรเจกต์ใหม่ · ซ้อมผ่าน · **ยังไม่สลับ**

Ben ตัดสินใจสร้างโปรเจกต์ใหม่แทนการย้ายของเดิม (Supabase ย้าย region ของโปรเจกต์ที่มีอยู่ไม่ได้)

| | เก่า (ยังใช้งานอยู่) | ใหม่ |
|---|---|---|
| project ref | `jpufhxzvqfrdcblfmrmu` | `mmsornnhtkvcjqsynxic` |
| region | ap-southeast-2 **ซิดนีย์** | ap-southeast-1 **สิงคโปร์** |
| URL | `https://jpufhxzvqfrdcblfmrmu.supabase.co` | `https://mmsornnhtkvcjqsynxic.supabase.co` |
| Postgres / auth schema | 17.6 / 77 migration (`20260625000000`) | **ตรงกันเป๊ะ** → ย้ายบัญชีตรงๆ ได้ |

### ของที่ต้องย้าย (สำรวจแล้ว)
ฐานข้อมูล 20 MB (public 6 MB) · บัญชี 9 · **รูปใน Storage = 0** (มีแค่ bucket `listing-photos` + policy 4 ตัว) · pg_cron 1 งาน · event trigger `ensure_rls` 1 ตัว · **ไม่มี** Edge Function / Vault secret / Realtime table / custom role · ทุก object ใน public เป็นของ `postgres` (ไม่มีของ `supabase_admin` ติดมา)
- **n8n ไม่ต้องแก้แล้ว** — Ben บอกจะเลิกใช้ เปลี่ยนไปใช้อย่างอื่นแทน
- session/refresh token **ไม่ย้าย** → ทุกคนต้อง login ใหม่ แต่**รหัสผ่านเดิมใช้ได้** (hash ย้ายมาตรงตัว)

### สคริปต์: [db/migrate_project/](db/migrate_project/) — รันซ้ำได้ ไม่มีรหัสผ่านในไฟล์
```
powershell -File db\migrate_project\full_cutover.ps1   # ย้ายทั้งหมด + เทียบ → บรรทัดท้ายต้องเป็น "NONE - identical"
powershell -File db\migrate_project\compare.ps1        # เทียบอย่างเดียว (อ่านทั้ง 2 ฝั่ง ไม่เขียน)
```
| ไฟล์ | หน้าที่ |
|---|---|
| `env.ps1` | อ่าน `C:\Users\thinn\haus-migration.env` (**นอก repo** — `OLD_DB_URL` `NEW_DB_URL` `NEW_PUBLISHABLE_KEY` `NEW_SECRET_KEY`) · ส่งรหัสผ่านทาง `PG*` env ไม่ใช่ command line |
| `pre.sql` / `post.sql` | ปิด/คืน default privileges รอบการ restore (ดูกับดักข้อ 1) + ถอด storage policy/event trigger ที่ขวาง `--clean` |
| `gen_extras.sql` | สร้าง DDL ของที่อยู่นอก `public` จากโปรเจกต์เก่า: storage policy 4 · cron · event trigger |
| `final_reset.sql` | ล้างตาราง public + `auth.users`/`identities` ในโปรเจกต์ใหม่ก่อนลงข้อมูล |
| `fingerprint.sql` + `compare.ps1` | พิมพ์ "ข้อเท็จจริง" ~1,500 บรรทัดจากแต่ละฝั่งแล้ว diff: จำนวนแถว **+ md5 ของเนื้อหา** 70 ตาราง · hash รหัสผ่าน · สิทธิ์ระดับตาราง/คอลัมน์/function · policy · RLS · trigger · constraint · index · view · sequence · default ACL · cron · event trigger |
| `rls_test.sql` | จำลอง login 3 persona แบบ Phase 4 (rollback ทุกบล็อก) |

- เครื่องมือ `pg_dump`/`psql` 17.6 แบบ portable อยู่ที่ `%TEMP%\haus-pg17` (ไม่ได้ติดตั้ง · หายเมื่อไหร่ `env.ps1` บอกวิธีโหลดใหม่) · **เครื่องนี้ไม่มี pg_dump/psql/Docker/Supabase CLI มาก่อน**
- dump ลง `%TEMP%\haus-migration-dump` — **นอก OneDrive โดยตั้งใจ** เพราะมีเงินเดือน + hash รหัสผ่าน · **ลบทิ้งหลังย้ายเสร็จ**

### 🔴 กับดักที่เจอ (จำไว้ใช้ทุกครั้งที่ย้าย/restore Supabase)
1. 🔴🔴 **โปรเจกต์ใหม่แจกสิทธิ์ ALL ให้ `anon`/`authenticated` อัตโนมัติทุก object ที่ `postgres` สร้างใน public** (default privileges) แต่ `pg_dump` พิมพ์เฉพาะ grant ที่ต่างจาก "เจ้าของคนเดียว" → **restore ตรงๆ = revoke ทั้งหมดของ Phase 4 หายเงียบ รวมถึง SELECT คอลัมน์เงินเดือน/PII ใน `main_1_hr`** · แก้: `pre.sql` ถอน default privileges ก่อน restore → `post.sql` คืนให้หลังลงข้อมูล (ให้ตรงกับโปรเจกต์เก่า ซึ่งยังแจกอัตโนมัติอยู่เหมือนกัน)
2. **ต้องลงข้อมูลด้วย `session_replication_role = replica`** (ปิด trigger) — ไม่งั้นออกรหัสทรัพย์/ลีดใหม่ทับ · `trg_notify_lead_assigned` ยิงแจ้งเตือนพันใบ · support_log/A List ซ้ำ · และยังแก้ปัญหา FK วน `main_1_hr` ↔ `teams` ที่ `pg_dump --data-only` เตือนไว้ด้วย
3. **ของนอก `public` ไม่ติดมากับ `pg_dump -n public`**: storage policy 4 ตัว · cron `daily-notifications` · event trigger `ensure_rls` (ตัวที่เปิด RLS ให้ตารางใหม่อัตโนมัติ) — และ policy/event trigger พวกนี้ **อ้าง `public.has_perm()` / `rls_auto_enable()`** จึงขวาง `pg_restore --clean` ไม่ให้ drop function → ต้องถอดก่อนแล้วสร้างใหม่ทีหลัง
4. **ต่อได้ทาง Session pooler (port 5432) เท่านั้น** — Direct connection เป็น IPv6 ล้วน **เครื่องนี้ไม่มี IPv6** (ทดสอบแล้ว) · Transaction pooler (6543) ใช้กับ `pg_dump` ไม่ได้ · ⚠️ **รหัสผิดหลายครั้ง Supabase แบน IP** → `env.ps1` ปฏิเสธเองถ้ายังเป็น `[YOUR-PASSWORD]` (ครั้งแรก Ben วางลิงก์มาโดยยังไม่แทนรหัส)
5. **secret key (`sb_secret_`) โดน 401 ถ้า User-Agent ดูเหมือนเบราว์เซอร์** — PowerShell ส่ง `Mozilla/...` มาเอง · ไม่ใช่ key ผิด ใส่ `-UserAgent` อื่นก็ผ่าน
6. **ไฟล์รูปไม่ติดมากับ dump** — วันนี้ยังไม่มีรูปสักรูป · สคริปต์**หยุดเอง**ถ้าโปรเจกต์เก่ามีรูปแล้ว (ต้องก๊อปไฟล์แยกก่อน)
7. ไฟล์ `.sql` ที่ PowerShell 5.1 เขียนมี BOM → psql อ่านบรรทัดแรกพัง · สคริปต์เขียนแบบ UTF-8 ไม่มี BOM

### ผลซ้อม (2 รอบ · รอบ 2 คือ `full_cutover.ps1` ตัวจริง ใช้เวลา **~4 นาที**)
- `compare.ps1` → **NONE - identical** ทุกหมวด (ตาราง 70 · policy 272 · สิทธิ์ 89 relation + 29 คอลัมน์ · function 24 · trigger 11 · constraint 204 · index 95 · บัญชี 9)
- `rls_test.sql` ตรงกันทั้ง 2 ฝั่งทุกบรรทัด:

| persona | ทรัพย์ | ลีด | last match | กิจกรรม | เจ้าของ | เห็นเงินเดือน | สิทธิ์ |
|---|---|---|---|---|---|---|---|
| E-001 (Admin) | 544 | 1,058 | 56 | 2,646 | 481 | 4 | 36 |
| S-003 (Q, agent) | 544 | 189 (ของคนอื่น **0**) | 16 | 529 | 95 | **0** | 13 |
| SP-002 (Pui, marketing) | 544 | 0 | 0 | 0 | 0 | 0 | 7 |

  + agent แย่งลีด/ลบทรัพย์ = **0 แถว** · `authenticated` อ่าน `main_1_hr.salary` ตรง = **permission denied** · `anon` = permission denied ทุกตาราง/function
- API จริงของโปรเจกต์ใหม่: anon ได้ 42501 · secret key เห็นทรัพย์ 544 / ลีด 1,058 · `v_main_listing` คืนชื่อไทยถูก · Auth เห็น 9 บัญชี confirm ครบ · Storage มี bucket
- ตั้งค่า Auth ฝั่งสาธารณะ (`/auth/v1/settings`) ตรงกันทั้ง 2 ฝั่ง

### 🔴 ตัวขวาง: มีคนพัฒนาบนโปรเจกต์เก่าอยู่ **ระหว่างที่ซ้อม**
- วันเดียวกันมี migration เข้าโปรเจกต์เก่า 6 ตัว (16:03–19:00 ตัวล่าสุด **20 วินาทีก่อน**สคริปต์รัน) และหลังจากนั้นยังมีเพิ่มอีก: ตาราง `lead_stage_event` · `dash_activity_counts` · `dash_revenue_monthly` · `dash_stage_moves` · `log_lead_stage_change` + trigger · policy `targets` เปลี่ยน · `lead_status.counts_as_revenue`
- GitHub `haus-crm` มี commit `97b8980` (2026-09-10 18:14, `benhoenig@gmail.com`) ที่**เครื่องนี้ยังไม่ได้ pull**
- → **โปรเจกต์ใหม่ตอนนี้ตกยุคแล้ว (ตั้งใจ)** `full_cutover.ps1` สร้างใหม่จาก snapshot สดทุกครั้ง แต่ **session นั้นต้องหยุดระหว่างสลับ** และหลังสลับต้องแก้ `project_ref` ใน `.mcp.json` ของตัวเอง + authorize ใหม่ที่ `/mcp`

### 🔄 อัปเดต 2026-09-17: ซ้อมใหม่กับสภาพล่าสุด + สคริปต์รองรับไฟล์และประวัติ migration แล้ว
Ben Poovaviranon พัฒนาบนฐานเก่าต่อทั้งสัปดาห์ (10→17 ก.ย. **22 commit**) — ยกเครื่องหน้าตา (ธีมส้ม/กรมท่า · โลโก้ · ⌘K) · แดชบอร์ดทีม + เป้ารายได้ · **ปิดดีล = เคส + ทะเบียนรายได้** · **ตัวอ่านลีดด้วย OpenAI ของจริง** · **เริ่ม track migration ลง git** (`haus-crm/supabase/migrations` 99 ไฟล์)

| | ตอนซ้อม 09-10 | ตอนนี้ 09-17 |
|---|---|---|
| ตาราง · view · function | 68 · 5 · 24 | **76** · 5 · **38** |
| policy · index · constraint | 272 · 95 · 204 | **302** · 117 · 248 |
| migration ใน DB | 60 | **99** |
| Storage | bucket 1 · **ไฟล์ 0** | bucket 2 (+`avatars`) · **ไฟล์ 8** (รูปโปรไฟล์ 48 KB) |

**3 เรื่องที่ต้องแก้ในสคริปต์ (แก้แล้วทั้งหมด):**
1. 🔴 **ไฟล์ใน Storage** — เดิมสคริปต์**หยุดทันที**ถ้าเจอไฟล์ เพราะ `pg_dump` ก๊อปแต่แถวไม่ก๊อปไฟล์ → เพิ่ม [copy_storage.ps1](db/migrate_project/copy_storage.ps1): สร้าง bucket ผ่าน storage API (สคริปต์เดิม**ไม่เคยสร้าง bucket เลย** ตอนซ้อมสร้างมือ) · โหลดไฟล์จาก URL สาธารณะของฝั่งเก่าแล้วอัปเข้าฝั่งใหม่ · ลบไฟล์ที่ฝั่งใหม่มีเกิน · **ไม่ก๊อปแถว `storage.objects`** ปล่อยให้ storage สร้างเอง (id/เวลาจึงเป็นของใหม่โดยตั้งใจ → `fingerprint.sql` เทียบ `bucket/ชื่อ/ขนาด` แทนทั้งแถว)
2. 🔴 **ประวัติ migration** (`supabase_migrations.schema_migrations` 99 แถว) อยู่คนละ schema จึงไม่ติดมากับ dump — **ถ้าไม่ก๊อป `supabase db push` ครั้งถัดไปจะไล่รันซ้ำทั้ง 99 ไฟล์**
3. 🔴 **`pg_restore --clean` ใช้ไม่ได้อีกต่อไป** — มันสั่ง `DROP POLICY IF EXISTS ... ON <ตาราง>` ให้ทุก policy ในไฟล์ dump และ `IF EXISTS` ของ policy **ไม่ครอบถึงตารางที่ปลายทางไม่เคยมี** → ตารางใหม่ตัวแรก (`team_revenue_targets`) ทำ restore ล้มทั้งก้อน · เปลี่ยนเป็น `pre.sql` ล้าง `public` ให้เกลี้ยงก่อน แล้ว restore ตรงๆ
- ⚠️ **เครื่องมือย้ายไปอยู่ `C:\Users\thinn\pgtools\pg17`** — ของเดิมอยู่ `%TEMP%` แล้ว **Windows ล้างไฟล์ที่ไม่ได้แตะมาสัปดาห์นึงทิ้ง เหลือ 10 จาก 68 ไฟล์ `pg_restore` หายกลางคัน**

**ผลซ้อมรอบ 2026-09-17 (ใช้เวลา ~4.5 นาที)**: `compare.ps1` → **NONE - identical** ทุกหมวด (76 ตาราง · 302 policy · 38 function · 117 index · 248 constraint · 37 คอลัมน์ที่คุมสิทธิ์ · **bucket 2 · ไฟล์ 8 · ประวัติ migration**) · `rls_test.sql` ตรงกับฝั่งเก่าทุกบรรทัด (Admin สิทธิ์ 38 · Q เห็นลีดตัวเอง 189 ของคนอื่น 0 · Pui 0 · แย่งลีด/ลบทรัพย์ 0 แถว · anon ถูกปฏิเสธหมด)

**เพิ่มเข้ารายการตอนสลับ**: `haus-crm/scripts/import-avatars.mjs` และ **`haus-crm/.mcp.json`** (ไฟล์ใหม่ของสัปดาห์นี้ ฝัง ref เก่าไว้ทั้งคู่) → จุดที่ต้องแก้ URL กลายเป็น **6 จุด** · และมี env ตัวใหม่ **`OPENAI_API_KEY`** ที่ต้องตั้งใน Vercel ด้วย ไม่งั้นฟีเจอร์ AI อ่านข้อความจะขึ้นว่า "ยังไม่ได้ตั้งค่า AI"

### ✍️ Ben (2026-09-10): **"ยังสลับไม่ได้ — เดี๋ยวจะมีคนมาต่องาน"**
คนที่มารับช่วงต่อ อ่านตรงนี้ก่อน:
- **อย่าเพิ่งสลับเอง** จนกว่า Ben จะสั่ง + เคลียร์ได้แล้วว่าใครทำ migration บนโปรเจกต์เก่าอยู่
- โปรเจกต์ใหม่มีข้อมูล**ซ้อมไว้แต่ตกยุค** ไม่ต้องไปแก้อะไรในนั้น — `full_cutover.ps1` ล้างแล้วสร้างใหม่ทั้งหมดอยู่แล้ว
- **ถ้าทำต่อจากเครื่องอื่น** ต้องมี 2 อย่างที่อยู่นอก repo: ไฟล์ `C:\Users\thinn\haus-migration.env` (ขอค่าจาก Ben — มีรหัสผ่าน DB ทั้ง 2 โปรเจกต์ + key ใหม่ · ถ้า path ต่างให้แก้ใน `env.ps1`) และ `pg_dump`/`psql` 17 (`env.ps1` บอกวิธีโหลด)
- ระหว่างนี้งานพัฒนาทุกอย่าง**ยังทำบนโปรเจกต์เก่าได้ตามปกติ** — ไม่ต้องทำซ้ำในโปรเจกต์ใหม่ เพราะตอนสลับจะดึงไปทั้งหมด

### ขั้นตอนสลับจริง (~10 นาที) — **ยังไม่ได้ทำ รอ Ben สั่ง**
1. **Ben**: ตั้ง Vercel env 3 ตัว → `NEXT_PUBLIC_SUPABASE_URL` · `NEXT_PUBLIC_SUPABASE_ANON_KEY` · `SUPABASE_SERVICE_ROLE_KEY` (ค่าอยู่ใน `haus-migration.env`) — ไม่รู้ว่าตอนนี้ตั้งไว้ไหม (Vercel MCP ไม่มีเครื่องมืออ่าน/ตั้ง env) ถ้าตั้งไว้มันจะ override ค่าสำรองในโค้ด
2. **Ben**: บอกทีมหยุดบันทึก + session ที่ทำ migration หยุด
3. `full_cutover.ps1` → ต้องได้ `NONE - identical` (ไม่ได้ = หยุด) → รัน `rls_test.sql` ฝั่งใหม่
4. `git pull` ใน `haus-crm` ก่อน แล้วแก้ **6 จุด**: [haus-crm/lib/supabaseConfig.ts](haus-crm/lib/supabaseConfig.ts) (URL + publishable key สำรอง) · [haus-crm/next.config.mjs](haus-crm/next.config.mjs) (host รูป) · `haus-crm/scripts/import-avatars.mjs` · `haus-crm/.mcp.json` · `haus-crm/.env.local` (รวม `SUPABASE_SERVICE_ROLE_KEY` ที่ยังเป็น JWT แบบเก่า) · [.mcp.json](.mcp.json) ของ repo แม่ · (ไม่เร่ง) `import/run_import.py` → commit ด้วย `hauslivingestate@gmail.com` → push → Vercel deploy
5. **Ben**: login เช็ค production แล้วปล่อยทีม

**หลังสลับ**: ลบ `C:\Users\thinn\haus-migration.env` + `%TEMP%\haus-migration-dump` · เก็บโปรเจกต์เก่าไว้ 1–2 สัปดาห์ (cron ของเก่ายังเขียนแจ้งเตือนลงฐานเก่าต่อ ไม่มีผลอะไร หยุดทีหลังได้)
- 💡 **แนะนำ**: ปิด "Allow new users to sign up" ในโปรเจกต์ใหม่ (Authentication → Sign In / Providers) — **ของเก่าก็เปิดอยู่** (`disable_signup=false`) ใครก็สมัครผ่าน API ได้ ไม่ได้สิทธิ์อะไร (ไม่มีแถวพนักงาน = RLS ปฏิเสธหมด) แต่ไม่มีเหตุผลต้องเปิด เพราะบัญชีสร้างจากหน้าแอดมิน (admin API ยังใช้ได้ตอนปิด)

---

## 🔖 อ่านก่อน (2026-08-26) — เพิ่มข้อมูลใหม่จากชีท 4 ไฟล์ (`Action` · `Active Lead` · `All Listings` · `Project`)

Ben ส่ง export ใหม่ 4 ไฟล์มาวางใน `import/` (`Database Sheets - Action.csv` · `Active Lead.csv` · `All Listings.csv` · `Project.csv`) — **`Active Lead.csv` แทน `buyer_focus.csv` เดิม** (โครงสร้างคอลัมน์เหมือนกันเป๊ะ รวมถึงบั๊กคอลัมน์เหลื่อม 1 ช่องแบบเดิม)

### 🔴 พบก่อนเขียนอะไรทั้งสิ้น: `Project ID` ในชีท **ไม่นิ่ง**
เทียบ DB เดิมกับชีทใหม่ด้วย `project_id` ตรงๆ แล้วพบว่าโครงการเดิมขยับเลข — ยืนยันด้วยชื่อจริง เช่น "เซนโทร พระราม2-พุทธบูชา" ใน DB คือ `PROJECT-049` แต่ชีทใหม่ให้เป็น `PROJECT-050` (ทุกโครงการหลังจากจุดที่มีการแทรก/ลบแถวในชีทจะขยับตาม — เป็นสูตรอิงตำแหน่งแถว ไม่ใช่ ID คงที่)
→ **ห้ามใช้ `project_id` จากชีทมาจับคู่/insert ทับ DB เด็ดขาด** ต้องจับคู่ด้วย **`project_name_thai`** แทน (วิธีเดียวกับที่ `run_import.py` ใช้จับคู่ listing→project ตั้งแต่แรก) — ยืนยันแล้วว่า Listing ID กับ Lead ID **นิ่งจริง** ไม่มีปัญหานี้ (ของ DB เดิมทุกใบยังมี base id อยู่ในชีทใหม่ครบ 100%)

### ทางที่เลือก (Ben ยืนยัน): **insert เฉพาะของใหม่ ไม่แตะของเดิม**
เทียบแล้วพบว่าเป็นข้อมูลเพิ่มล้วนๆ ไม่มีอะไรหายไปจากชีทเลยสักตัว — แต่ของที่ "มีอยู่แล้วทั้ง 2 ฝั่ง" (โครงการ 292 ชื่อ / ทรัพย์ 509 / ลีด ~938) **ไม่ถูกแตะ** เพราะพนักงานแก้ข้อมูลผ่านเว็บแอปจริงมาตั้งแต่ 3 ส.ค. แล้ว ถ้าเอาค่าจากชีททับอาจไปลบงานที่เพิ่งทำในเว็บ (pipeline_stage, ราคา, ปิดดีล ฯลฯ) — เก็บไว้เป็นตัวเลือก "sync เต็มรูปแบบ" ถ้า Ben ต้องการภายหลัง

| ตาราง | ก่อน | หลัง | +เพิ่ม |
|---|---|---|---|
| `main_3_property_detail` | 308 | 323 | **+15** โครงการใหม่ (mint id ใหม่ `PROJECT-325..339` เอง ไม่ใช้เลขจากชีท) |
| `main_2_owner` | 454 | 481 | **+27** เจ้าของใหม่ (เช็คซ้ำด้วยชื่อ+เบอร์ก่อน insert) |
| `main_4_listing_database` | 511 | 544 | **+33** ทรัพย์ใหม่ |
| `main_6_buyer_crm` | 953 | 1,062 | **+109** ลีดใหม่ (`L26-990` ถึง `L26-1100`) |
| `activities` | 2,334 | 2,646 | **+312** แถว (ทั้งหมดอยู่ในเดือน ส.ค. 2026 — หลัง import ครั้งก่อน 3 ส.ค.) |

**วิธีตรวจ diff**: ดึง PK ปัจจุบันจาก DB มาเทียบกับที่ parse จากชีท (Python, ไม่ผ่านแอป) — โครงการเทียบด้วยชื่อไทยเท่านั้น, ทรัพย์/ลีดเทียบด้วย ID ตรงๆ ได้เลย, กิจกรรมเทียบแบบ grouped tuple `(employee_code, action, date, count)` เพราะไม่มี natural key แล้วนับส่วนต่างจริง (sheet มากกว่า DB เท่าไหร่ในแต่ละ tuple)
**เขียนเข้า DB**: ผ่าน `mcp__supabase__execute_sql` ตรงๆ (ไม่ผ่าน PostgREST/RLS) เป็น multi-row `INSERT` ต่อตาราง — เจ้าของใหม่ใช้ `INSERT ... SELECT ... WHERE NOT EXISTS` กันชนซ้ำกับที่มีอยู่แล้ว 454 แถวโดยไม่ต้องดึงมาทั้งตาราง, `owner_id` ของทรัพย์ resolve ด้วย subselect (name+phone) ตอน insert เลย
สคริปต์วิเคราะห์/gen SQL ทั้งหมดอยู่ใน `import/*.py` (`analyze.py` · `diff2.py` · `diff3.py` · `diff_activities.py` · `build_all_sql.py` · `build_leads_sql.py`) — เป็นไฟล์ใช้ครั้งเดียว ไม่ได้ผูกกับ workflow ปกติ

**ทดสอบหลัง insert**: นับแถวทุกตารางตรงตามที่คำนวณไว้เป๊ะ (+15/+27/+33/+109/+312) · เช็ค `owner_id` ของทรัพย์ใหม่ทั้ง 33 รายการ ไม่มีตัวไหน null ผิดที่ (ตัวเดียวที่ null คือ `TNGM087` ซึ่งชีทไม่มีชื่อเจ้าของอยู่แล้ว ถูกต้อง)

---

## 🔖 อ่านก่อน (2026-08-24) — แดชบอร์ดของ Ben · คลังตาราง · ของที่ค้าง

> เซสชันนี้ **ไม่ได้แก้โค้ดเลย** เป็นการสำรวจล้วน · ตัวเลขแถวเป็นค่าที่วัดไว้ล่าสุด ไม่ได้ยิงสด
> เพราะ **Supabase MCP หลุด ต้อง authorize ใหม่ที่ `/mcp`** (โหมด non-interactive รันเองไม่ได้)

### 🔴 ค้นพบใหญ่: "ตัวเลขรายได้" มีอยู่จริง — แต่อยู่ในชีท ไม่ใช่ Supabase
Ben ส่งลิงก์แดชบอร์ดที่ใช้งานจริงมาให้ดู: **https://haus-dashboard-benhoenigs-projects.vercel.app**

**เป็นคนละแอปกับ `haus-crm`** (คนละโปรเจกต์ Vercel) และ **อ่าน Google Sheets ผ่าน `/api/sheets?sheet=...`**
12 ชีท: `summary_overview` · `summary_overview_monthly` · `summary_revenue` · `summary_revenue_monthly` ·
`summary_activity` · `summary_activity_monthly` · `summary_listings` · `summary_listings_monthly` ·
`summary_kpi` · `summary_heatmap_daily` · `summary_targets` · `summary_lead_sources` (+ `/api/settings`)

→ **ตรงกับคอมเมนต์ "wiring map" ใน [lib/dashboard.ts](haus-crm/lib/dashboard.ts) เป๊ะ** — ของเราถูกออกแบบให้เป็นตัวเดียวกัน แค่เปลี่ยนต้นทางจากชีทเป็น Supabase view

**ตัวเลขจริงที่แดชบอร์ดนั้นโชว์ (ส.ค. 2026):** ทีม **฿478,800 · 4 ยูนิต** · Mhow ฿283,800 (2 ดีล) · Stone ฿97,500 · Q ฿97,500 · Pup/Game/Golf ฿0 · Mhow ปีนี้ ฿777,450 / 7 ดีล · **เป้าทีม ฿3,000,000/เดือน**

- 🔴 **ต้นทางคือชีท `_raw_close_case`** (คอลัมน์ วันที่ปิด · Status `Pending`/`Success` · วันที่โอน) — **ตอน import 2026-08-03 ชีทนี้ไม่ได้ถูกดึงเข้ามาเลย** เข้ามาแค่ `main_7_last_match` 56 แถวที่ไม่มีราคา
- ⚠️ **"รายได้" ในแดชบอร์ดนั้นคือ "คอมมิชชั่น" ไม่ใช่ราคาบ้าน** — ฿283,800 ต่อ 2 ยูนิต = เฉลี่ย ฿119,700/ยูนิต
  → **ห้ามแมปเข้า `main_7_last_match.last_match_price` โดยไม่ถามก่อน** (ช่องนั้นทำไว้ 2026-08-17 สำหรับ "ราคาปิดดีล") · ตัวที่น่าจะตรงกว่าคือ `main_6_buyer_crm.commission` — **ยังไม่ได้ยืนยันกับ Ben**
- ✅ **แก้ความเข้าใจเดิม**: ที่เคยเขียนว่า "ไม่มีตัวเลขรายได้ในระบบเลย ต้องกรอก 56 ดีลเอง" — **จริงเฉพาะฝั่ง Supabase** ข้อมูลมีอยู่แล้วในชีท เลือก import ได้แทนการกรอกมือ

### เทียบ: แดชบอร์ดของ Ben (ใช้จริง) vs ของใน haus-crm (พักไว้)
| | Ben (live, ข้อมูลจริง) | haus-crm (`components/dashboard/*`) |
|---|---|---|
| การ์ดยินดี | **7 ใบ** (นักขาย · ปิดดีล · เป้าแน่น · ขยัน · สม่ำเสมอ · มาแรง · นักล่าทรัพย์) | 1 ใบ |
| KPI | **6 ตัว** — Owner Talk · Update Price · New List · Sourcing · Survey · Buyer Follow + จังหวะสัปดาห์ 1–4 | 4 ตัว (ขาด Update Price · New List) |
| ช่วงเดือน | ม.ค. 2025 – ส.ค. 2026 (20 เดือน) + preset "ปีก่อน" | ม.ค.–ก.ค. 2026 **ฮาร์ดโค้ด** |
| นาฬิกา | จริง (ส.ค. 2026 · วันที่ 24/31) | ตรึงไว้ `DASH_MONTH="2026-07"` `DASH_DAY=18` |
| เป้าทีม | **฿3,000,000/เดือน** | `TEAM_GOAL_MONTHLY = 12,000,000` ❌ ผิด 4 เท่า |
| Division | `div=sales` (จริง) + `div=marketing` (**ติดป้าย `[ MOCK ]` บนจอ**) | ไม่มี |
| ปุ่ม | ตั้งเป้า KPI · ตั้งค่า · ดูรางวัล 1/2/3 | ไม่มี |

- แท็บรายคน **6 คน** (Q/Stone/Pup/Game/Golf/Mhow) ใช้ได้จริงทุกคน — 10 บล็อก: ฝั่งผู้ซื้อ · ฝั่งเจ้าของ · KPI · กิจกรรมแยก 3 กลุ่ม · heatmap รายวัน
- `div=support` / `listing` / `all` / `admin` **ไม่มีจริง** เด้งไปหน้า marketing หมด → มีแค่ 2 division
- ทุกหน้า 0 console error · หน้าเว็บบอกเอง "อัปเดตทุก 5 นาที"

**❓ ยังไม่ได้ตัดสิน — ต้องถาม Ben ก่อนเริ่ม**: จะให้แดชบอร์ดใน `haus-crm` มาแทนตัวนี้ (ต้อง import `_raw_close_case` + ทำ view ให้ครบ 12 ชีท) หรือปล่อยให้ 2 ตัวทำงานคู่กันโดยตัวนั้นอ่านชีทเหมือนเดิม

### 📋 คลังตารางปัจจุบัน (~64 ตาราง · 5 view · 16 function)
| กลุ่ม | ตาราง | แถวล่าสุด |
|---|---|---|
| **หลัก (11)** | `main_1_hr` · `main_2_owner` · `main_3_property_detail` · `main_4_listing_database` · `main_5_lead_database` · `main_6_buyer_crm` · `main_7_last_match` · `main_8_listing_photo` · `main_9_support_log` · `main_10_potential_listing` · `main_11_potential_listing_log` | 10 · 452 · 308 · **511** · **0 ⚠️** · **953** · 56 · 0 · ~511 · 210 · 210 |
| **Lookup (26)** | gender · nationality · potential · lead_status · pipeline_stage · bank_loan · lead_type · lead_purpose · sell_reason · complain_status · marketing_channel · contact_by · employee_status · job_position · second_position · listing_status · listing_potential · listing_type · property_type · in_out_project · direction · view_type · unit_position · price_remark · unit_condition · close_type | — |
| **สิทธิ์/คน (6)** | `permissions` · `roles` · `role_permissions` · `user_roles` · `teams` · `zone`+`zone_sales` | 36 · 8 · 141 · 10 · **0 (รอ CEO)** · 30/30 |
| **งาน/กิจกรรม (5)** | `activities` · `action_type` · `tasks` · `targets` · `user_quick_actions` | **2,334** · 23 · 0 · 0 · 0 |
| **วันลา (3)** | `leave_type` · `leave_allowances` · `leave_requests` | — · 6 · 20 |
| **โปรเบชั่น (2)** | `probation_rank` · `rank_criterion` | ladder เดิม |
| **เทมเพลต (5)** | `kpi_template` · `listing_copy_template` · `checklist_template` · `checklist_template_item` · `listing_checklist_item` | 6 · **0 = ใช้ค่าตั้งต้น** · 3 · 14 · 0 |
| **ระบบ (3)** | `audit_log` · `notifications` · `notification_cron_state` | 13 · 0 · 1 |
| **ตายแล้ว (2)** | `contacts` · `contact_roles` | **0 — ไม่มีใครใช้** |

**View (5)**: `v_main_listing` · `v_support_listing` · `v_sale_status` · `v_sale_zones` · `v_employee_private`

### ⚠️ 3 เรื่องที่ต้องรู้จากการนับ
1. 🔴 **`db/supabase_full_setup.sql` ตกยุคแล้ว** — มี 59 ตาราง **ขาด 5 ตัวที่แอปเรียกใช้จริง**: `kpi_template` · `listing_copy_template` · `checklist_template` · `checklist_template_item` · `listing_checklist_item` (ทำผ่าน migration แล้วมิเรอร์ลงแค่ `rls_policies.sql` เป็นคอมเมนต์) · **ถ้ามีคน setup project ใหม่ด้วยไฟล์นี้ หน้าตั้งค่า 3 หน้ากับหน้าทรัพย์จะพังทันที** — เสนอ Ben ให้เติมแล้ว ยังไม่ได้ทำ
2. **`main_5_lead_database` ยังว่าง 0 แถว** — import 2026-08-03 ลงแต่ `main_6` (trigger นับเลขจาก 2 ตารางแล้ว แต่ตัวตารางยังว่าง)
3. **ไม่มีตารางไหนเก็บ "รายได้" เลย** — ตรงกับข้อค้นพบเรื่องชีทด้านบน

### ❓ Ben ถาม: "KPI ดูที่ไหน" — ตอบแล้ว พร้อมช่องว่าง 2 ข้อ
- **แก้แบบ KPI** → `/settings` → **เป้าหมาย KPI** (เห็นเฉพาะ `masterdata.govern` = CEO/Admin) · 6 แบบ: โทรหาลูกค้า 30 · พาชม 10 · เยี่ยมเจ้าของ 12 · ถ่าย Reels 6 · ปิดการขาย 3 · คอมมิชชั่น 500,000
- **ดูเป้าจริง** → `/today` การ์ด "เป้าหมายเดือนนี้" (ทางการ / ส่วนตัว)
- 🐛 **ช่องว่าง 1: `kpi_template` ยังไม่มีใครอ่านนอกจากหน้าตั้งค่า** — ฟอร์มตั้งเป้าใน `/today` ยังให้พิมพ์เองทุกครั้ง ไม่ได้เอา 6 แบบมาเป็นตัวเลือก (**งานเล็ก ยังไม่ได้ทำ**)
- **ช่องว่าง 2**: ตั้งเป้าให้ลูกทีมไม่ได้ เพราะ `teams` ว่าง → "ทางการ (ตั้งโดยหัวหน้า)" จะว่างเสมอ

---

## 🔖 ค้างอยู่ตรงนี้ — อ่านก่อนทำต่อ (2026-08-14)

### ✅ เสร็จ 2026-08-14: Phase 6 — `/leave` · `/team` · ตั้งค่า→โซน + ปิดช่องโหว่ RLS 1 จุด
**commit**: `98f9145` (/leave) · `71033ea` (/team) · `deca0f6` (โซน) — push แล้วทั้งหมด

#### ✍️ Ben สั่ง 2026-08-14: `date_started` = **1/11/2025 ทุกคน** · เซลล์ใหม่ **"นับจาก 0 คนอื่นผ่านหมดแล้ว"**
`date_started` เขียนครบ 10 คนแล้ว (รวม Pai ที่ลาออก + E-001 แถวแอดมินปลอม)

#### ✅ `/new-sales` เสร็จแล้ว (`21362e4`) — Phase 6 เหลือแค่ `/` แดชบอร์ด กับ `/website`
- **สมาชิกโปรแกรมเป็น "ข้อเท็จจริง" ไม่ derive** — 2 คอลัมน์ใหม่บน `main_1_hr`: `probation_start` · `probation_passed_at` · กระดาน = เซลที่ Active + มี start + **ยังไม่มี passed** · ทั้ง 10 คนถูกสแตมป์ว่าผ่านแล้ว → กระดานว่างตามที่ Ben สั่ง แล้วค่อยเติมเมื่อกดปุ่ม **"เข้าโปรแกรมเซลล์ใหม่"** ในหน้าประวัติพนักงาน
  - **เหตุผลที่ไม่ derive จาก `date_started`**: ทุกคนเริ่มวันเดียวกัน จะตั้งช่วงกี่เดือนก็ได้ผลแค่ 2 แบบ — ทั้งทีมขึ้นกระดาน หรือไม่มีใครขึ้นเลย
  - **`probation_passed_at` ต้องเก็บ ไม่ derive** เพราะเกณฑ์แบบ `monthly` ที่เดือนนี้ทำไม่ถึงจะทำให้ "ไม่ผ่าน" ย้อนหลังได้
- **ladder ย้ายเข้า DB แล้ว** — ตาราง `probation_rank` + `rank_criterion` (seed = ladder เดิมเป๊ะ) · เดิมอยู่ใน `ProbationProvider` แบบ in-memory **CEO แก้แล้วรีเฟรชหายทั้งหมด** · ตัวแก้เก็บเป็น draft แล้วกด **"บันทึกเกณฑ์"** (บันทึกทุก keystroke จะได้ Rank ที่ยังสร้างไม่เสร็จ + เกณฑ์ที่ยังไม่เลือกกิจกรรมชน FK)
- 🐛 **dropdown กิจกรรมในตัวแก้ Rank ใช้ `ACTION_GROUPS` (seed 20 ตัว) ทั้งที่ตารางมี 23** — ขาด `Owner Talk` ซึ่งเป็น KPI ตัวแรกของบริษัท · **บั๊กชุดเดียวกับฟอร์มงานใน Phase 5 ข้อ 6** เปลี่ยนมาอ่าน `action_type` จริงแล้ว

### ✅ เสร็จ 2026-08-14: ตั้งค่า → ข้อมูลอ้างอิงกลาง เขียนจริงแล้ว (`5c8a9a6`)
**ประเภททรัพย์ · ช่องทาง&ฟิลด์ Lead · แท็ก Lead · ประเภทกิจกรรม** เคยแก้ลง React state ทั้งหมด — CEO เพิ่มช่องทางการตลาด เห็นมันโผล่ในฟอร์มรับลีดจริง แล้วรีเฟรชหาย · ตอนนี้อ่าน+เขียนตารางจริงผ่าน [lib/mutations/reference.ts](haus-crm/lib/mutations/reference.ts)

**2 คุณสมบัติของตารางพวกนี้ที่กำหนดวิธีทำ:**
1. ⚠️ **PK คือตัวชื่อเอง** (convention ของโปรเจกต์) และ **FK ทุกเส้นเป็น `on update cascade` — เช็คครบ 20 เส้น** → **เปลี่ยนชื่อ = เขียนทับค่าในทุกแถวที่ถืออยู่** (ทดสอบแล้ว: เปลี่ยน `คอนโด` → ทรัพย์ตามไปครบ 16 ไม่มีตกค้าง) ตั้งใจให้เป็นแบบนี้ แต่แปลว่า **การเปลี่ยนชื่อ = การจัดประเภทใหม่** จึง commit ตอน blur ไม่ใช่ทุก keystroke
2. **ลบเป็น `on delete no action`** → ค่าที่ยังมีคนใช้ DB ปฏิเสธเอง · นับก่อนแล้วบอกเป็นภาษาไทย ("ลบไม่ได้ — มีทรัพย์ 16 รายการใช้ค่านี้อยู่")

🐛 **`property_type.code` เป็น NOT NULL แต่ฟอร์มไม่เคยมีช่องนี้** → เพิ่มประเภททรัพย์ผ่านหน้านี้**ล้มเหลว 100% มาตลอด** · `code` คือตัวอักษรตัวแรกของรหัสทรัพย์ (`CASK020` = C+ASK+020) เพิ่มช่องกรอก 1 ตัวอักษรแล้ว · **แถวที่มีอยู่แก้ code ไม่ได้** (ฝังอยู่ในรหัสที่ออกไปแล้ว) · code ซ้ำกันได้โดยตั้งใจ (บ้านเดี่ยว/บ้านแฝด ใช้ H เหมือนกัน)

🐛 **`ACTION_GROUPS` (seed 20 ตัว) โผล่เป็นครั้งที่ 3** — คราวนี้ที่ตัวแก้ประเภทกิจกรรม + ตัวเลือกกิจกรรมของ KPI · ทั้งคู่เปลี่ยนไปอ่าน `action_type` จริง (23 ตัว) แล้ว
- แท็กใหม่ได้ **id ที่สร้างขึ้น ไม่ใช่ตัว label** เพราะ `main_6_buyer_crm.tag_id` เก็บ id — ถ้าใช้ label เป็น id คนแรกที่แก้คำผิดจะย้ายลีดที่ติดแท็กทั้งหมด
- ป้าย "โหมดออกแบบ: การเปลี่ยนแปลงยังไม่ถูกบันทึก" มี 4 จุด **2 จุดกลายเป็นคำโกหกไปแล้ว** → ลบออกจากจุดที่เขียนจริงได้ · จุดที่ยังไม่มีตารางเก็บ (**เช็คลิสต์ทรัพย์ · เทมเพลตคำโฆษณา · เทมเพลต KPI · บทบาท/สิทธิ์**) เปลี่ยนเป็นข้อความสีเหลืองบอกตรงๆ

### ✅ เสร็จ 2026-08-17: รูปทรัพย์จริง — Supabase Storage + บีบอัดที่เครื่อง (`1eec1ed`)
🔴 **ทุกรูปในแอปเป็นรูป stock จาก Unsplash** (การ์ดทรัพย์ · ทรัพย์ทั้งบริษัท · แกลเลอรีหน้ารายละเอียด) **โดยไม่มีอะไรบอกว่าเป็นรูปตัวอย่าง** — ตอนเดโมไม่เป็นไร แต่ระบบขึ้นของจริงแล้ว เซลเปิดจอให้ลูกค้าดู = โชว์บ้านผิดหลัง · **ลบ `lib/placeholderImages.ts` ทิ้งแล้ว** ทรัพย์ที่ไม่มีรูปขึ้นไอคอนตึกแทน

**Ben สั่ง**: เก็บลง Supabase Storage · เซลอัปเอง · จำกัด 20 รูป/ทรัพย์ · ทำตัวบีบอัดให้

| ตั้งค่า | ค่า |
|---|---|
| ย่อด้านยาวสุด | **1920 px** (พอเต็มจอ + เอาไปทำเว็บพอร์ทัลลูกค้าต่อได้ · เล็กกว่าต้นฉบับ 3-4 เท่า) |
| บีบเป็น | **WebP 82%** (เล็กกว่า JPEG ~30%) |
| เป้าต่อรูป / เพดาน bucket | **1 MB / 2 MB** |
| ผลจริงที่ทดสอบ | **3.6 MB → 70 KB** (51 เท่า) · รูปมือถือทั่วไป 200–350 KB |

- ⚠️ **`toBlob` คืน PNG เงียบๆ ถ้าเบราว์เซอร์ไม่รองรับ WebP** — และ PNG ของรูปถ่าย**ใหญ่กว่าต้นฉบับ** จึงต้องเช็ค `blob.type` แล้ว fallback เป็น JPEG
- ⚠️ **ไฟล์ที่เก็บคือ "ไฟล์แสดงผล" ไม่ใช่ต้นฉบับ** — ต้นฉบับความละเอียดเต็มยังอยู่ใน Google Drive (`photo_album_link` 360 ทรัพย์) ซึ่งการตลาดใช้ส่งขึ้น DDproperty/Livinginsider
- ⚠️ **พื้นที่**: 360 ทรัพย์ × 10 รูป × 300 KB ≈ **1 GB = โควตาฟรีทั้งก้อน** ต้องจับตาเมื่อเซลเริ่มอัปจริง (Pro = 100 GB)
- **ไฟล์วิ่งจากเบราว์เซอร์เข้า bucket ตรง** ไม่ผ่าน server action (จะเสียแบนด์วิดท์ 2 เท่าจากมือถือ + ชน body limit) · action รับแค่ path
- **กัน 20 รูป 2 ชั้น** — ในแอป + **trigger บนตาราง** เพราะ REST ยิงตรงข้ามด่านแอปได้ (ทดสอบแล้วแถวที่ 21 ถูกปฏิเสธเป็นภาษาไทย)
- **insert แถวล้ม → ลบไฟล์ทิ้ง** ไม่ปล่อยไฟล์กำพร้ากินโควตาโดยไม่มีใครอ้างถึง · ลบรูป → หายทั้งแถวและไฟล์ (ยืนยัน `storage.objects` กลับเป็น 0)
- ต้องเพิ่ม `images.remotePatterns` ใน `next.config.mjs` ไม่งั้น `next/image` ปฏิเสธ host ของ Supabase ทุกรูป

**ทดสอบ (Admin)**: ไม่เหลือ Unsplash สักรูป · ทรัพย์ว่างขึ้น 0/20 + คำอธิบาย · อัป 3.6 MB → ได้ WebP 70 KB · ลบ → กลับ 0/20 ไฟล์หายด้วย · **agent มี `listings.edit` อยู่แล้วจึงอัปได้ ซึ่งคือจุดประสงค์** · audit_log กลับเป็น 13 · **0 console error**

---

### ✅ เสร็จ 2026-08-23: เช็คลิสต์ทรัพย์เด่น เขียนจริงแล้ว (`ef8bdbf`) — **ปิดครบทั้ง 3 หน้าตั้งค่า**
หน้าสุดท้ายที่ยังไม่มีตารางเก็บ · **หนักกว่าอีก 2 อัน** เพราะ `ChecklistProvider` ตัวเดียวถือทั้ง **เทมเพลต · ติ๊กของทุกทรัพย์ · วันสัญญา Exclusive** → ติ๊กเช็คลิสต์หรือกรอกวันหมดสัญญาแล้ว**ดูเหมือนบันทึก แต่รีเฟรชหายหมด**

**3 ตารางใหม่**: `checklist_template` · `checklist_template_item` · `listing_checklist_item` + 2 คอลัมน์ `agreement_start`/`agreement_end` บน `main_4` (เพิ่มเข้า `v_main_listing` แล้ว)

#### ✍️ Ben ตัดสินใจ 2 ข้อ (2026-08-23)
1. 🔴 **เทมเพลต "ลงประกาศ A List" ซ้ำกับ `main_10_potential_listing` เป๊ะทั้ง 7 ข้อ** — Ben เลือก **ทำตารางใหม่ แล้วเลิกใช้ 5 คอลัมน์เดิม** (`template_link` · `marketplace` · `profile` · `group_date` · `group_boost_date`) · **ไม่มีข้อมูลหาย เพราะทั้ง 5 ยังว่าง 0/210** · `main_10` ยังทำหน้าที่เดิมคือ "ทรัพย์ไหนเป็น A List" ผ่าน trigger ไม่ได้ถูกแตะ
2. **ขั้นตอนแบบ "เอกสาร" เก็บลิงก์ Google Drive ไม่อัปไฟล์** — โฉนด/สำเนาบัตร ปชช. อยู่ที่เดิม **ไม่เอา PII เข้า Supabase** + ไม่กินโควตาที่รูปทรัพย์ใช้อยู่

#### 3 เรื่องที่ต้องรู้
- ⚠️ **สิทธิ์ 2 ชั้นต่างกันโดยตั้งใจ** — แก้ "ว่าขั้นตอนคืออะไร" ต้อง `checklists.manage` แต่ **"ติ๊ก" ใช้สิทธิ์เท่ากับแก้ทรัพย์** (`listings.edit`/`listings.marketing`) เพราะงานเช็คลิสต์เป็นงานข้ามทีม (เซลคุยเจ้าของ · Support เก็บเอกสาร · การตลาดโพสต์) ถ้าผูกกับเซลเจ้าของทรัพย์คนเดียว **ส่วนใหญ่จะติ๊กไม่ได้เลย**
- ⚠️ **ความคืบหน้าเป็น live join ไม่ใช่ snapshot** — แถวเกิดตอนมีคนแตะครั้งแรกเท่านั้น → เพิ่มขั้นตอนใหม่ ทรัพย์ทุกหลังเห็นทันทีไม่ต้อง backfill · **ลบขั้นตอน = ความคืบหน้าของขั้นนั้นในทุกทรัพย์หายตาม (cascade)** ถูกต้องแล้ว แต่เป็นเหตุผลที่หน้าจอถามก่อนลบ
- ⚠️ **วันสัญญาอยู่บน `main_4` ไม่ใช่ `main_10`** — trigger ลบแถว main_10 ทิ้งทันทีที่ทรัพย์หลุดเกณฑ์ **วันหมดสัญญาที่เซ็นไว้จะหายไปด้วย**

**ทดสอบ (Admin, `HBGY007` = Exclusive จึงได้ครบทั้ง 3 เทมเพลต)**: การ์ดขึ้น 0/14 · ติ๊กแล้วรอดข้ามรีเฟรช + สแตมป์ `completed_by='E-001'` · ลิงก์ Drive รอด · วันสัญญารอด + โชว์ระยะสัญญา/วันเหลือ · แก้ชื่อขั้นตอนใน ตั้งค่า → **ไปโผล่ที่การ์ดในหน้าทรัพย์จริง** · ระดับ DB: agent เห็นเทมเพลต แก้ไม่ได้ แต่ติ๊กได้ · check ปฏิเสธ 23514 ครบ 3 กรณี · **0 console error** · คืนค่าครบ (3 เทมเพลต · 14 ขั้นตอน · 0 ความคืบหน้า · 0 สัญญา · audit_log 13)

### ✅ เสร็จ 2026-08-23: เทมเพลตคำโฆษณา + เทมเพลต KPI เขียนจริงแล้ว (`840f4f9`)
2 ใน 3 หน้าตั้งค่าที่ยังไม่มีตารางเก็บ — **เหลือ "เช็คลิสต์ทรัพย์" หน้าเดียว** (ดูหัวข้อถัดไป)
CEO เคยแก้คำโฆษณาแล้วเห็นมันเปลี่ยนในทุกทรัพย์ทันที พอรีเฟรชก็หายหมด

#### คำโฆษณา — ตาราง `listing_copy_template` ([lib/mutations/copyTemplates.ts](haus-crm/lib/mutations/copyTemplates.ts))
- ⚠️ **เก็บเฉพาะช่องที่มีคนแก้ ไม่ได้เก็บครบ 9 ช่อง** — ค่าตั้งต้นอยู่ในโค้ด (`defaultTemplate`) และเป็น fallback เสมอ
  → **ตารางว่าง = คำโฆษณายังออกถูกทุกช่อง** · **"คืนค่าเริ่มต้น" = ลบแถว** ไม่ใช่เขียนค่าตั้งต้นทับ
  → ปรับค่าตั้งต้นในโค้ดเมื่อไหร่ ช่องที่ไม่มีใครแก้ได้อานิสงส์ทันที ไม่ถูกสำเนาเก่าบัง
- 🔴 **`CopyTemplatesProvider` เปลี่ยนเป็นอ่านอย่างเดียว** — ของเดิมเป็น store ที่ตัวแก้เขียนลงตรงๆ **แปลว่าพิมพ์ปุ๊บคำโฆษณาทุกทรัพย์เปลี่ยนตามทันทีทั้งที่ยังไม่ได้บันทึก** · ตอนนี้ชีทถือ draft ของตัวเองแล้วค่อยเขียนตอนกดบันทึก **ไม่มีสภาวะที่แอปสร้างคำโฆษณาจากค่าที่ DB ไม่มี**

#### เป้าหมาย KPI — ตาราง `kpi_template` ([lib/mutations/kpiTemplates.ts](haus-crm/lib/mutations/kpiTemplates.ts))
- seed 6 แถวตรงกับ `KPI_TEMPLATES` เดิมในโค้ดเป๊ะ · `activity_type` เป็น FK → `action_type` (เปลี่ยนชื่อกิจกรรมแล้วเทมเพลตตามไปเอง)
- ตารางปฏิเสธเอง 2 กรณี: เทมเพลตแบบไปป์ไลน์ที่ยังถือกิจกรรมค้างไว้ · แบบกิจกรรมที่ยังไม่เลือกกิจกรรม → **จึงบันทึกทั้งชุดด้วยปุ่ม ไม่ใช่ทุก keystroke** (เหมือนตัวแก้ Rank)
- 🔴 **`kpi_template.id` ต้องเป็น `generated BY DEFAULT as identity` ห้ามเป็น `always`** — upsert คือ `INSERT ... ON CONFLICT` ที่ต้องส่ง `id` มาด้วยเพื่อหา conflict แต่ `always` ปฏิเสธค่า id ทุกกรณี → **บันทึกแถวเดิมล้มเงียบทุกครั้ง** · จับได้เพราะ**ไม่มีแถวใน `audit_log`** ไม่ใช่เพราะหน้าจอบอก (จำไว้ใช้กับตารางใหม่ที่จะ upsert ทุกตัว)

**ทดสอบ (Admin)**: ทั้ง 2 ตัวแก้แล้วรอดข้ามรีเฟรช + คืนค่ากลับได้ · ระดับ DB: agent เขียนไม่ได้ทั้งคู่ (42501) แต่**อ่านได้** (ปุ่มสร้างคำโฆษณาต้องใช้) · marketing แก้คำโฆษณาได้ แต่แก้ KPI ไม่ได้ · check ปฏิเสธ 23514 · FK ปฏิเสธกิจกรรมที่ไม่มีจริง 23503 · **0 console error** · คืนค่าครบ (6 เทมเพลตชื่อเดิม · 0 override · audit_log 13)

### ✅ เสร็จ 2026-08-23: ฟอร์มทรัพย์ 2 หน้าใช้รายการช่องชุดเดียวกัน (`b577cdd` · `bbdc1a3` · `fb5564e`)
Ben ถามว่า *"ทำไมหน้าเพิ่มทรัพย์ กับหน้าแก้ไขทรัพย์ มันไม่เหมือนกัน"* — เพราะ 2 ฟอร์มถูกเขียนคนละรอบ **เพิ่มทรัพย์มี 12 ช่อง แก้ไขมี 41** → กรอกตอนสร้างเสร็จแล้วต้องเปิดแก้ไขต่ออีกรอบเพื่อกรอกส่วนที่เหลือ · Ben เลือก **"แบ่งกลุ่ม — ช่องจำเป็นเปิด ที่เหลือพับไว้"**

- **[lib/listingFields.ts](haus-crm/lib/listingFields.ts) (ใหม่) = แหล่งความจริงเดียว** — `LISTING_SECTIONS` (กลุ่มแรกเปิด ที่เหลือพับ) + `LISTING_FIELDS` 41 ช่อง (`kind`/`group`/`section`/`lookup`) · ทั้งฟอร์มเพิ่มและชีทแก้ไขเรนเดอร์จากตัวเดียวกันผ่าน [ListingFieldInput.tsx](haus-crm/components/ListingFieldInput.tsx) → **เพิ่มช่องใหม่ทีเดียวได้ทั้ง 2 หน้า** (นี่คือเหตุผลที่มันเคยไม่ตรงกัน)
- **ผู้ดูแล(เซล) ถูกถอดออกจากฟอร์มเพิ่มทรัพย์** ตามที่ Ben สั่ง — ลงชื่อคนที่กดเองอัตโนมัติ (`current_employee_code()`) · **เพิ่มรูปได้ตั้งแต่ตอนสร้าง** แล้ว (stage ไว้ในเครื่อง → อัปหลัง insert ได้ `listing_id`)
- 🐛 **8 คอลัมน์ที่เป็น FK แต่เรนเดอร์เป็นช่องพิมพ์อิสระ** (`direction` `view_type` `unit_position` `unit_condition` `in_out_project` `price_remark` `listing_type` `listing_status`) — พิมพ์อะไรลงไปก็ชน FK เป็น error ดิบ · เปลี่ยนเป็น dropdown จากตารางจริงครบ (8/2/10/4/2/4/5/8 ตัวเลือก) **บั๊กนี้มีมาก่อนงานนี้**
- 🐛 **ช่องที่เปิดแล้วเห็นไม่หมด** (Ben แจ้ง) — วัดบนจอ 390×780 แล้วพบว่า `formScrollHeight === formClientHeight` **คือฟอร์มไม่ได้ล้นเลย** · section อยู่ใน flex column ที่ถูกจำกัดความสูง → flex ย่อแต่ละ section ลง แล้ว `overflow-hidden` (ที่ใส่ไว้เพื่อมุมโค้ง) ก็ตัดส่วนที่เกินทิ้ง **ไม่ใช่เลื่อนไม่ได้ แต่เนื้อหาหายไปเลย** → แก้ด้วย `shrink-0` + ทำหัว/ท้ายตรึง เนื้อกลางเลื่อน (ปุ่มบันทึกจะได้ไม่ถูกดันตกจอ) · วัดหลังแก้: เลื่อนได้ 1 ก้อนแทน 7 · เนื้อหา 3337px ในกรอบ 570px · ช่องสุดท้ายถึงได้จริง

### ✅ เสร็จ 2026-08-23: แจ้งเตือนตามเวลา — pg_cron (`6c32dbb` · migration `daily_reminder_notifications` + `notification_types_for_reminders`)
งานที่**ไม่มีใคร "กด" อะไรตอนที่มันควรเตือน**: ลีดค้างไม่ได้ติดต่อ · ใบลารออนุมัติ · ดีลปิดแล้วยังไม่กรอกราคา · ทรัพย์ที่ประกาศอยู่แต่ยังไม่มีรูป

**ใช้ `pg_cron` ที่มากับ Supabase** — ไม่ต้องมีเซิร์ฟเวอร์แยก ไม่ต้องตั้ง Vercel cron ไม่มีค่าใช้จ่ายเพิ่ม · job `daily-notifications` เวลา `0 2 * * *` (02:00 UTC = **09:00 ไทย**) เรียก `run_daily_notifications()`

**3 อย่างที่ Ben ตัดสินใจ:**
1. **สรุปใบเดียวต่อคนต่อวัน ไม่ใช่ใบต่อรายการ** — ลีดค้างมี ~925 ราย ถ้ายิงใบต่อลีด กระดิ่งจะกลายเป็นขยะตั้งแต่วันแรกแล้วไม่มีใครเปิดอีก
2. **นับเฉพาะที่ค้างหลังเปิดระบบ** — นาฬิกาลีดค้างเริ่มที่ `notification_cron_state.started_at` ไม่ใช่ `last_follow_date` (ช่องนั้นมาจากชีทตอน import และ **ลีด 337 รายไม่เคยมีค่าเลย**) → **วันแรกเงียบสนิท** แล้วค่อยเริ่มเตือนเมื่อพ้น 7 วัน ซึ่งตอนนั้นคือค้างจริงในมือเรา
3. **ผู้รับ**: ใบลา → CEO/HR · ดีลไม่มีราคา → เจ้าของดีล · ทรัพย์ไม่มีรูป → เซลที่ดูแล
- **รูปตามเฉพาะทรัพย์ที่ยังมีชีวิต** (Posted / Ready to Post / Update) — Sold/Cancel Completed ไม่ต้องตามแล้ว
- ⚠️ ฟังก์ชันเป็น **`security definer`** เพราะเขียนแจ้งเตือนถึงคนอื่น ซึ่ง policy own-row ของ `notifications` ปฏิเสธโดยตั้งใจ (เหตุผลเดียวกับ trigger มอบหมายลีด)
- ⚠️ **รันซ้ำปลอดภัย** — แต่ละกฎเช็คก่อนว่าวันนี้คนนั้นได้แจ้งเตือนชนิดนั้นไปแล้วหรือยัง (รันรอบสองได้ 0 ใบ)
- 🔴 **`notifications.type` มี CHECK constraint** → เพิ่มชนิดใหม่ต้องแก้ **3 ที่ ไม่ใช่ 2**: union ใน TypeScript · `NOTIFICATION_META` · **ตัว constraint ใน DB** (รัน cron ครั้งแรกล้มเพราะข้อนี้)

**ทดสอบ**: รันแรกส่ง **11 ใบ** (ดีลไม่มีราคา 5 คน: Game 1 · Pup 3 · Stone 12 · Q 16 · Mhow 24 · ทรัพย์ไม่มีรูป 6 คน รวม 323 = Posted 322 + Update 1 · **ลีดค้าง 0 ตามที่ออกแบบ** · ใบลา 0) · รันซ้ำได้ 0 ใบ · เบราว์เซอร์ (Game): เห็นสรุป 2 ใบในกระดิ่ง ผู้ทำเป็น **"ระบบ"** ไม่มีใบลีดค้าง กดใบดีลแล้วไป `/last-match` ถูก · **0 console error** · คืนค่าครบ (notifications 0 · activities 2334 · audit_log 13)

---

### ✅ เสร็จ 2026-08-17: แจ้งเตือนตอนมอบหมายลีด — ทำเป็น trigger (migration `notify_on_lead_assignment`)
**Ben เลือกทาง trigger ไม่ใช่ RPC** หลังถามว่า "ถ้าให้ Admin หรือ Benz เท่านั้นที่มอบหมายลีดได้ล่ะ"

**คำตอบตอนนั้น: เป็นแบบนั้นอยู่แล้ว** — เช็ค DB แล้วมอบหมายลีดได้ 3 คน: **Stone (ceo) · Admin (system_admin) · Benz (listing_support)** · เซล 5 คนกับ Pui ทำไม่ได้อยู่แล้ว
- Stone/Admin **เขียนแจ้งเตือนหาคนอื่นได้อยู่แล้ว** เพราะมี `roles.manage` → **Benz คือคนเดียวที่ติด** และเป็นคนที่ทำงานนี้จริง
- (มี 2 บทบาทที่ถือ `leads.assign` แต่ยังไม่มีใครถือบทบาทนั้น: `admin` · `sales_leader`)

**ทำไม trigger ชนะ RPC**: ลีดเข้าทาง **n8n เป็นหลัก** (952/953 มี `sale_id` มาแต่ต้นทาง) → RPC จะครอบเฉพาะตอนคนกดปุ่มในเว็บ **เงียบสนิทตอนลีดใหม่วิ่งเข้าเอง ซึ่งคือตอนที่ควรดังที่สุด** · แถมไม่ต้องขยายสิทธิ์ให้ใครเลย (สวนทางกับที่ Ben กำลังจำกัดให้แคบลง) · และปลอมไม่ได้เพราะข้อความระบบเขียนเอง

**4 ด่านในฟังก์ชัน — ทดสอบครบทุกด่าน**
| ด่าน | ผลทดสอบ |
|---|---|
| Benz (ไม่มี `roles.manage`) มอบลีดให้ Game | ✅ แจ้งเตือนถึง S-002 · actor = "Benz" |
| มอบให้ตัวเอง | ✅ ไม่เตือน (0 แถว) |
| n8n / service role (ไม่มี session) | ✅ เตือน · actor = **"ระบบ"** |
| สร้างลีดใหม่ที่ระบุเซลมาแล้ว (เคสหลักของ n8n) | ✅ เตือนทันที |
| `update ... set sale_id = sale_id` (ไม่ได้ย้ายมือ) | ✅ ไม่เตือน |

- ⚠️ **`when` ของ trigger อ้าง `OLD` ไม่ได้ตอน INSERT** (42P17) → เช็ค "ค่าเปลี่ยนจริงไหม" ด้วย `tg_op` ในฟังก์ชันแทน
- 🔴 **IMPORT ลีดเป็นก้อนอีกครั้งเมื่อไหร่ ต้อง `alter table main_6_buyer_crm disable trigger trg_notify_lead_assigned;` ก่อน** ไม่งั้นยิงแจ้งเตือนพันกว่าใบ (เขียนเตือนไว้ในทั้ง 2 ไฟล์ SQL แล้ว)
- มิเรอร์ลง `db/supabase_full_setup.sql` + `db/rls_policies.sql` (§15) แล้ว

---

### ✅ เสร็จ 2026-08-17: แจ้งเตือน + บันทึกกิจกรรม ต่อ DB จริง (`e458852`)
**2 หน้าสุดท้ายที่ยังโชว์ข้อมูลปลอม**

#### แจ้งเตือน ([lib/mutations/notifications.ts](haus-crm/lib/mutations/notifications.ts))
ตาราง `notifications` สร้างไว้ตั้งแต่ 2026-08-03 แต่**ว่างมาตลอดเพราะไม่เคยมีอะไรเขียนลงไป** · กระดิ่งโชว์ seed ที่ addressing ด้วย login id ที่ session จริงไม่มี → **สำหรับคนที่ใช้งานจริงมันว่างเปล่าตลอด** และสถานะอ่านแล้วรีเซ็ตทุกรีเฟรช · ตอนนี้อ่านตารางจริง + กดอ่านแล้วเขียน `read_at`
- ⚠️ **กรอง `employee_code` ในคิวรีเอง ไม่พึ่ง RLS** — policy เป็น own-row **หรือ** `roles.manage` → ถ้าไม่กรอง กระดิ่งของแอดมินจะเห็นแจ้งเตือนทั้งบริษัท และ "อ่านทั้งหมด" จะล้างของทุกคน (กับดักเดียวกับ `/today` ใน Phase 5)
- 🔴 **มอบหมายลีดยัง "ไม่" ส่งแจ้งเตือน — ตั้งใจ ไม่ใช่ลืม** · INSERT policy เป็น own-row → **เซลส่งแจ้งเตือนหาเพื่อนที่เพิ่งมอบลีดให้ไม่ได้** ซึ่งเป็นจุดประสงค์ทั้งหมดของแจ้งเตือนตัวนั้น · ทำจริงต้องมี **RPC `security definer` หรือ trigger** — ยังไม่ทำเพราะเป็นการตัดสินใจที่ใหญ่กว่างานนี้ · `notify()` ใช้ได้แล้วกับเคสที่ผู้รับ = คนทำ หรือคนที่มี `roles.manage`
- นาฬิกาปลอมหายไปด้วย — `NOW` เคยตรึงไว้ที่ TODAY ของยุคออกแบบ ทำให้ทุกแถวขึ้น "เมื่อสักครู่" ตลอดกาล

#### บันทึกกิจกรรม
`ActivityProvider` เก็บ sample สิบกว่าแถว ทั้งที่ตารางมี **2,334 แถวจริง** — และมัน**เลิกเป็นที่รับ write ไปแล้วตั้งแต่ Phase 5** (ติ๊กงานเขียนลง `activities` ตรงๆ) → เป็น store ที่ไม่มีใครเขียน และทุกคนอ่านผิดที่ · ตอนนี้เป็น read-through ล้วน · ไทม์ไลน์ในหน้าทรัพย์ใช้แถวจริงแล้ว
- `lib/actions.ts` เหลือแค่ type + helper · `ACTION_GROUPS` ยังอยู่เพื่อ `NOTE_ACTION`/`AttachMode` **พร้อมคำเตือนว่ามันขาด 3 แถวและก่อบั๊กเดียวกันมาแล้ว 3 ครั้ง**

**ทดสอบ (Admin)**: กระดิ่งโชว์ 2 แถวจริง ไม่มีร่องรอย seed เก่า · กดอ่าน → `read_at` เขียนลง DB และคงอยู่ · `/today` + ไทม์ไลน์ทรัพย์เรนเดอร์จากแถวจริง · ลบแจ้งเตือนทดสอบครบ · `activities` เท่าเดิม 2,334 · audit_log 13 · **0 console error**

---

### ✅ เสร็จ 2026-08-17: ตัวจัดการทีม + เก็บราคาปิดดีล (`640d451`)
Ben สั่ง 2 อย่าง: **สร้างกลไกทีมไว้แต่ยังไม่ต้องตั้ง (รอ CEO)** · **บังคับกรอกราคาตอนเปลี่ยนสเตจเป็น Win/Close**

#### ทีมขาย ([lib/mutations/teams.ts](haus-crm/lib/mutations/teams.ts))
เขียน `teams` + `main_1_hr.team_id` จริงแล้ว · **ตารางยังว่างตามที่สั่ง**
- ⚠️ **ทีมไม่ใช่แค่ป้ายชื่อ** — `visible_employee_codes()` อ่านขอบเขต "ทีม" จาก `team_id` พอตารางว่างมันจึงคืน "ตัวเองคนเดียว" **ให้ทุกคนรวมทั้ง CEO** → นี่คือเหตุผลที่คอลัมน์กิจกรรมใน `/team` ขึ้น "—" · ตั้งเป้าให้ลูกทีมไม่ได้ · แดชบอร์ดทีมทำไม่ได้ · หน้าจอตอนว่างบอกเรื่องนี้ตรงๆ แล้ว
- **2 อย่างที่ตัวแก้ปฏิเสธ** เพราะจะ "ดูเหมือนตั้งได้แต่ไม่มีผล": ตั้งหัวหน้าที่ยังไม่อยู่ในทีม (helper อ่านสมาชิก → หัวหน้าจะเห็นลูกทีม 0 คน) · หัวหน้าที่ยังไม่มีบทบาท `Sales Leader` → **เตือนสีเหลืองแล้วชี้ไปหน้าบทบาท** ไม่แอบให้สิทธิ์เอง (สมาชิกภาพ กับ อำนาจ เป็นคนละเรื่อง)

#### ราคาปิดดีล ([lib/mutations/lastMatch.ts](haus-crm/lib/mutations/lastMatch.ts))
- **เปลี่ยนสเตจเป็น ปิดการขาย/ปิดได้ → ช่องราคาโผล่ + บันทึกไม่ได้ถ้าไม่กรอก** · แถวดีลสร้างจากลีด + ทรัพย์ที่ลูกค้าสนใจ เซลพิมพ์แค่ตัวเลขเดียว
- **56 ดีลเดิมกรอกย้อนหลังได้ที่หน้า `/last-match`** แก้ในตารางเลย commit ตอน blur (ไม่ใช่ทุก keystroke — "35" ไม่ใช่ราคา และเลขนี้ไปเป็นยอดรายได้)
- 🐛 **2 จุดที่ CLAUDE.md เขียนไว้ผิด — ยึดข้อมูลจริง**: (1) **ไม่มี trigger บน `main_7_last_match`** ต้อง mint id เอง (2) **id จริงเป็นแบบชื่อเล่น** (`Stone-10`, `Stone+Pup-01`) จากตอน import ไม่ใช่ `S-001-001` → ของใหม่ตามของเดิม (`Mhow-25`)
- เขียนต้องมี **`lastmatch.add`** (ไม่ใช่ permission ฝั่ง view) ตามที่ policy ของตารางขอ

**ทดสอบ (Admin)**: สร้างทีม → เพิ่มสมาชิก → ตั้งหัวหน้า อยู่ครบข้ามรีเฟรช + เตือนเรื่องบทบาทขึ้นจริง · ย้าย `L26-018` เป็น "ปิดได้" → ถูกปฏิเสธตอนไม่กรอกราคา → กรอกแล้วได้ `Mhow-25` **sale_id = S-004 ของเจ้าของลีด ไม่ใช่แอดมินที่กด** + รายละเอียดทรัพย์ก๊อปมาถูก · แก้ราคาใน `/last-match` รอดข้ามรีเฟรช · **คืนค่าครบ** (56 ดีลไม่มีราคา · ไม่มีทีม · L26-018 กลับเป็น Call · audit_log 13) · **0 console error**

#### ✍️ Ben ตอบเรื่องที่ค้าง (2026-08-17)
- **โควตาวันลา** — CEO กำหนดเองได้อยู่แล้วที่ ตั้งค่า → โควตาวันลา (ทำตอน `/leave`) · "ให้เกินไปก่อนไม่เป็นไร" = ระบบไม่บล็อกการลาอยู่แล้ว แค่โชว์ป้ายแดง **ไม่ต้องทำอะไรเพิ่ม**
- **แท็ก Lead** — CEO แก้เองได้แล้วที่ ตั้งค่า → แท็ก Lead (4 อันที่มีเป็นตัวอย่างรอเปลี่ยน)
- **ข้อมูลทรัพย์ที่ว่าง** (ทิศ 453/511) — Ben บอกไม่เป็นไร บางทรัพย์ว่างอยู่แล้วจริง **ไม่ต้องแก้**

---

### ✅ เสร็จ 2026-08-14: ตั้งค่า → บทบาท & สิทธิ์ เขียนจริงแล้ว (`be71cef`)
**อันตรายที่สุดในบรรดาหน้าที่ยังเป็น in-memory** — ติ๊กเปิดสิทธิ์แล้ว**ดูเหมือนได้ผล** (toggle ติด · ตัวเลขสิทธิ์เพิ่ม · sidebar ของ persona ที่ "ดูในมุมมอง" เปลี่ยนตามด้วย) แต่ไม่มีอะไรถึง DB เลย → คนกดให้สิทธิ์ HR แล้วเชื่อว่าให้ไปแล้ว ทั้งที่ไม่ได้ให้ · ตอนนี้เขียน `roles` / `role_permissions` / `user_roles` จริงผ่าน [lib/mutations/roles.ts](haus-crm/lib/mutations/roles.ts)

**🔒 กันล็อกตัวเอง 2 ชั้น — ชั้นที่ 2 เจอจากการเดินชนเอง**
1. **ระดับบริษัท** (ออกแบบไว้ตั้งแต่แรก) — ทุก policy ในระบบมี `has_perm('roles.manage')` เป็นทางออกฉุกเฉิน ถ้าคนสุดท้ายเสียสิทธิ์นี้ **จะไม่มีใครคืนให้ได้อีกเลย ทั้งทางเว็บและทาง API** → ทุก write ที่อาจเอาคนสุดท้ายออกจะนับก่อนแล้วปฏิเสธไม่ให้เหลือ 0 (RLS ทำแทนไม่ได้ มันเห็นทีละแถว)
2. 🔴 **ระดับตัวเอง (เพิ่มรอบนี้)** — ตอนทดสอบด้วยบัญชี Admin **ถอด role `system_admin` ของตัวเองออกได้จริง** · ชั้นที่ 1 ยอมถูกต้อง (Stone ยังถือ `ceo` อยู่ ระบบไม่ได้ล็อก) แต่หน้าตั้งค่าส่วนนี้ gate ด้วย `roles.manage` → **จอหายกลางคัน กลับเข้าไม่ได้ ต้องแก้ด้วย SQL ดิบ** · ตอนนี้ปฏิเสธแยกต่างหาก ครอบทั้ง 3 ทางที่ทำได้ (ปิดสิทธิ์ในบทบาทที่ตัวเองถือ · ถอด role ตัวเอง · ลบ role ที่ตัวเองถือ)

- **บทบาทของระบบ (CEO · ผู้ดูแลระบบ) ล็อกไว้** — เปลี่ยนชื่อ/ลบ/แก้สิทธิ์ไม่ได้ เป็นทางกลับถ้าตั้งค่าที่เหลือผิด
- **id ของ role สร้างขึ้นใหม่ ไม่ derive จากชื่อ** เพราะ `user_roles`/`role_permissions` เก็บ id — ถ้า derive จากชื่อ คนแรกที่เปลี่ยนชื่อบทบาทจะทำให้สิทธิ์ทั้งหมดหลุด
- **ทดสอบ (Admin)**: บทบาทระบบไม่มีปุ่มลบ/ช่องแก้ชื่อ · ให้ `ดู Lead ทั้งหมด` กับ Marketing 7→8 ถอนคืน 8→7 ข้ามรีเฟรชทั้งคู่ · ถอด role ตัวเอง → **ถูกปฏิเสธเป็นภาษาไทย + role ยังอยู่หลังรีเฟรช** · สร้าง→เปลี่ยนชื่อ→ลบ บทบาททดสอบ ครบ · คืนค่าครบ (8 บทบาท · 141 grant · 10 assignment · audit_log 13) · **0 console error**

~~**เหลือในหน้าตั้งค่าที่ยังบันทึกไม่ได้จริง**~~ ✅ **ปิดครบทั้ง 3 แล้ว 2026-08-23** (เทมเพลตคำโฆษณา · เทมเพลต KPI · เช็คลิสต์ทรัพย์) — **ไม่เหลือหน้าตั้งค่าที่แก้แล้วหายอีกแล้ว**

### 🔴🔴 บทเรียนสำคัญที่สุดของวัน — `main_1_hr` **ไม่มี grant ระดับตาราง**
migration ที่เพิ่ม 2 คอลัมน์โปรเบชั่น **ทำ `/team` `/new-sales` `/settings` พังหมดทันที** ขึ้น `permission denied for table main_1_hr`
- ตารางนี้ถูก `revoke select` ทั้งตารางตั้งแต่ 2026-08-03 แล้ว grant กลับ**ทีละคอลัมน์** (เพื่อกันเงินเดือน/PII) → **คอลัมน์ใหม่ไม่ได้สืบทอดอะไรเลย** และ PostgREST ล้มทั้ง query ไม่ใช่แค่คอลัมน์นั้น
- ✅ **เพิ่มคอลัมน์ใน `main_1_hr` เมื่อไหร่ ต้อง `grant select (คอลัมน์ใหม่) ... to authenticated` ทุกครั้ง**
- ✅ **บล็อก grant ระดับคอลัมน์ถูกเขียนลง `db/rls_policies.sql` แล้ว (§14.2)** — ของเดิมรันสดมือเปล่าไม่เคยบันทึกไว้ ถ้ามีคน setup ใหม่จะได้ฐานที่ **เงินเดือน/PII อ่านได้หมด** โดยไม่รู้ตัว

**ทดสอบครบวงจร (login Admin E-001 — Ben ให้รหัสมา)**: ใส่ Golf เข้าโปรแกรม → ขึ้นกระดานที่ "เริ่มต้น 0%" พร้อม ladder + กิจกรรมจริง 40 แถว (`total` เป็น 0 ถูกต้อง เพราะกิจกรรมเก่ากว่าวันเข้าโปรแกรม) → แก้ชื่อ Rank → บันทึก → **รีเฟรชแล้วชื่อยังอยู่** (ของเดิมหายทุกครั้ง) → กดผ่าน → กระดานว่างอีกครั้ง · **ตัวแก้โซนได้ขับในเบราว์เซอร์จริงครั้งแรก** (ก่อนหน้ามีแต่รหัส agent): RM3 เพิ่ม/ถอนเซลคนที่ 3 ได้ มงกุฎเจ้าภาพไม่หลุด · **คืนค่าครบทุกอย่าง** (โปรเบชั่นกลับ 2025-11-01/ผ่าน · Rank กลับ Rookie/Junior/Senior · zone_sales 30 · audit_log 13) · **0 console error**

#### ตั้งค่า → โซน (`deca0f6`)
🐛 **บั๊กสดที่เจอ: `lib/zones.ts` (sample 12 โซน) ยังป้อน dropdown โซนใน `ListingEditSheet` อยู่ และ 4 รหัสในนั้น (`PTM` `PT3` `BKL` `BWK`) ไม่มีใน `zone` เลย → เลือกแล้ว save ชน FK ทันที** · อีก 22 โซนจริงก็ไม่มีให้เลือก — เปลี่ยนไปอ่านจาก DB ผ่าน `MasterDataProvider` (31 ตัวเลือก = 30 โซน + ไม่ระบุ)
- `ZonesAdmin` เดิมโชว์ "เซลส์ที่ดูแล" **คนเดียว** จากคอลัมน์ `zone.sale_id_assigned` ที่**ถูกลบไปตั้งแต่ 2026-08-03** + ปุ่มแก้ไข disabled → เขียนใหม่เป็นตัวแก้จริง เลือกเซลได้หลายคน + ตั้งเจ้าภาพ + เพิ่ม/แก้ชื่อ/ลบโซน
- ⚠️ **`setZoneSales` ต้องเขียนทับทั้งชุดเสมอ** — `is_primary` มี partial unique index (`uq_zone_primary`) ถ้าย้ายเจ้าภาพแบบ insert ก่อน delete จะชน 23505 (ทดสอบแล้วชนจริง)
- ⚠️ **`zone_id` ห้ามแก้** — ฝังอยู่ในรหัสทรัพย์แบบไม่มีตัวคั่น (`CASK020` = C+ASK+020) · รหัสใหม่ต้องเช็ค **prefix collision** ไม่ใช่แค่ซ้ำ (`RM` คู่กับ `RM2` ทำให้ `CRM2001` อ่านได้ 2 แบบ) — 30 โซนปัจจุบันสะอาด
- ลบโซนที่มีทรัพย์ไม่ได้ + บอกจำนวน (PHU มี 85)
- **ทดสอบ**: CEO แก้/มอบหมายได้ · agent เขียน 0 แถวทั้ง 2 ตาราง · ย้ายเจ้าภาพผ่าน · เจ้าภาพซ้ำถูกปฏิเสธ 23505 · เบราว์เซอร์ (Game): dropdown ถูก 31 ตัว ไม่มี ghost 4 ตัว · `/settings` ไม่โชว์ส่วนโซนเลย · DB เท่าเดิม 30/30
- ⚠️ **ยังไม่ได้ขับ UI ตัวแก้โซนในเบราว์เซอร์จริง** — มีแต่รหัสของ agent ส่วนนี้ gate ด้วย `masterdata.govern`

#### `/leave` (ใบลา 20 · โควตา 6)
ไฟล์ใหม่ [lib/mutations/leave.ts](haus-crm/lib/mutations/leave.ts) (`submitLeave`/`decideLeave`/`withdrawLeave`/`setLeaveAllowance`) · `getLeaveRequests()`/`getLeaveAllowances()` ใน [lib/queries.ts](haus-crm/lib/queries.ts) · `LeaveProvider` เลิกถือความจริงเอง รับจาก layout · **`RbacProvider` เพิ่ม `employeeCode`** (ของเดิม client เทียบ seed id `u_game` กับ employee_code จึงไม่เคยตรง = "ใบลาของฉัน" ว่างตลอดสำหรับ user จริง)

🔴 **ช่องโหว่ที่เจอ + ปิดแล้ว (apply บน production + มิเรอร์ลง `db/rls_policies.sql`)** — migration `leave_requests_own_update_pending_only`
`p_update` ท่อน "แถวของตัวเอง" **ไม่มีเงื่อนไข status** → เซลยิง REST `PATCH /leave_requests?id=eq.6 {"status":"approved"}` **อนุมัติใบลาตัวเองได้จริง** (ทดสอบยืนยันก่อนแก้) · ตัวที่กันอยู่มีแค่ด่านในแอป ซึ่งไม่ใช่ด่านสุดท้าย → เพิ่ม `and status='pending'` ทั้ง `using` และ **`with check`** (ถ้าใส่แต่ `using` การแก้ pending→approved ยังผ่าน) · `p_delete` ด้วยเหตุผลเดียวกัน (ลบใบที่ตัดสินแล้ว = ลบหลักฐาน)
- ยืนยันหลังแก้: เซลอนุมัติตัวเอง **0 แถว** · เซลลบใบที่ตัดสินแล้ว **ไม่ได้** · เซลยกเลิกใบ pending ของตัวเอง **ยังได้** · CEO อนุมัติ **ยังได้**

🐛 แบนเนอร์ `/today` เขียน "คุณลา**ลาป่วย**วันนี้" (ประเภทลาขึ้นต้นด้วย "ลา" อยู่แล้ว) — แก้แล้ว

#### `/team` (พนักงาน 10) — **ลบ PII ปลอมของคนจริงทิ้ง**
`lib/team.ts` เคยเก็บรายชื่อเพื่อนร่วมงานจริงทั้ง 10 คน **พร้อมเงินเดือน/เลขบัตร ปชช./เลขบัญชีที่แต่งขึ้น** → ลบทั้งก้อน เหลือแค่ type + helper
- **อ่าน**: `getEmployees()`/`getEmployee()`/`getZoneOptions()` — `main_1_hr` + `zone_sales`+`zone` + `user_roles`+`roles` + `teams` + **`v_employee_private`** (คอลัมน์อ่อนไหวถูก revoke ที่ base table มาทางอื่นไม่ได้)
- **เขียน**: [lib/mutations/employees.ts](haus-crm/lib/mutations/employees.ts) `updateEmployee`/`createEmployee` (เดิม `save()` เป็น `console.log`)
  ⚠️ **`update` บนคอลัมน์เงินเดือน/PII ไม่เคยถูก revoke — revoke แค่ `select`** → ใครมี `people.manage` เขียนทับได้ทั้งที่อ่านไม่ได้ ด่านเดียวที่กันคือ `FIELDS[].group` ในไฟล์นี้ **write path อื่นที่แตะ `main_1_hr` ต้องทำซ้ำ**
  ⚠️ **ห้ามรับ `employee_code` จากฟอร์ม** — trigger `set_hr_employee_code` อ่าน `second_position` ก่อน (Sales→S, Support→SP) แล้วค่อย fallback ไป `position` (CEO→C) → ส่ง `'Sales'` ให้ CEO จะได้ `S-006` ไม่ใช่ `C-002` ดังนั้น "ผู้บริหาร" ต้องส่ง `second_position = null` (ทดสอบครบ 3 ทาง: S-006 / SP-004 / C-002)

🐛 **2 คอลัมน์ที่เคยโกหกเพราะ RLS เป็น own-row** (pattern เดียวกับ Phase 5 ข้อ 6):
1. **กิจกรรมเดือนนี้** — `activities` own-row (`performance.view_team` + `visible_employee_codes()` ซึ่ง = ตัวเองคนเดียวเพราะ `teams` ว่าง) → เดิมจะโชว์ **0** ให้ทุกคนที่ไม่ใช่ตัวเอง = บอกว่าเขาไม่ทำงาน · แก้เป็น `null` → "—"
2. **บทบาท** — `user_roles` own-row เหมือนกัน → เดิมโชว์ "—" ให้เพื่อนทุกคนราวกับไม่มีบทบาท · แก้เป็น**ซ่อนคอลัมน์ทั้งคอลัมน์**เว้นแต่มี `roles.manage`/`people.manage`

**ตัดทิ้งเพราะไม่มีที่เก็บ**: ปุ่มอัปโหลดรูปโปรไฟล์ (ไม่มีคอลัมน์ + ไม่มี bucket — เดิมพรีวิวแล้วหายตอนบันทึก) · ชิปเลือกโซนในหน้าประวัติ (โซนอยู่ `zone_sales` คนละตาราง งานเขียนนี้ไม่แตะ → โชว์อย่างเดียว) · ช่องแก้รหัสพนักงาน
**พลอยได้**: `/new-sales` + ตั้งค่า → ทีม รับ roster จริงเป็น prop แล้ว (เดิมอ่าน seed ก้อนเดียวกัน) · กระดานเซลใหม่ว่างโดยตั้งใจ + **บอกเหตุผลบนจอ** ว่ารอ `date_started` · ลบ `assignableAgents()`/`defaultAssignee()` ที่ตายแล้วใน `lib/leads.ts`

**ทดสอบ (login Game/S-002 บน localhost)**: 10 แถวตรง DB · โซนเป็นชื่อไทย · ไม่มีคอลัมน์คอมมิชชั่น/บทบาท · ไม่มีปุ่มแก้ไข/เพิ่ม · 2 การ์ดอ่อนไหวล็อก · ค้นด้วยชื่อเล่น+รหัสได้ · รหัสมั่ว → 404 · ใบลา: โควตาโชว์ ลากิจ 8/3 เกิน 5 วัน (ตรง DB) · ยื่นใบลาจาก `/today` → แบนเนอร์ขึ้นเองไม่ต้องรีเฟรช → ยกเลิกที่ `/leave` → หายทั้งแถวและ audit · **0 console error** · คืนค่าครบ (ใบลา 20 · audit 13 · พนักงาน 10)

**ค้าง**: ยังไม่ได้ทดสอบหน้า `/team` ในเบราว์เซอร์ด้วยบัญชีที่มี `people.manage` (มีรหัสแค่ของ Game) — ฝั่ง DB ทดสอบครบแล้วว่า CEO เขียนได้ / agent เขียนไม่ได้ · `TeamsManager` ยังเก็บทีมใน memory (ตาราง `teams` ว่าง รอ CEO)

---

## 🔖 ก่อนหน้านี้ (2026-08-13)

### ✅ เสร็จ 2026-08-13: Phase 6 — `/contacts` (3/8) **ไม่ใช้ตาราง `contacts` เลย**
**Ben ตัดสินใจ**: ตั้งคำถามว่าตาราง `contacts` จำเป็นไหม ในเมื่อชื่อ+เบอร์เจ้าของอยู่ใน `main_2_owner` และของลูกค้าอยู่ใน `main_6_buyer_crm` อยู่แล้ว → **เลือกทางที่อ่านสดจาก 2 ตารางเดิม ไม่สร้าง/ไม่ import ตารางที่ 3**

**ตัวเลขที่ใช้ตัดสิน (นับจาก DB จริง):** เจ้าของ 452 (มีเบอร์ 401) · ลีด 953 (มีเบอร์ 891) · เบอร์ไม่ซ้ำรวม **1,169** · **คนที่เป็นทั้งเจ้าของและผู้ซื้อมีแค่ 5 ราย (0.4%)** → เหตุผลเดียวของตาราง unified คุ้มกับ 5 ราย แต่ต้องแลกกับชื่อ/เบอร์ 2 ชุดที่ต้องซิงก์ + snapshot ที่เก่าลงเรื่อยๆ

**วิธีที่ใช้**: `getContacts()`/`getContact()` ใน [lib/queries.ts](haus-crm/lib/queries.ts) อ่าน `main_2_owner` + `main_6_buyer_crm` + `v_main_listing` แล้วยุบด้วย **เบอร์โทรที่ตัดอักขระออกหมด** · id เป็น key สังเคราะห์ (`p<ตัวเลข>` / `o<owner_id>` / `l<lead_id>`) ไม่ใช่ PK ของตาราง
- **scoping ได้ฟรี** — 2 ตารางต้นทาง RLS คุมอยู่แล้ว เซลจึงเห็นเฉพาะเจ้าของทรัพย์ที่ตัวเองดูแล + ลีดของตัวเอง
- `lib/contacts.ts` เหลือแค่ type + helper (client-safe) · เพิ่ม role `agent` (นายหน้า) เพราะ `lead_type='Co-Agent'` มีจริง 47 ราย · แยก `ContactSummary` ออกจาก `Contact` เพื่อไม่ส่งรายการทรัพย์/ลีดของ ~1,200 คนลง browser
- ตาราง `contacts`/`contact_roles` **ยังอยู่ใน DB แต่ไม่มีใครใช้แล้ว (0 แถว)** — ถ้าจะลบทิ้งต้องสั่ง แต่ **ห้ามลบ permission `contacts.view_all`** เพราะเป็นตัวคุมการเห็นเบอร์เจ้าของใน `main_2_owner` + `v_main_listing`

**🐛 บั๊กที่เจอตอนทดสอบ (แก้แล้วทั้งคู่):**
1. 🔴 **ลีดหายทั้งหมด — หน้าโชว์แค่เจ้าของ 31 คน** เพราะ select ขอคอลัมน์ `remark` แต่ `main_6_buyer_crm` ใช้ชื่อ **`admin_remark`** → PostgREST error ทั้ง query แล้ว `?? []` กลืนเงียบ **แก้ชื่อคอลัมน์ + ใส่ `throw` เมื่อ query ล้ม** (ครึ่งหน้าที่เงียบๆ แย่กว่า error)
2. **ค้นเบอร์แบบไม่ใส่ขีดหาไม่เจอ** — ข้อมูลเก็บ `066-1532619` แต่คนพิมพ์ `0661532619` ซึ่งเป็น use case หลักของหน้านี้เลย → เทียบแบบตัดอักขระทั้ง 2 ฝั่ง

**ทดสอบแล้ว (login Game/S-002 บน localhost)**: เห็น **172 ราย** = ตรงกับที่คำนวณจาก SQL เป๊ะ (เจ้าของ 31 + ลีด 147 ยุบด้วยเบอร์) · ชิปบทบาท เจ้าของ 31 · ผู้ซื้อ 134 · ผู้เช่า 1 · ปล่อยเช่า 1 · นายหน้า 6 · ค้นเบอร์ได้ทั้ง 3 แบบ (`0661532619` / `066-1532619` / `1532619` → เจอคนเดียวกัน) · กรองบทบาทได้ · เปิดหน้ารายคนเห็นทรัพย์ที่เป็นเจ้าของ + ความสนใจจริง · **0 console error**

### ↩️ 2026-08-13: เพิ่มชั้น "ทีม" ให้สิทธิ์ดูเจ้าของ แล้ว**ถอนกลับในวันเดียวกัน**
Ben สั่งครั้งแรกว่า *"Owner เฉพาะของตัวเอง ยกเว้น Admin CEO และ Leader ของเขา"* → ทำ permission `contacts.view_team` + ชั้นกลางใน policy ของ `contacts` และ `main_2_owner` (ทดสอบผ่าน: จำลองหัวหน้าคุมทีม 3 คนเห็น 220 ราย ไม่ใช่ 452) **แล้ว Ben เปลี่ยนเป็น "หัวหน้าทีมให้เห็นทั้งหมด"** → ไม่มีใครเหลือในชั้นกลาง จึงถอนทั้งหมดออก (permissions กลับเป็น **36**, `sales_leader` ได้ `contacts.view_all` คืน, policy กลับเป็น own → all เหมือน Phase 4)

**กติกาที่ใช้จริงตอนนี้**: เซล = เฉพาะเจ้าของทรัพย์ที่ตัวเองดูแล · **Admin / CEO / หัวหน้าทีม / Listing Support = เห็นทั้งหมด** · Marketing = ไม่เห็นเลย
- Listing Support อยู่ชั้น "ทั้งหมด" โดยตั้งใจ — งาน Support คือโทรหาเจ้าของของทรัพย์ที่ตัวเอง**ไม่ได้**ดูแล (`main_4.sale_id` ไม่เคยเป็น `SP-xxx`) ถ้า scope จะมองไม่เห็นเจ้าของเลยสักราย
- ยืนยันหลังถอนแล้ว: permissions 36 · agent (Mhow) เห็น 99 ราย เท่าเดิม · `contacts` ยัง 0 แถว ไม่เคยถูกแตะ

### ✅ เสร็จ 2026-08-13: Phase 6 — `/projects` · `/last-match` (2/8)
**เสร็จรอบนี้:**
- **`/projects` + `/projects/[id]`** — อ่าน `main_3_property_detail` จริง **308 โครงการ** · id เปลี่ยนจาก slug เป็น `project_id` จริง (`PROJECT-006`) · แมปชื่อคอลัมน์ที่ไม่ตรงกัน (`units`←total_units · `age`←project_age · `common_area`←facilities · `resident_persona`←resident_occupation · `closing_price`←project_sold_price) · `flooding` เป็น boolean → แปลงเป็น "เคยท่วม"/"ไม่ท่วม" โดย **null ต้องยังเป็น "ไม่ระบุ"** (ไม่ใช่ "ไม่ท่วม")
- **`/last-match`** — อ่าน `main_7_last_match` จริง 56 แถว · **ถอด client-side scoping ทิ้ง** เพราะ RLS ทำ own/team/all ให้อยู่แล้ว (ของเดิมเทียบ seed user id กับ seed employee code → session จริงไม่เคยแมตช์ จะทำให้ตารางว่าง) เหลือ `matchScope()` ไว้ตัดสินแค่ว่าจะโชว์คอลัมน์ "เซลส์" ไหม
- **`listings/[id]` → โครงการ** — เลิกเทียบชื่ออังกฤษแบบหลวมๆ เปลี่ยนไปใช้ FK `project_id` ตรงๆ (ชีทใส่ชื่อไทยในช่องอังกฤษ เทียบชื่อเจอ 1/508)

**🐛 บั๊กที่เจอระหว่างทาง (ทั้งหมดมีมาก่อน แก้แล้ว):**
1. 🔴 **`lib/listings.ts` สุ่มผู้ดูแลทรัพย์จาก hash ของ listing_id** — `listingAgent()` เป็นของยุค design-first แต่ยังใช้อยู่จริงใน **`/company-listings`** (หน้าที่มีไว้หา Co-Agent) และ **`ListingOwnerCard`** → **เบอร์โทรที่โชว์เป็นของเพื่อนร่วมงานที่สุ่มมา** และ `isManager` (ตัวตัดสินว่าจะโชว์เบอร์เจ้าของไหม) ก็ตัดสินจากคนสุ่มนั้น (RLS ยังกันข้อมูลจริงอยู่ แต่ UI ไม่ตรงกับ RLS) — **แก้: ใช้ `effective_sale_id` จริง + `getStaffDirectory()` · คำนวณ `isManager` ที่ server จาก employee_code ของ session · ลบ `lib/listings.ts` ทั้งไฟล์**
2. **หน้าทรัพย์โชว์ UUID ดิบ** — ช่อง "ผู้ดูแล" อ่าน `created_by` ซึ่งเก็บ `auth.users.id` และ **ทั้ง 511 แถวเป็น uuid เดียวกัน** (บัญชี admin ที่รัน import) → โชว์ `1fa17e8b-...` กลางจอ · แก้เป็นแมปเป็นชื่อเล่น + **เปลี่ยนป้ายเป็น "ผู้สร้างรายการ"** (ผู้ดูแลจริงมีการ์ดของตัวเองอยู่แล้ว)
3. **`main_7_last_match.date_created` มี 6 แถวเป็น `1899-12-30`** (Excel serial-zero = ช่องวันที่ว่างตอน import) โชว์เป็น "30/12/1899" — **กันที่ชั้นอ่าน** (วันที่ก่อนปี 2000 = ไม่ระบุ) **ยังไม่ได้แตะข้อมูลใน DB** → ถ้า Ben อยากให้ล้างเป็น null สั่งได้
   - เช็คแล้วคอลัมน์วันที่อื่นไม่โดน (main_4/main_6/main_3/activities/birthday = 0)

**ทดสอบแล้ว (login Game/S-002 บน localhost)**: `/projects` 308 + ชิปโซนเป็นชื่อไทยครบ 24 โซน ตรงกับ `count(*)` ใน DB · เปิด `PROJECT-006` เห็นข้อมูลจริง 42% · id มั่ว → 404 · `listings/HPHU001` → ลิงก์ไป `/projects/PROJECT-207` ถูก · `/last-match` Game เห็น **1 แถว** (มีจริง 1 แถวใน DB → RLS own-scope ถูก) · ไม่มี 1899 · ไม่มี UUID · `/company-listings` 511 แถว **ผู้ดูแล+เบอร์ตรงกับ DB ทุกแถวที่สุ่มเช็ค** (CCRK026→Mhow · CCWT086/CPCC078→Golf) · 0 console error

**ค้าง**: คอลัมน์ "เซลส์" ใน `/last-match` โชว์เฉพาะคนที่มี `lastmatch.view_team/all` — บัญชีที่ใช้ทดสอบเป็น agent เลย**ยังไม่ได้เห็นคอลัมน์นั้นจริงในเบราว์เซอร์** (ตรวจที่ระดับ query แล้วว่าแมปชื่อเล่นถูก)


### ✅ เสร็จ 2026-08-13: Phase 5 ข้อ 6 — ติ๊กงาน `/today` เขียนจริง → **ปิด Phase 5 ครบ 6/6**
**ทำเฉพาะ "ปุ่มติ๊ก" ไม่ได้** — ต่างจากข้อ 1-5 ที่หน้าอ่านข้อมูลจริงอยู่แล้ว `/today` **ยังเป็น seed ทั้งหน้า**: `tasks`/`targets`/`user_quick_actions` **ว่าง 0 แถวทั้ง 3 ตาราง** · `currentAgent()` ฮาร์ดโค้ด `"Stone"` · `TODAY` ฮาร์ดโค้ด `2026-07-13` · งานอยู่ใน React state (id `t_1`) → จะติ๊กให้เขียน DB ได้ ต้องมี "งานจริง" ที่มี id จาก DB ก่อน จึงต้องต่อ **อ่าน+เพิ่ม+แก้+ลบ** ทั้งชุด (= ข้อ 6 + ส่วน `/today` ของ Phase 6 รวบทำทีเดียว) **Ben สั่งเอาทั้ง 2 ฝั่ง** (แผนงาน + เป้าหมาย)

**ไม่ต้องแตะ DB เลยรอบนี้** — schema + RLS ครบตั้งแต่ 2026-08-03 · `tasks`/`activities` policy เป็น own-row (`employee_code = current_employee_code()`) ซึ่ง SELECT ตัวเองได้ → **ไม่ต้องทำ RPC** ต่างจาก `create_owner`/`create_lead` · `activities.task_id` มี `unique` + `on delete cascade` ตามดีไซน์

**ไฟล์ใหม่ (ใน `haus-crm/`)**: [lib/plan.ts](haus-crm/lib/plan.ts) (อ่านทั้งหน้า) · [lib/mutations/tasks.ts](haus-crm/lib/mutations/tasks.ts) · [lib/mutations/targets.ts](haus-crm/lib/mutations/targets.ts)
**เขียนใหม่**: `lib/momentum.ts` (ตัด seed เหลือ type+helper, id เป็น `number`, `todayISO()`) · `DailyPlan.tsx` · `TargetsBoard.tsx` · `TaskDetailSheet.tsx` · `today/page.tsx` · `lib/quickAdd.ts` · +`searchLeads()` ใน `lib/search.ts`

**🐛 บั๊กที่เจอ (มีมาก่อนงานนี้ทั้งหมด — จะระเบิดทันทีที่เริ่มเขียนจริง):**
1. **ตัวเลือกลูกค้า/ทรัพย์ในฟอร์มงานเป็นของปลอม 7 ตัว** (`SAMPLE_LEAD_OPTIONS`/`SAMPLE_LISTING_OPTIONS`: `L-0007`, `TCYP001`…) ซึ่ง**ไม่มีอยู่ใน DB สักตัว** ทั้ง `tasks.related_lead_id` และ `activities.related_lead_id` เป็น FK → บันทึกล้มทุกครั้ง **ลบทิ้งทั้ง 2 ค่า** เปลี่ยนเป็น combobox ค้นจริง (debounce 250ms)
2. **`ACTION_GROUPS` ขาด 3 กิจกรรมที่มีจริงใน `action_type`** — `Owner Talk` (ชื่อ KPI ทางการตัวแรกเลย) · `Update Price` · `เซ็นสัญญา` (seed 20 vs DB 23) → เปลี่ยนมาโหลดจากตารางจริง (บั๊กชุดเดียวกับ `COMPLAINT_STATUSES` / vocabulary ของฟอร์มลีด)
3. ⚠️ **RLS เป็นเพดาน ไม่ใช่ตัวกรอง — ต้องกรอง `employee_code` เองทุก query** `tasks`/`targets` policy เปิดให้ `roles.manage` ด้วย และ `activities` เปิดให้ `performance.view_team` → ถ้าพึ่ง RLS อย่างเดียว **แผนงานของ Admin จะโชว์งานทั้งบริษัท** และเป้าหมายของหัวหน้าทีมจะนับกิจกรรมของลูกทีมเป็นของตัวเอง (จำไว้ใช้กับทุกหน้าที่เป็น "ของส่วนตัว" ใน Phase 6)

**🐛 บั๊กที่งานนี้สร้างเองแล้วเจอตอนทดสอบ (แก้แล้ว — ทั้งคู่เป็น pattern ที่ต้องใช้กับ write path ทุกจุดต่อจากนี้):**
- **A. `run()` ไม่มี try/catch** — server action **reject** ได้ (คนละเรื่องกับ return `{ok:false}`) เช่นเน็ตหลุด/request ถูก abort → `void run(...)` กลืน rejection, `busy` ค้าง true, ไม่ขึ้น error, **แต่ optimistic tick ยังโชว์ว่าติ๊กแล้ว** ทั้งที่ DB ไม่มีอะไรเลย (เจอจริง: งานถูก rollback เป็น `done=false` แต่จอขึ้น "เสร็จ 2 จาก 2")
- **B. ปลด `busy` เร็วเกินไป** — เดิมปลดตอน action ตอบ แต่ `router.refresh()` ยังไม่ลง → คลิกติ๊กในช่วงนั้นทำงานกับ **render เก่า** ทำให้งานที่เพิ่งผูกกิจกรรมถูกติ๊ก**โดยข้ามหน้าต่างยืนยัน** count/remark หายเงียบ (พิสูจน์แล้ว: activity ได้ `remark=null`) **แก้ด้วย `useTransition` ครอบ `router.refresh()` แล้วนับ `isPending` เป็น busy ด้วย**

**ทดสอบจริง (login เป็น Game / S-002 / role `agent` บน localhost — Ben ให้รหัสมาทดสอบ):**
- ระดับ DB จำลอง session: สร้างงาน → ติ๊ก → เขียน activity → ยกเลิกติ๊ก → activity หาย → ลบงาน → cascade ครบ
- เบราว์เซอร์จริง: หน้าโชว์ "แผนงานและเป้าหมายของ Game" + วันที่ **13/08/2026 (นาฬิกาจริง)** · เพิ่มงาน + ปุ่มลัด → เขียน `tasks` · ติ๊ก → หน้าต่างยืนยัน → `activities` count 3 → **เป้าหมาย auto ขยับเป็น 3/5 ทันที** · ยกเลิกติ๊ก → **กลับเป็น 0/5** (activity ถูกลบจริง) · ติ๊กใหม่ count 2 → 2/5
- แก้งาน: dropdown มี **24 ตัวเลือก** (23 กิจกรรม + ไม่ผูก) ยืนยันว่ามี `Owner Talk`/`Update Price`/`เซ็นสัญญา` ครบ · ค้นทรัพย์ "HPHU" ได้ 8 รายการจริง → เลือก `HPHU001` → บันทึก → **แถวโชว์ชื่อโครงการจริง** → ติ๊ก → activity ได้ `related_listing_id='HPHU001'` + remark ถูก
- ปุ่มลัด/ลบเป้าหมาย/ลบงาน ผ่านครบ · **0 console error ทุกรอบ**
- **ลบข้อมูลทดสอบครบ** — tasks 0 · targets 0 · activities กลับเป็น **2334** (cascade เอา activity ไปด้วย) · user_quick_actions 0 · audit_log กลับเป็น 13 แถว · ทรัพย์ 511 / ลีด 953 เท่าเดิม

**ค้างไว้ (ตั้งใจ ไม่ใช่ของลืม):**
- **`targets` ยังตั้งได้เฉพาะของตัวเอง** — เป้าหมาย "ทางการ" ต้องมีหน้าจัดการทีม แต่ `teams` ยังว่าง → `visible_employee_codes()` = ตัวเองคนเดียวสำหรับทุกคนอยู่แล้ว ตั้งให้คนอื่นยังไง RLS ก็ปฏิเสธ (รอ CEO กำหนดหัวหน้าทีม)
- `source='kpi'`/`'pipeline'` ยังอ่านค่าที่เก็บไว้ (`manual_current`) — ต้องมี `summary_kpi` rollup ก่อน (Phase 6)
- **กฎ "ทำซ้ำ" บันทึกลง DB แล้วแต่ยังไม่สร้างงานของวันถัดไปให้** (มีข้อความบอกในฟอร์มแล้ว)
- แบนเนอร์ "ลาวันนี้" ใน `/today` ยังอ่าน seed (`/leave` เป็น Phase 6) — เทียบด้วยชื่อเล่น ใครไม่อยู่ใน seed ก็ไม่ขึ้น
- `TODAY` ใน `lib/momentum.ts` **ยังต้องคงไว้** (มี 8 ไฟล์ที่ยังเป็น seed อ้างอยู่: leave/probation/notifications/new-sales) — ทำเครื่องหมาย `@deprecated` ไว้แล้ว ลบตอน Phase 6

**หมายเหตุเครื่องมือ**: แก้บั๊ก Windows ของ `browser-automation/browser.mjs` แล้ว — `--script` ใช้ `pathToFileURL()` แทน path ดิบ (เดิม path `C:\...` โดน ESM loader อ่านเป็น protocol `c:` แล้ว throw ใช้ `--script` บน Windows ไม่ได้เลย)

---

## 🔖 ก่อนหน้านี้ (2026-08-11)

### ✅ เสร็จ 2026-08-11: Phase 5 ข้อ 5 — เพิ่มทรัพย์เขียนจริง (`ListingIntakeButton` / `ListingForm`)
ฟอร์มนี้ถูกออกแบบก่อน schema นิ่ง เลยมี **3 จุดที่เขียนตรงๆ ไม่ได้เลย** (เจอจาก query DB จริง):

1. 🔑 **`main_4_listing_database` ไม่มีคอลัมน์ `listing_name`** — ชื่อทรัพย์ที่โชว์ทุกหน้ามาจาก view: **`v_main_listing.listing_name = main_3_property_detail.project_name_thai`** ผูกผ่าน `project_id` แต่ฟอร์มมีช่อง "ชื่อทรัพย์" เป็น free text + บังคับกรอก ซึ่งไม่มีที่เก็บ → **ทรัพย์ที่สร้างจะไม่มีชื่อทุกหน้า** · **Ben เลือก: ช่องโครงการเป็นตัวค้นหาจริง + สร้างโครงการใหม่ได้ในฟอร์ม** แล้วตัดช่อง "ชื่อทรัพย์" ทิ้ง (ไม่แก้ schema)
2. **trigger `set_listing_id` โยน exception ถ้าไม่มี `zone`** (`raise exception 'ต้องระบุ property_type และ zone ก่อน'`) แต่ฟอร์มให้เลือก "— ไม่ระบุ —" ได้ → **บันทึกล้มทุกครั้ง** · แก้: บังคับเลือกทั้ง 2 ช่อง + เช็คที่ชั้นแอปก่อน ให้ขึ้นข้อความไทยแทน exception ดิบ
3. `listZones()`/`assignableAgents()` เป็น sample (ชื่อเล่น) ทั้งที่ `sale_id` เป็น FK → `employee_code` — บั๊กเดียวกับ `/assign` ข้อ 4

**🐛 บั๊กแฝงที่เจอระหว่างทาง (จากงาน Phase 5 ข้อ 1 เอง)**: `LISTING_FIELDS` ใน `updateListing` มี `listing_name` อยู่ด้วย ทั้งที่ **ไม่ใช่คอลัมน์ของ main_4** → ใครแก้ช่อง "ชื่อทรัพย์" ใน `ListingEditSheet` จะได้ error จาก Postgres ทันที (ตอนทดสอบ 08-07 แก้แค่ remark/status เลยไม่โดน) — **แก้แล้ว**: ถอดออกจาก map + ทำช่องนั้นเป็น read-only พร้อมบอกว่าชื่อมาจากโครงการ

**ไม่ต้องทำ RPC รอบนี้** (ต่างจากข้อ 1/3) — ทุก role ที่มี `listings.create` มี `listings.view` ครบ และ SELECT policy ของ `main_4`/`main_3` เป็นการเช็คสิทธิ์ล้วน **ไม่ scope ตามแถว** → `.insert().select('listing_id')` ผ่านปกติ (ต่างจาก `main_2_owner` ที่ SELECT ผูกกับ "ต้องมี listing โยงอยู่แล้ว" จึงยังต้องใช้ `create_owner` RPC เดิม)

**ไฟล์ที่แก้ (ใน `haus-crm/`):** `lib/mutations/listings.ts` (+`createListing`, +`createProject`) · `lib/search.ts` (+`searchProjects`) · `lib/lookups.ts` + `MasterDataProvider` (+`listingPotentials` — ของเดิม `POTENTIALS` มี 3 ค่า แต่ตาราง `listing_potential` จริงมี **5** ขาด `A List + Fb add`/`Exclusive A`) · `lib/newListing.ts` (ตัด `listing_name`, ใส่ `project_id`) · `ListingForm.tsx` (เขียนใหม่ทั้งไฟล์) · `ListingIntakeButton.tsx` + `listings/page.tsx` (ส่ง agents)

**ทดสอบแล้ว (login เป็น Mhow / S-004 / agent — จงใจใช้คนที่มี `listings.create` แต่ **ไม่มี** `projects.edit`)**: เลือกโครงการที่มีอยู่ → ได้ `CASK020` (C=คอนโด + ASK=อโศก prefix ถูก) **และหน้าทรัพย์มีชื่อโชว์จริง** · สร้างโครงการใหม่จากในฟอร์ม → `PROJECT-325` + ทรัพย์ `HSLY086` ได้ชื่อจากโครงการใหม่ (พิสูจน์ว่า policy `main_3` ที่รับ `listings.create` ใช้งานได้จริง) · เจ้าของถูกสร้างผ่าน `create_owner` + ผูก `owner_id` · `audit_log` ครบ (`changed_by='S-004'`) · trigger `main_9_support_log` เขียน `action='created'` เอง · **ลบข้อมูลทดสอบครบ ยอดกลับเป็น 511/308/452**

---

## 🔖 ก่อนหน้านี้ (2026-08-10)

### ✅ เสร็จ 2026-08-10: Phase 5 ข้อ 4 — มอบหมายลีดอัตโนมัติ (แมปชื่อ→รหัส) + `/assign` เขียนจริง
**Ben เปลี่ยนทิศทางระหว่างวางแผน**: ไม่ต้องมีคนนั่งกดมอบหมายทีละราย เพราะลีดที่เข้ามา**ระบุชื่อเซลมาอยู่แล้ว** (ช่อง "Sales Assigned" ในฟอร์มรับลีด) ระบบควรแมปชื่อ → `employee_code` ให้เอง — **ข้อมูลจริงยืนยันว่าถูก: ลีด 952/953 มี `sale_id` ครบแล้ว** เหลือไม่มีคนดูแลแค่ 1 ราย

**DB (apply บน production + มิเรอร์ลง `db/rls_policies.sql` แล้ว):**
- **`resolve_employee_code(name)`** — เทียบ **ตรงตัว** case-insensitive: `nickname` → `first_name_en` → `first_name_th` · เฉพาะ Active · เจอไม่ชัดหรือหลายคน → คืน `null` ไม่เดา
  ⚠️ **ห้ามใช้ substring/prefix matching เด็ดขาด** — "Q" เป็นชื่อเล่นจริงของ S-003 ถ้าใช้ `like '%q%'` จะแมปมั่วครึ่งบริษัท
- **`create_lead` รับ `sale_name` เพิ่ม** — ไม่มี `sale_id` ก็แปลจากชื่อให้ (n8n/ฟอร์มใช้ได้ทันที) · **ชื่อที่แมปไม่ได้ไม่ทำให้ insert ล้ม** ลีดยังถูกสร้างแต่ `sale_id` เป็น null แล้วไปโผล่ในตัวกรอง "ยังไม่มอบหมาย" (ทำลีดลูกค้าหายเพราะพิมพ์ชื่อผิด = แย่กว่ามาก)

**แก้ 3 บั๊กบนหน้า `/assign` ที่มีมาก่อนงานนี้** — ทั้งหมดเป็นอาการเดียวกัน: **โค้ดเทียบชื่อเล่นกับ employee_code**
1. dropdown ผู้ดูแลเทียบไม่เคยตรง เลยตกไป fallback **โชว์รหัสดิบ `S-004`** แทนชื่อคน (ตัวกรอง + CSV export ก็โดนด้วย)
2. ป้าย "เจ้าของทรัพย์" ใช้ `defaultAssignee()` จาก sample 6 ตัวปลอม → **ไม่เคยขึ้นเลย** (ถอดออก เพราะ `/assign` ไม่มีข้อมูลผู้ดูแลทรัพย์จริงให้เทียบ)
3. คอลัมน์ "ช่องทาง" ฮาร์ดโค้ด `null` พร้อมคอมเมนต์ว่า "main_6 ไม่มีคอลัมน์ source" — **ผิด** มี `marketing_channel` อยู่จริง แค่ `CrmRow` ไม่ได้ select
- เจอเพิ่มตอนทดสอบ: หน้าลีดโชว์รหัสดิบอีก 2 จุด (แถว "ผู้ดูแล" + บรรทัดผู้ทำในไทม์ไลน์) แก้ให้เป็นชื่อแล้ว

**ไฟล์ที่แก้ (ใน `haus-crm/`):**
- **[lib/mutations/leads.ts](haus-crm/lib/mutations/leads.ts)** — เพิ่ม `assignLead()` เช็ค `leads.assign` → update `sale_id` → `audit_log` (`action='assign'`) · **ไม่ต้องทำ RPC** ต่างจากข้อ 1/3 เพราะเป็น UPDATE ธรรมดา ไม่ต้องอ่านค่าที่ DB สร้างกลับมา (RLS เดิมรองรับอยู่แล้ว)
- **[lib/leadHistory.ts](haus-crm/lib/leadHistory.ts) (ใหม่)** — `getAssignHistory()` อ่านประวัติจริงจาก `audit_log` ⚠️ `audit_log` อ่านได้เฉพาะ `roles.manage` → คืน `readable:false` แยกจาก "ไม่เคยมีประวัติ" (ไม่งั้นคนทั่วไปจะเห็นช่องว่างที่**โกหกว่าลีดไม่เคยถูกย้ายมือ**)
- **[components/LeadAssignment.tsx](haus-crm/components/LeadAssignment.tsx)** + **[LeadTimeline.tsx](haus-crm/components/LeadTimeline.tsx)** — dropdown เขียนจริง + optimistic override + agents จาก DB (เก็บ employee_code โชว์ชื่อเล่น)
- **[lib/queries.ts](haus-crm/lib/queries.ts)** — เพิ่ม `marketing_channel` เข้า `CrmRow`
- **ลบ [components/NewLeadsProvider.tsx](haus-crm/components/NewLeadsProvider.tsx) ทิ้งทั้งไฟล์** — ไม่มีใครใช้แล้ว ปิดฉาก store in-memory ยุค design-first

**ทดสอบแล้ว**: `resolve_employee_code` ครบทุกเคส (`Mhow`/`mhow`/`MHOW`/เว้นวรรค → S-004 · `Q` → S-003 · ชื่อไทย/อังกฤษ → C-001 · คนลาออก/ชื่อมั่ว/ว่าง/null → null) · `create_lead` ด้วยชื่อ → sale_id ถูก, ชื่อมั่ว → ลีดถูกสร้างแต่ไม่มอบหมาย · เบราว์เซอร์จริง login E-001 → `/assign` dropdown โชว์ชื่อไม่ใช่รหัสแล้ว → ย้าย `L26-018` จาก Mhow → Game → เช็ค DB + `audit_log` ตรง → หน้าลีดโชว์ประวัติจาก `audit_log` และ**ไม่หายหลังรีเฟรช** → คืนค่าครบ (953/952/0)

---

### ✅ เสร็จ 2026-08-10: Phase 5 ข้อ 3 — เพิ่มลีดเขียนจริง (`LeadIntakeFab` / `LeadForm`)
**ใหญ่กว่าข้อ 1-2 มาก** เพราะฟอร์มนี้ถูกออกแบบไว้ตอน design-first โดยใช้ vocabulary ที่**ไม่ตรงกับ DB เลยสักตัว** — ถ้าต่อ insert ตรงๆ จะ FK violation ทุกครั้ง (บั๊กแบบเดียวกับ `COMPLAINT_STATUSES` ข้อ 2 แต่กระจายทั้งฟอร์ม: `ddproperty` vs `Ddproperty` · `line_oa` vs `LINE OA` · `male` vs `Male` · `ไทย` vs `Thai` · `buyer`/`owner` vs `Buyer - Buy`/`Owner - Sale` · ชื่อเล่น `Mhow` vs `S-004`)

**Ben ตัดสินใจ 4 ข้อ**: เขียน `main_5` → `main_6` ทั้งคู่ · โหลด vocabulary จาก DB จริง · เพิ่มคอลัมน์ใน DB · ให้ `leads.view_all` กับ `listing_support`

**DB (apply บน production + มิเรอร์ลงไฟล์ setup แล้วทั้ง 2 ไฟล์):**
- **lookup ใหม่ 2 ตาราง** `lead_purpose` · `sell_reason` (+ RLS policy ครบ — ตารางใหม่ต้องเขียน policy เองเสมอ เพราะ `rls_auto_enable()` ของ Supabase บังคับเปิด RLS ให้ ถ้าไม่มี policy จะอ่าน dropdown ไม่ได้เลย)
- **4 คอลัมน์ใหม่บน `main_6_buyer_crm`** — `interest_zone` · `interest_property_type` · `purpose` · `sell_reason` (เลือก main_6 ไม่ใช่ main_5 เพราะแอปอ่าน main_6 ทุกที่ + เป็นข้อมูลที่เซลแก้ได้เรื่อยๆ ส่วนราคาที่เจ้าของต้องการใช้ `budget` ช่องเดิม)
- **RPC `create_lead(p jsonb)`** (`security definer`) — เขียน main_5 (trigger สร้าง lead_id) + main_6 (`lead_ref` ผูกกลับ) ในทรานแซกชันเดียว **กับดักเดิมของ `main_2_owner` ซ้ำอีกรอบ**: `insert ... returning lead_id` โดน SELECT policy เช็คด้วย → admin ที่มอบลีดให้คนอื่น และ `listing_support` (ไม่มีสิทธิ์ดูลีดเลย) อ่านแถวที่ตัวเองเพิ่งเขียนไม่ได้ ชน 42501
- **`listing_support` ได้ `leads.view_all`** ตามที่ Ben สั่ง (เดิมมี `leads.create`+`leads.assign` แต่ดูลีดไม่ได้เลย — สร้างเสร็จแล้วมองไม่เห็นของตัวเอง)

**🐛 บั๊กที่เจอจากการทดสอบ (ไม่ได้เกิดจากงานนี้ แต่จะระเบิดทันทีที่เริ่มใช้)**: `main_5_lead_database` **ว่าง 0 แถว** (import 2026-08-03 ลงแต่ main_6) แต่ trigger `set_lead_database_id` นับเลขจาก main_5 ตารางเดียว → ลีดใหม่จะได้ `L26-001` แล้วไล่ขึ้นไป **ชน `L26-007` ที่มีอยู่จริงในลีดที่ 7** (PK collision, insert ล้มทั้งรายการ) — **แก้ trigger ให้นับจากทั้ง 2 ตาราง** (ทั้งคู่ใช้ id ชุดเดียวกันโดยดีไซน์) ทดสอบแล้วได้ `L26-990` → `L26-991` ต่อเนื่องถูกต้อง

**ไฟล์ที่แก้ (ใน `haus-crm/`):**
- **[lib/lookups.ts](haus-crm/lib/lookups.ts) (ใหม่)** — `getLookups()` ดึง 9 lookup จริงจาก DB + `getAssignableAgents()` ดึงเซล Active จาก `main_1_hr` (คืน employee_code) · `lead_type` เรียงตามลำดับธุรกิจไม่ใช่ตัวอักษร (ไม่งั้นเลือก "เจ้าของ" แล้ว default เป็น `Owner - Others` แทน `Owner - Sale`)
- **[lib/search.ts](haus-crm/lib/search.ts) (ใหม่)** — `searchListings()` ค้นทรัพย์จริง 511 รายการ (เดิม hardcode ปลอม 6 ตัว) คืน `effective_sale_id` ให้ default ผู้รับมอบหมาย = เซลที่ดูแลทรัพย์นั้น
- **[lib/mutations/leads.ts](haus-crm/lib/mutations/leads.ts)** — เพิ่ม `createLead()` เช็คสิทธิ์ + บังคับว่าคนที่ไม่มี `leads.assign` จะยัด `sale_id` เป็นคนอื่นไม่ได้ (ลงชื่อตัวเองเสมอ) + `audit_log`
- **[components/LeadForm.tsx](haus-crm/components/LeadForm.tsx)** — dropdown ทุกตัวมาจาก DB · combobox ทรัพย์ค้นจริง (debounce 250ms) · assignee เก็บ employee_code · submit เขียนจริง + โชว์ `lead_id` ที่ได้กลับมา
- **[components/MasterDataProvider.tsx](haus-crm/components/MasterDataProvider.tsx)** — รับค่าจาก DB เป็น initial (seed เหลือเป็น fallback ตอนไม่มี session) + เพิ่ม `leadTypes`/`purposes`/`sellReasons`/`zones`
- **[lib/leads.ts](haus-crm/lib/leads.ts)** — `emptyLead()` ไม่ preset ค่า vocabulary อีกต่อไป (การเดา default คือต้นเหตุที่ seed slug หลุดเข้าฟอร์ม) · เพิ่ม `todayISO()` แทน `INTAKE_TODAY` ที่ hardcode `2026-07-20` · ลบ `nextLeadId()` (DB เป็นเจ้าของ id)
- **[components/NewLeadsProvider.tsx](haus-crm/components/NewLeadsProvider.tsx)** + **[LeadAssignment.tsx](haus-crm/components/LeadAssignment.tsx)** — ลบ `newLeads`/`addLead` (ลีดใหม่มาจาก DB แล้ว) เหลือ `assignments`/`assign`/`historyOf` ให้ข้อ 4

**ทดสอบแล้ว**: RPC ระดับ DB ทั้งในนาม E-001 และ **SP-001/listing_support** (เคสที่เดิมพัง) → ได้ lead_id ทั้งคู่ · negative case: agent (S-004, ไม่มี `leads.create`) ถูกปฏิเสธ 42501 · เบราว์เซอร์จริง login E-001 → buyer path (`L26-990`, ค้นทรัพย์ HPHU001 → assignee auto = S-004) + owner path (`L26-991`, `sell_reason` เขียนจริง, ฟิลด์ฝั่ง buyer เป็น null ถูกต้อง) · เช็ค main_5/main_6/audit_log ตรงหมด · ลบข้อมูลทดสอบครบ (953/0/452 เท่าเดิม)

**ค้างไว้ (ไม่เร่ง)**: `/assign` กับ `LeadTimeline` ยังใช้ `defaultAssignee()`/`assignableAgents()` จาก sample เดิม (เทียบชื่อเล่นกับทรัพย์ปลอม) — เป็นของ Phase 5 ข้อ 4 ที่จะแก้อยู่แล้ว · `lib/ai/parseLead.ts` ยังอ่านโซนจาก `SAMPLE_INTEREST_LISTINGS`

---

### ✅ แก้แล้ว 2026-08-08: หน้า `/leads/[id]` พังบางลีด — "Cannot read properties of undefined (reading 'kind')"
Ben เจอบน production ว่าลีด**บางคน**เปิดแล้ว error บางคนไม่ — **เป็นบั๊กตัวเดียวกันเป๊ะกับที่แก้ไปแล้วเมื่อ 2026-08-05** (`lib/tags.ts` signed shift) แต่คนละไฟล์ที่ตอนนั้นหาไม่เจอ

**สาเหตุ**: [lib/leadTimeline.ts](haus-crm/lib/leadTimeline.ts) ฟังก์ชัน `sampleTimeline()` ใช้ `h >> (i+1)` (signed shift) กับ hash ที่เป็น unsigned 32-bit — hash ≥ 2^31 จะได้ index ติดลบ → `SCRIPT[-n]` เป็น `undefined` → พังตอนอ่าน `.kind` (บรรทัด 50 `(h >> (i*2)) % 3` ก็ผิดแบบเดียวกัน ทำให้วันที่ในไทม์ไลน์เดินถอยหลังได้) — **แก้เป็น `>>>` ทั้ง 2 จุด**

**ยืนยันด้วยข้อมูลจริง** (วิธีเดียวกับรอบ 2026-08-05 ที่ได้ผล): ดึง lead_id จริงมารันฟังก์ชันตรงๆ นอกเว็บ → **245 จาก 478 ตัวอย่าง (~51%) พังพอดี** ตรงกับอาการ "บางคนขึ้น บางคนไม่" · แก้แล้วรันซ้ำ 0 error · ทดสอบผ่านเบราว์เซอร์จริงกับ 8 ลีดที่เคยพัง (login เป็น E-001) เรนเดอร์ครบ 0 console error

**⚠️ บทเรียนสำคัญ (รอบนี้เสียเวลาเพราะข้อนี้)**: รอบ 2026-08-05 แก้แค่ `lib/tags.ts` ไฟล์เดียวโดย**ไม่ได้ grep หาก็อปปี้อื่นของ hash function ตัวเดียวกัน** — บั๊กเลยกลับมาอีกใน 3 วัน **เวลาแก้บั๊กที่เกิดจาก helper ที่ถูกก็อปวาง ให้ grep หาทุกสำเนาเสมอ** (`grep 2166136261` เจอ 3 ไฟล์: `tags.ts` ✅ · `leadTimeline.ts` ✅ แก้รอบนี้ · `dashboard.ts` ใช้ `>>>` ถูกอยู่แล้ว ไม่ต้องแก้)

---

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
- ~~**`SUPABASE_SERVICE_ROLE_KEY` ตั้งไว้แค่ `.env.local` ในเครื่อง**~~ ✅ **เสร็จ 2026-08-10** — ตั้งใน Vercel (Production) + redeploy แล้ว ยืนยันด้วยการเรียกใช้จริงบน production
  - ⚠️ **บทเรียน: ตั้ง env var บน Vercel เฉยๆ ไม่พอ ต้อง redeploy ด้วย** — deployment ที่ build ไปแล้วมองไม่เห็นตัวแปรใหม่ รอบแรกที่เช็คยังได้ HTTP 500 อยู่ทั้งที่ตั้งค่าแล้ว
  - **วิธียืนยันที่ใช้ (ปลอดภัย ไม่กระทบใคร ใช้ซ้ำได้)**: login production เป็น E-001 → ตั้งค่า → บัญชีผู้ใช้ → "ตั้งรหัสผ่านใหม่" ให้ **E-001 เอง โดยกรอกรหัสเดิมเป๊ะ** → เป็นการเรียก `auth.admin.updateUserById` จริงแต่ผลลัพธ์ไม่เปลี่ยนอะไร → เช็ค `auth.users.updated_at` ขยับ + `audit_log` มีแถว `reset_password` ใหม่
  - **วิธีแยกสาเหตุตอนพัง**: รันโค้ดชุดเดียวกันบน `npm run dev` (ซึ่งมี key ใน `.env.local`) เทียบกับ production — สำเร็จที่ local แต่ 500 บน production = ตัวแปรไม่ถึง runtime ไม่ใช่บั๊กโค้ด · **key ผิด ≠ key หาย**: key ผิดจะได้ `Invalid API key` กลับมาใน UI สวยๆ ส่วน key หายจะ throw ที่ [lib/supabase/admin.ts:18](haus-crm/lib/supabase/admin.ts#L18) ก่อนยิง API เลย → server action ตอบ HTTP 500 ดิบๆ
- ยังไม่ได้ทดสอบ negative case (เรียก `resetUserPassword`/`createUserAccount` ตรงๆ ตอน login เป็นคนไม่มีสิทธิ์) แบบ live — เชื่อตาม pattern เดียวกับ `updateListing` ที่ทดสอบแล้วใน Phase 5 ข้อ 1 (permission check ก่อนแตะ DB เสมอ) แต่ยังไม่ได้ exploit-test ฟีเจอร์นี้ตรงๆ
- ไม่มีปุ่มลบบัญชี (auth) ในหน้านี้ — ถ้าต้องการ offboard คนออกจริงต้องทำ SQL ตรงหรือเพิ่มฟีเจอร์แยก

*(หมายเหตุ: "ขั้นต่อไป" ของหัวข้อนี้ทำครบหมดแล้ว — commit/push แล้ว · ตั้ง service_role key ใน Vercel แล้ว · Phase 5 ข้อ 2-4 เสร็จแล้ว)*

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
- ⚠️ **3 บรรทัดล่างนี้เป็นสถานะ ณ 2026-08-03 ที่ตกยุคไปแล้ว — อัปเดต 2026-08-13:**
- **สิ่งที่ต่อของจริงแล้ว**: auth + session + สิทธิ์จาก DB · `/account` เปลี่ยนรหัส · จัดการบัญชีผู้ใช้ · อ่านข้อมูลจริงทุกหน้าลีด/ทรัพย์/แผนวันนี้ · **เขียนจริงครบ 6/6 จุดของ Phase 5** (แก้ทรัพย์ · แก้ลีด/แท็ก/ข้อร้องเรียน · เพิ่มลีด · มอบหมายลีด · เพิ่มทรัพย์ · ติ๊กงาน+เป้าหมาย `/today`)
- **สิ่งที่ยังเป็นของปลอม**: store ในหน้า ตั้งค่า/กิจกรรม/วันลา ยังเก็บใน React Provider (refresh แล้วหาย) · ~8 หน้าที่ยังอ่าน seed (Phase 6)
- **RBAC ใน `lib/rbac.ts` = สเปก** ย้ายเข้า DB แล้ว (ตาราง `roles`/`permissions`/`user_roles`) และ ✅ **RLS ปิดครบแล้วตั้งแต่ Phase 4** — DB ปฏิเสธจริง ไม่ใช่แค่ UI ซ่อนเมนู
- **การตัดสินใจเรื่อง auth (Ben, 2026-08-03)**: login ด้วย **อีเมลส่วนตัว** (`main_1_hr.email` ไม่ใช่ `work_email`) และ **Admin ตั้งรหัสผ่านให้ user ได้** → ✅ **ทำแล้ว 2026-08-08** ที่ `/settings` → บัญชีผู้ใช้ (gate ด้วย `people.manage_accounts` ไม่ใช่ `people.manage` ตามที่คุยกันทีหลัง) · service_role key เก็บฝั่ง server เท่านั้น + ตั้งใน Vercel แล้ว 2026-08-10
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
