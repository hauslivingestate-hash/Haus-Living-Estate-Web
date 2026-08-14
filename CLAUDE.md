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

| ด้าน | สถานะ |
|---|---|
| ข้อมูล | ✅ import จากชีทครบ — ทรัพย์ **511** · ลีด **953** · โครงการ **308** · เจ้าของ **452** · กิจกรรม **2,334** · Last Match **56** · พนักงาน **10** · โซน **30** |
| Login | ✅ ใช้งานจริง — **9 บัญชี** (พนักงาน 8 + Admin) · บังคับ login แล้ว · มีหน้าเปลี่ยนรหัส `/account` · **CEO/HR สร้าง/รีเซ็ตรหัสให้คนอื่นได้แล้วที่ ตั้งค่า → บัญชีผู้ใช้** |
| สิทธิ์ | ✅ RBAC อยู่ใน DB — **36 สิทธิ์** · 8 บทบาท · ผูกกับพนักงานจริงแล้ว |
| DB | ✅ **56 ตาราง** (+`lead_purpose`/`sell_reason` 2026-08-10) · เงินเดือน/PII ล็อกแล้ว · +3 function (`create_owner` Phase 5 ข้อ 1 · `create_lead` ข้อ 3 · `resolve_employee_code` ข้อ 4) |
| ความปลอดภัย | ✅ **RLS Phase 4 ปิดครบแล้ว** — `demo_read_all` + anon ถูกถอนหมด (ดูรายละเอียดใต้ Phase 4) |
| ✅ การบันทึก | ✅ **Phase 5 ปิดครบ 6/6 แล้ว 2026-08-13** — ทุกปุ่ม save เขียน DB จริง · +ใบลา/ประวัติพนักงาน (2026-08-14) |

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
  - 🔴 **ตัวขวางจริงคือ ไม่มีตัวเลขรายได้ในระบบเลย** — `main_7_last_match.last_match_price` **ว่าง 0 จาก 56 แถว** · แดชบอร์ดตัวนี้พอร์ตมาจาก HAUS V2 โดยมี "รายได้" เป็นแกนกลาง ถ้าเปิดตอนนี้ **5 จาก 6 บล็อกในหน้าภาพรวมเป็น ฿0**
  - เป้าทีม (`teams.revenue_goal`) กับเป้า KPI (`targets`) ก็ว่างทั้งคู่
  - **สิ่งที่มีครบพอจะทำแดชบอร์ดได้ทันที**: กิจกรรม 2,334 แถว (10 เดือน) · ลีดใหม่รายเดือน 953/953 · ไปป์ไลน์ 835 (Call 521 → Show 149 → Win 21) · ทรัพย์ + ราคาประกาศ 491/511 · จำนวนดีลปิด 50
  - **3 ทางที่กางให้ Ben ดูแล้ว**: (ก) ทำใหม่ให้แกนเป็นกิจกรรม/ไปป์ไลน์แทนรายได้ (ข) กรอกราคาปิด 56 ดีลก่อนแล้วเปิดของเดิม (ค) เปิดของเดิมเลยแล้วยอมให้ว่าง — **Ben เลือกพักไว้ก่อน**
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
