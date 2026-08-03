# import/ — วาง CSV จาก Google Sheets ที่นี่

โฟลเดอร์นี้รอไฟล์ข้อมูลจริงจากชีท 2 เล่ม เพื่อ import เข้า Supabase **ครั้งเดียวจบ**
(ตกลงกันแล้วว่าชีทจะเลิกใช้เมื่อระบบขึ้น — ไม่มี two-way sync ไม่มีรอบสอง)

## วิธี export
เปิดชีท → `File` → `Download` → `Comma-separated values (.csv)` ทีละแท็บ แล้วเอามาวางที่นี่

## แท็บที่ต้องการ

### เล่ม 1 — "Stone Haus Living Listing" (`1sxgoXeyJ-bG_3NYo64sKvo1PxrA6yV5RsbDNXigB65M`)
| แท็บ | แถวโดยประมาณ | ตั้งชื่อไฟล์ |
|---|---|---|
| Listings | ~109 | `listings.csv` |
| Buyer Focus | ~176 | `buyer_focus.csv` |
| Projects | 39 | `projects.csv` |
| Last Match | 118 | `last_match.csv` |
| Last Match กรอกข้อมูล | 118 | `last_match_entry.csv` |
| Actions | 289 | `actions.csv` |

### เล่ม 2 — "HR Sheet" (`1oJTQhWXUNj1ft78WY9aNvXLoTr5w1ApyN4mWMyQP0eY`)
| แท็บ | แถวโดยประมาณ | ตั้งชื่อไฟล์ |
|---|---|---|
| Employee Lists | ~10 | `hr_employees.csv` |
| Zone | 519 | `hr_zones.csv` |
| Day off | 21 | `hr_dayoff.csv` |

**ไม่ต้องเอา** `User Pass` (รหัสผ่านพอร์ทัล — ไม่เข้า CRM), `Spending`, `Comments` (ตกลงว่าไม่ย้าย เก็บชีทไว้เป็น archive อ่านอย่างเดียว)

## ⚠️ ก่อน import ต้องทำก่อน
1. เพิ่มคอลัมน์ที่ยังขาดใน DB (15 คอลัมน์ของ listing + คอลัมน์ intake ของ `main_6_buyer_crm`) — ดู TODO 🔴 ใน `CLAUDE.md`
2. import `main_1_hr` ก่อนเสมอ เพราะ FK ทั้งระบบวิ่งเข้า `employee_code`
3. ปิด policy `demo_read_all` ก่อน import ข้อมูล HR จริง (ไม่งั้นเงินเดือน/เลขบัตร ปชช. เปิดสาธารณะ)
4. รัน import ด้วย `service_role` key ไม่ใช่ anon (RLS จะบล็อก insert)

> โฟลเดอร์นี้ถูก gitignore ไว้ (ยกเว้นไฟล์ README นี้) — ข้อมูลจริงมี PII ไม่ควรขึ้น git
