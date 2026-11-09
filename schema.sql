-- รันไฟล์นี้ทั้งไฟล์ใน Supabase > SQL Editor

create table classes (
  id uuid primary key default gen_random_uuid(),
  name text unique not null
);

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text not null,
  role text not null check (role in ('teacher','student')),
  class_id uuid references classes(id) on delete set null
);

create table rooms (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  is_special boolean not null default false
);

create table subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  class_id uuid not null references classes(id) on delete cascade,
  teacher_id uuid not null references profiles(id) on delete cascade,
  periods_per_week int not null check (periods_per_week between 1 and 20),
  requires_special boolean not null default false
);

-- ข้อจำกัดระดับฐานข้อมูล: ห้ามชั้นเรียน ครู หรือห้อง ซ้อนกันในคาบเดียวกัน
create table timetable (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  subject_id uuid not null references subjects(id) on delete cascade,
  teacher_id uuid not null references profiles(id) on delete cascade,
  room_id uuid not null references rooms(id) on delete cascade,
  day int not null check (day between 0 and 4),
  period int not null check (period between 1 and 8),
  unique (class_id, day, period),
  unique (teacher_id, day, period),
  unique (room_id, day, period)
);

-- รหัสสำหรับสมัครเป็นครู (เปลี่ยนค่า CHANGE_ME ก่อนใช้งานจริง)
create table app_settings (key text primary key, value text not null);
insert into app_settings values ('68319010011', 'CHANGE_ME');
alter table app_settings enable row level security; -- ไม่มี policy = เข้าถึงจากเว็บไม่ได้

create function is_teacher() returns boolean
language sql security definer stable set search_path = public as
$$ select exists (select 1 from profiles where id = auth.uid() and role = 'teacher') $$;

create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare r text := 'student';
begin
  if new.raw_user_meta_data->>'role' = 'teacher'
     and new.raw_user_meta_data->>'code' = (select value from app_settings where key = '68319010011') then
    r := 'teacher';
  end if;
  insert into profiles (id, full_name, role, class_id)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', 'ผู้ใช้'), r,
          nullif(new.raw_user_meta_data->>'class_id', '')::uuid);
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function handle_new_user();

-- สิทธิ์: ทุกคนที่ล็อกอินอ่านได้ / เฉพาะครูแก้ไขได้
do $$
declare t text;
begin
  foreach t in array array['classes','rooms','subjects','timetable'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "read" on %I for select to authenticated using (true)', t);
    execute format('create policy "teacher write" on %I for all to authenticated using (is_teacher()) with check (is_teacher())', t);
  end loop;
end $$;

create policy "public read classes" on classes for select to anon using (true);

alter table profiles enable row level security;
create policy "read" on profiles for select to authenticated using (true);
