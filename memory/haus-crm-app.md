---
name: haus-crm-app
description: Next.js CRM web app scaffolded from the design system, at Desktop/haus-crm, runs on port 3000
metadata:
  type: project
---

แอพ CRM หน้าเว็บของ Haus Living Estate อยู่ที่ `c:\Users\thinn\OneDrive\Desktop\Haus-Web-Wp.Ben\haus-crm` (ย้ายเข้ามาไว้ใน repo DB แล้ว แต่เป็น **git repo แยกของตัวเอง** — repo แม่ Haus-Web-Wp.Ben ใส่ `haus-crm/` ใน .gitignore ไว้ ไม่ track)

- Stack: Next.js 15 (App Router) + Tailwind v4 + TypeScript + @supabase/supabase-js
- ดึง design tokens จาก [[haus-design-system]] tokens.css → `app/globals.css`, ฟอนต์ Anuphan + IBM Plex Mono ผ่าน next/font
- หน้า: `/` (Dashboard), `/pipeline`, `/leads`, `/listings`, `/styleguide`
- อ่านข้อมูลจาก Supabase ด้วย anon/publishable key (server components, read-only) ผ่าน view v_main_listing / v_sale_status + ตาราง main_6
- รัน: `cd haus-crm && npm run dev` → http://localhost:3000
- .env.local มี NEXT_PUBLIC_SUPABASE_URL + NEXT_PUBLIC_SUPABASE_ANON_KEY (publishable key)

**How to apply:** ถ้าจะต่อยอด CRM หน้าเว็บ ใช้โฟลเดอร์นี้ ไม่ต้อง scaffold ใหม่ ดู [[supabase-demo-seed-and-rls]] เรื่องข้อมูล/สิทธิ์
