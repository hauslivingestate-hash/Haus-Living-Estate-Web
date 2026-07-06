---
name: supabase-demo-seed-and-rls
description: Live Supabase DB มี seed ข้อมูลตัวอย่าง + demo_read_all anon policies (สำหรับให้แอพ demo อ่านได้)
metadata:
  type: project
---

เพื่อให้ [[haus-crm-app]] อ่านข้อมูลได้ ได้แก้ Supabase project (jpufhxzvqfrdcblfmrmu) จริง 2 อย่าง:

1. **Seed ข้อมูลตัวอย่าง** ลง main tables (ก่อนหน้านี้ว่าง 0 แถวทุกตาราง):
   - main_1_hr: S-001..S-004 (sales), SP-001 (support), C-001 (CEO)
   - zone assign sale_id_assigned, main_2_owner 5, main_3 6 โครงการ, main_4 10 listing,
     main_5 7 lead, main_6 10 CRM, main_7 3 last_match (main_10 auto-sync 6 แถว)

2. **RLS demo policy**: ทุกตารางใน public เดิมเปิด RLS แต่ไม่มี policy → anon อ่านไม่ได้เลย
   เพิ่ม policy ชื่อ `demo_read_all` (for select to anon, authenticated using(true)) ครบ 36 ตาราง

**Why:** anon/publishable key ต้องมี SELECT policy ถึงจะอ่านผ่าน RLS ได้

**How to apply:** `demo_read_all` เป็นแค่ read-only สำหรับ demo — ตอนทำ RLS จริง (TODO แยกข้อมูล listing ตาม created_by) ต้อง **ลบ demo_read_all ทิ้งก่อน** แล้วเขียน policy จริง ไม่งั้นทุกคนเห็นทุกแถว ยังไม่มี policy สำหรับ insert/update/delete (แอพเป็น read-only)
