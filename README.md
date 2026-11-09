# ระบบจัดตารางสอนอัตโนมัติ

เว็บไซต์ไฟล์เดียว (HTML + JavaScript) ใช้ Supabase เป็นฐานข้อมูล และ Deploy บน Vercel ได้ทันทีโดยไม่ต้อง build

## 1. ตั้งค่า Supabase
1. สร้างโปรเจกต์ที่ supabase.com
2. เปิด SQL Editor แล้วรันไฟล์ `schema.sql` ทั้งไฟล์
3. แก้รหัสครู: `update app_settings set value = 'รหัสของคุณ' where key = 'teacher_code';`
4. ไปที่ Project Settings > API คัดลอก Project URL และ anon public key
5. (ทางเลือก) Authentication > Providers > Email ปิด Confirm email เพื่อให้สมัครแล้วใช้งานได้ทันที

## 2. ใส่ค่าในเว็บ
เปิด `index.html` แก้สองบรรทัดนี้:

```js
const SB_URL = 'https://YOUR-PROJECT.supabase.co';
const SB_KEY = 'YOUR-ANON-PUBLIC-KEY';
```

anon key เป็นคีย์สาธารณะ ปลอดภัยที่จะอยู่ในโค้ด เพราะสิทธิ์ถูกควบคุมด้วย Row Level Security ใน `schema.sql` (ห้ามใช้ service_role key)

## 3. เก็บบน GitHub
```bash
git init
git add .
git commit -m "timetable app"
git branch -M main
git remote add origin https://github.com/USERNAME/timetable-app.git
git push -u origin main
```

## 4. Deploy บน Vercel
1. เข้า vercel.com > Add New > Project > เลือก repository ข้างต้น
2. Framework Preset: Other (ไม่ต้องตั้งค่า build)
3. กด Deploy

## หลักการไม่ให้ตารางซ้อนกัน
- ตัวจัดตารางตรวจห้องเรียน ครู และห้องสอน ก่อนวางทุกคาบ
- ฐานข้อมูลมี unique constraint (ห้องเรียน/ครู/ห้องสอน + วัน + คาบ) เป็นด่านสุดท้าย แม้มีการแก้ข้อมูลโดยตรงก็ซ้อนกันไม่ได้
- วิชาที่ติ๊ก ต้องใช้ห้องพิเศษ จะถูกจัดเฉพาะห้องพิเศษ และวิชาทั่วไปจะไม่ใช้ห้องพิเศษ

## ปรับแต่ง
จำนวนคาบต่อวันแก้ที่ค่า `PERIODS` ใน `index.html` และค่า check constraint ของคอลัมน์ `period` ใน `schema.sql`
