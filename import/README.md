# import/ — วาง CSV จาก Google Sheets ที่นี่

โฟลเดอร์นี้รอไฟล์ข้อมูลจริงจากชีท 2 เล่ม เพื่อ import เข้า Supabase **ครั้งเดียวจบ**
(ตกลงกันแล้วว่าชีทจะเลิกใช้เมื่อระบบขึ้น — ไม่มี two-way sync ไม่มีรอบสอง)

## วิธี export
เปิดชีท → `File` → `Download` → `Comma-separated values (.csv)` ทีละแท็บ แล้วเอามาวางที่นี่

> **เอาทั้งแท็บมาเลย ไม่ต้องเลือกคอลัมน์** — รายการหัวข้อข้างล่างมีไว้ให้เช็คว่าไฟล์ที่โหลดมาถูกแท็บ
> ถ้าหัวข้อไม่ตรง แปลว่าชีทถูกแก้หลังจากที่เอกสารนี้เขียน บอกผมด้วย

---

## เล่ม 1 — "Stone Haus Living Listing"
`1sxgoXeyJ-bG_3NYo64sKvo1PxrA6yV5RsbDNXigB65M`

### `listings.csv` ← แท็บ **Listings** (~109 แถว, 61 คอลัมน์ A–BI)
| กลุ่ม | หัวข้อในชีท |
|---|---|
| ระบุตัวตน | Date Created · Listing Name · **Listing ID** · Listing Status · Potential · Hook · Owner Focus |
| การตลาด | Sign · VDO · Ddproperty · Livinginsider · Facebook · DD Boost · LV Boost · FB Repost · New Photo · Shorts/Reels · Hometour · Facebook Ad · Marketing Report |
| ราคา | Old Price · New Price · Update Remark · Last Match Price · Last Match Remark · Asking Price · Rental Price · Price Remark · Listing Type |
| สเปค | Project Name(Eng) · Unit no. · Property Type · ใน/นอกโครงการ · ถนน/ซอย · Zone · Bed · Bath · ไร่ · งาน · วา · ตรม.ใช้สอย · ชั้น · ทิศ · ตำแหน่ง · **อายุ** · **ส่วนกลาง** · Parking · Unit Condition |
| เจ้าของ | Owner's Name · Owner's Phone · Owner's LINE · วันที่ Owner Talk ล่าสุด · Activity Comment |
| อื่น ๆ | Remark · Photo Album · Link Location · Link · Last Match · Last Match Type · Created By · Days on Market |

### `buyer_focus.csv` ← แท็บ **Buyer Focus** (~176 แถว, 24 คอลัมน์ A–X)
Date Received · **Listing Code** · Potential · Lead Status · สนใจ · Lead Name · Phone · Admin Remark · LINE ID · Budget · Pipeline Stage · Progress · วันที่ Follow ล่าสุด · Activity Comment · Commission · Bank Loan · Closing Date · Transfer Date · Case Closing Remark · Complete · Confirm · Created By · **Lead ID** · Lead Type

### `projects.csv` ← แท็บ **Projects** (39 แถว, 25 คอลัมน์ A–Y)
Project ID · **Project Name (Eng)** · Project Name (Thai) · Property Type · Zone · จำนวนยูนิต · กี่เฟส · ประเภท Type ยูนิต · วัสดุ · พื้นถึงฝ้า · อายุโครงการ · ส่วนกลาง · ค่าส่วนกลาง · นิติบุคคล · นิติเก็บค่าส่วนกลางได้กี่ % · จอดเกินเสียคันละเท่าไหร่ · ราคาปล่อยเช่าในโครงการ · น้ำท่วมขังหรือไม่ · อาชีพลูกบ้าน · ราคาจบโครงการ · ข้อดี · ข้อเสีย · Sales Created By · Date Created · Date Updated

### `last_match.csv` + `last_match_entry.csv` ← แท็บ **Last Match** และ **Last Match กรอกข้อมูล** (118 แถว/แท็บ)
โครงเหมือนกัน 2 แท็บ (รวมเป็นตารางเดียว + คอลัมน์ `source`)
By · Type · Projects Name · Property Type · Zone · Sq.wa / Sq.m · Bed/Bath · Last Match Price · Last Match Remark · Buyer Persona · **Last Match ID** · Date Created

### `actions.csv` ← แท็บ **Actions** (289 แถว, 10 คอลัมน์ A–J)
Date · Sales · Action · จำนวน · ชั่วโมง · Remark · Recap · เกิดอะไรขึ้น? · เพราะอะไร? · Improvement Plan
> 3 คอลัมน์ท้ายว่างทั้งหมด — โหลดมาด้วยแต่จะไม่ import

---

## เล่ม 2 — "HR Sheet"
`1oJTQhWXUNj1ft78WY9aNvXLoTr5w1ApyN4mWMyQP0eY`

### `hr_employees.csv` ← แท็บ **Employee Lists** (~10 แถว, 31 คอลัมน์ A–AE) 🔴 **ต้องมาก่อนทุกไฟล์**
| กลุ่ม | หัวข้อในชีท |
|---|---|
| ตำแหน่ง | **Employee Code** · Status · Division · Position · 2nd Position · Zone (Sales) |
| ชื่อ | First/Last Name (Eng) · First/Last Name (Thai) · Nickname · Gender · Nationality |
| ติดต่อ | Phone · Additional Phone · Email · Assigned Work Email · Line (UserId) |
| การจ้าง | Birthday · Date Started · Sheet ID (Sales) · Remark · Employee Agreement Files |
| ฉุกเฉิน | Emergency Contact · Contact Phone · Contact Relationship |
| 💰 | Salary · Commission |
| 🔒 | ID Card no. · KBANK Account · PaySlip Drive |

### `hr_zones.csv` ← แท็บ **Zone** (~30 แถวจริง)
Zone ID · Zone Code · Name (Eng) · Name (Thai) · **Current Sales Assigned** · ~~Sales Sheet~~ · ~~Location~~ · ~~Date Updated/Created~~
> 4 คอลัมน์ท้ายตกลงว่า**ไม่เอา** — โหลดมาก็ได้ ผมจะข้ามให้

### `hr_dayoff.csv` ← แท็บ **Day off** (21 แถว)
Date Submit · Name · Start Date · End Date · Condition · Remark · ลิงค์กรอก

---

## ❌ ไม่ต้องเอา
| แท็บ | เหตุผล |
|---|---|
| `User Pass` (~1000 แถว) | รหัสผ่านพอร์ทัล/บัญชีโฆษณา — ไม่ใช่ข้อมูล CRM |
| `Spending` · `Comments` | ตกลงแล้วว่าไม่ย้าย — เก็บชีทไว้เป็น archive อ่านอย่างเดียว |
| `KPI Target` · `Owner` · `New Lead` | มีที่อยู่ในระบบแล้ว (ตั้งค่า → เป้าหมาย KPI / listing detail / ฟอร์มรับลีด) |

---

## ⚠️ ก่อน import ต้องทำก่อน

- [x] ~~เพิ่มคอลัมน์ที่ยังขาดใน DB~~ — ทำแล้ว 2026-08-03 (17 คอลัมน์ของ listing + 11 ของ buyer CRM)
- [x] ~~สร้างตารางที่แอปต้องใช้~~ — ทำแล้ว (activities, tasks, targets, contacts, leave, notifications, audit ฯลฯ · รวม 54 ตาราง)
- [ ] **import `hr_employees.csv` ก่อนเสมอ** — FK ทั้งระบบวิ่งเข้า `employee_code`
- [ ] ปิด policy `demo_read_all` ก่อน import ข้อมูล HR จริง (ไม่งั้นเงินเดือน/เลขบัตร ปชช. เปิดสาธารณะ) — ตกลงว่าปิดพร้อม auth
- [ ] รัน import ด้วย `service_role` key ไม่ใช่ anon (RLS จะบล็อก insert)

## สิ่งที่ผมจะแก้ให้ตอน import (ไม่ต้องแก้ในชีท)
วันที่ Excel serial → date · เบอร์โทรที่กลายเป็น `9.92e8` → เติม 0 กลับ · ราคา `1.7E7` → ตัวเลข ·
ส่วนกลาง 3 หน่วยปนกัน → เรต · อายุ → ปีที่สร้าง · typo โซน/ประเภททรัพย์ (`บ้้าน`, `ที่ี่ดิน`) ·
กิจกรรม 23 ค่า → 20 ค่ามาตรฐาน (รวม Show/Showing, Reels/ถ่าย Reels) · ใบลาซ้ำ 2 แถว ·
`"ลาป่วย "` มีเว้นวรรคท้าย · ชื่อเล่น → employee_code

## เรื่องที่ต้องถามคนก่อน import แท็บนั้น
| แท็บ | ถามใคร | เรื่อง |
|---|---|---|
| Day off | HR | ใบลา Golf `09/10/2026 → 20/06/2026` วันกลับด้าน — ที่ถูกคือ 9–20 ต.ค. ใช่ไหม |
| Day off | HR | โควตาวันลาจริง (ตอนนี้ใส่ขั้นต่ำตามกฎหมายไว้ 6/3/30 ซึ่งผิดแน่ ๆ) · ยกยอดข้ามปีไหม · ปีแรกได้เต็มหรือเฉลี่ย |
| Listings | Ben | `Created By` เป็น "Stone" ทั้ง 109 แถว — เอาตามนั้น หรือดึงผู้ดูแลจริงจาก per-agent sheet (คอลัมน์ Sheet ID) |
| Zone | Ben | โซนจริง ~30 แต่ DB มี 23 → โซนใหม่ต้องเช็คว่าตัวย่อไม่ชนกัน (`zone_id` ประกอบเป็นรหัสทรัพย์) |

> โฟลเดอร์นี้ถูก gitignore ไว้ (ยกเว้น README นี้) — ข้อมูลจริงมี PII ไม่ควรขึ้น git
