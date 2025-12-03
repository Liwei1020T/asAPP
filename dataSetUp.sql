
-- Profiles
create table if not exists profiles (
  id uuid primary key references auth.users(id),
  email text,
  full_name text not null,
  role text check (role in ('admin','coach','parent','student')) not null,
  phone_number text,
  avatar_url text,
  parent_id uuid references profiles(id),
  rate_per_session numeric,
  total_classes_attended int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table profiles enable row level security;
drop policy if exists "profiles_select_auth" on profiles;
create policy "profiles_select_auth" on profiles for select using (auth.role() = 'authenticated');
drop policy if exists "profiles_insert_self" on profiles;
create policy "profiles_insert_self" on profiles for insert with check (id = auth.uid());
drop policy if exists "profiles_update_self_or_admin" on profiles;
create policy "profiles_update_self_or_admin" on profiles
  for update using (id = auth.uid() or exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 允许家长绑定孩子：将学生的 parent_id 绑定到自己（仅限 role=student）
drop policy if exists "profiles_parent_link_child" on profiles;
create policy "profiles_parent_link_child" on profiles
  for update
  using (
    role = 'student'
    and (parent_id is null or parent_id = auth.uid())
  )
  with check (
    role = 'student'
    and parent_id = auth.uid()
  );

-- =====================================================
-- 用户注册时自动创建 profiles 记录的触发器
-- 使用 security definer 绕过 RLS 策略
-- =====================================================

-- 1. 创建处理新用户的函数
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name,
    role,
    phone_number,
    parent_id,
    rate_per_session,
    avatar_url,
    created_at,
    updated_at
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'parent'),
    nullif(new.raw_user_meta_data->>'phone_number', ''),
    nullif(new.raw_user_meta_data->>'parent_id', '')::uuid,
    nullif(new.raw_user_meta_data->>'rate_per_session', '')::numeric,
    nullif(new.raw_user_meta_data->>'avatar_url', ''),
    now(),
    now()
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        role = excluded.role,
        phone_number = coalesce(excluded.phone_number, profiles.phone_number),
        parent_id = coalesce(excluded.parent_id, profiles.parent_id),
        rate_per_session = coalesce(excluded.rate_per_session, profiles.rate_per_session),
        avatar_url = coalesce(excluded.avatar_url, profiles.avatar_url),
        updated_at = now();

  return new;
exception
  when others then
    -- 记录错误但不阻止用户创建
    raise warning 'handle_new_user failed for user %: %', new.id, sqlerrm;
    return new;
end;
$$;

-- 2. 删除旧触发器并重新创建
drop trigger if exists on_user_created on auth.users;
create trigger on_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- 3. profiles 表的 updated_at 自动更新时间触发器
create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();

-- Students（独立学生表，承载学员详细信息，不要求是 auth 用户）
create table if not exists students (
  id text primary key,
  -- 若该学生同时在 profiles 中有账号，则这里保存对应的 profile_id，方便与点名记录关联
  profile_id uuid references profiles(id),
  full_name text not null,
  avatar_url text,
  birth_date timestamptz,
  gender text,
  phone_number text,
  emergency_contact text,
  emergency_phone text,
  parent_id uuid references profiles(id),
  parent_name text,
  class_ids text[],
  level text check (level in ('beginner','elementary','intermediate','advanced','professional')) default 'beginner',
  status text check (status in ('active','inactive','graduated','suspended')) default 'active',
  enrollment_date timestamptz default now(),
  remaining_sessions int default 0,
  total_sessions int default 0,
  attendance_rate double precision default 0,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table students enable row level security;
drop policy if exists "students_select_auth" on students;
create policy "students_select_auth" on students
  for select using (auth.role() = 'authenticated');
drop policy if exists "students_write_admin" on students;
create policy "students_write_admin" on students
  for all using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- 允许家长绑定孩子：更新 students 表的 parent_id 字段
drop policy if exists "students_parent_bind" on students;
create policy "students_parent_bind" on students
  for update
  using (
    -- 只能绑定尚未被其他家长绑定的学生，或已是自己孩子的学生
    parent_id is null or parent_id = auth.uid()
  )
  with check (
    -- 只能将 parent_id 设置为自己
    parent_id = auth.uid()
  );

-- 自动根据点名记录扣减学生课时（按月统计）
-- 约定：
--   1) admin 在 students.total_sessions 中设置“本月可上课总课时”
--   2) students.remaining_sessions 表示“本月剩余课时”
--   3) 当有出席/迟到记录（present/late）时扣 1 节；改成缺席/请假或删除记录时加回 1 节
--   4) attendance.student_id 为 profiles.id；若该学生在 students 表有一行且 profile_id = attendance.student_id，则才会扣减
create or replace function public.update_student_sessions_from_attendance()
returns trigger
language plpgsql
as $$
declare
  v_student_id text;
  v_delta      int := 0;
begin
  if TG_OP = 'INSERT' then
    v_student_id := NEW.student_id;
    if NEW.status in ('present', 'late') then
      v_delta := -1;
    end if;
  elsif TG_OP = 'UPDATE' then
    v_student_id := NEW.student_id;

    if OLD.status in ('present', 'late') then
      v_delta := v_delta + 1;
    end if;
    if NEW.status in ('present', 'late') then
      v_delta := v_delta - 1;
    end if;
  elsif TG_OP = 'DELETE' then
    v_student_id := OLD.student_id;
    if OLD.status in ('present', 'late') then
      v_delta := 1;
    end if;
  end if;

  -- 没有变化则直接返回
  if v_delta = 0 then
    if TG_OP = 'DELETE' then
      return OLD;
    else
      return NEW;
    end if;
  end if;

  update students
  set remaining_sessions = greatest(remaining_sessions + v_delta, 0),
      updated_at         = now()
  where id = v_student_id;

  if TG_OP = 'DELETE' then
    return OLD;
  else
    return NEW;
  end if;
end;
$$;

drop trigger if exists trg_attendance_update_sessions on attendance;
create trigger trg_attendance_update_sessions
after insert or update or delete on attendance
for each row
execute function public.update_student_sessions_from_attendance();

-- Venues
create table if not exists venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  latitude double precision,
  longitude double precision,
  radius_m double precision
);
alter table venues enable row level security;
drop policy if exists "venues_select_auth" on venues;
create policy "venues_select_auth" on venues for select using (auth.role() = 'authenticated');
drop policy if exists "venues_write_admin" on venues;
create policy "venues_write_admin" on venues for all using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- Classes
create table if not exists class_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  level text,
  default_venue text,
  default_day_of_week int,
  default_start_time text,
  default_end_time text,
  capacity int,
  default_coach_id uuid references profiles(id),
  is_active boolean default true
);
alter table class_groups enable row level security;
drop policy if exists "classes_select_auth" on class_groups;
create policy "classes_select_auth" on class_groups for select using (auth.role() = 'authenticated');
drop policy if exists "classes_write_admin" on class_groups;
create policy "classes_write_admin" on class_groups for all using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- Class memberships（班级-学员关系，指向 students.id）
create table if not exists class_memberships (
  class_id uuid references class_groups(id) on delete cascade,
  student_id text references students(id) on delete cascade,
  joined_at timestamptz default now(),
  is_active boolean default true,
  primary key (class_id, student_id)
);
-- 若之前已存在使用 uuid/profiles 的外键，这里统一调整为 text -> students
do $$
begin
  begin
    alter table class_memberships
      alter column student_id type text using student_id::text;
  exception
    when others then
      null;
  end;

  begin
    alter table class_memberships
      drop constraint if exists class_memberships_student_id_fkey;
  exception
    when others then
      null;
  end;

  begin
    alter table class_memberships
      add constraint class_memberships_student_id_fkey
      foreign key (student_id) references students(id) on delete cascade;
  exception
    when others then
      null;
  end;
end $$;
alter table class_memberships enable row level security;
drop policy if exists "class_memberships_select_auth" on class_memberships;
create policy "class_memberships_select_auth" on class_memberships for select using (auth.role() = 'authenticated');
drop policy if exists "class_memberships_write_admin" on class_memberships;
create policy "class_memberships_write_admin" on class_memberships
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Sessions
create table if not exists sessions (
  id uuid primary key default gen_random_uuid(),
  class_id uuid references class_groups(id) on delete cascade,
  coach_id uuid references profiles(id),
  title text,
  venue text,
  venue_id uuid references venues(id),
  start_time timestamptz not null,
  end_time timestamptz not null,
  status text check (status in ('scheduled','completed','cancelled')) default 'scheduled',
  is_payable boolean default true,
  actual_coach_id uuid references profiles(id),
  completed_at timestamptz
);
alter table sessions enable row level security;
drop policy if exists "sessions_select_auth" on sessions;
create policy "sessions_select_auth" on sessions for select using (auth.role() = 'authenticated');
drop policy if exists "sessions_write_admin_or_coach" on sessions;
create policy "sessions_write_admin_or_coach" on sessions for all using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  or coach_id = auth.uid()
);

-- Attendance
create table if not exists attendance (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references sessions(id) on delete cascade,
  student_id text references students(id),
  status text check (status in ('present','absent','late','leave')) default 'present',
  coach_note text,
  ai_feedback text,
  created_at timestamptz default now()
);
alter table attendance enable row level security;
-- 调整 student_id 为 text -> students.id
do $$
begin
  begin
    alter table attendance
      alter column student_id type text using student_id::text;
  exception
    when others then
      null;
  end;

  begin
    alter table attendance
      drop constraint if exists attendance_student_id_fkey;
  exception
    when others then
      null;
  end;

  begin
    alter table attendance
      add constraint attendance_student_id_fkey
      foreign key (student_id) references students(id);
  exception
    when others then
      null;
  end;
end $$;
drop policy if exists "attendance_select_auth" on attendance;
create policy "attendance_select_auth" on attendance for select using (auth.role() = 'authenticated');
drop policy if exists "attendance_write_admin_or_coach" on attendance;
create policy "attendance_write_admin_or_coach" on attendance for all using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
  or exists (select 1 from sessions s where s.id = session_id and s.coach_id = auth.uid())
);

-- Notices
create table if not exists notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  is_pinned boolean default false,
  is_urgent boolean default false,
  target_audience text check (target_audience in ('all','coach','parent')) default 'all',
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);
alter table notices enable row level security;
drop policy if exists "notices_select_auth" on notices;
create policy "notices_select_auth" on notices for select using (auth.role() = 'authenticated');
drop policy if exists "notices_write_admin_or_coach" on notices;
create policy "notices_write_admin_or_coach" on notices for all using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','coach'))
);

-- Timeline posts
create table if not exists timeline_posts (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid references profiles(id),
  author_id uuid references profiles(id),
  media_urls text[] default '{}',
  media_type text check (media_type in ('video','image')) default 'image',
  thumbnail_url text,
  caption text,
  content text,
  visibility text check (visibility in ('public','internal')) default 'public',
  mentioned_student_ids text[] default '{}',
  created_at timestamptz default now(),
  likes_count int default 0,
  comments_count int default 0
);
alter table timeline_posts enable row level security;
drop policy if exists "timeline_select_auth" on timeline_posts;
create policy "timeline_select_auth" on timeline_posts for select using (auth.role() = 'authenticated');
drop policy if exists "timeline_write_admin_or_coach" on timeline_posts;
create policy "timeline_write_admin_or_coach" on timeline_posts for all using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','coach'))
);

-- 点赞表
create table if not exists timeline_likes (
  post_id uuid references timeline_posts(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (post_id, user_id)
);
alter table timeline_likes enable row level security;
drop policy if exists "timeline_likes_select_auth" on timeline_likes;
create policy "timeline_likes_select_auth" on timeline_likes for select using (auth.role() = 'authenticated');
drop policy if exists "timeline_likes_write_self" on timeline_likes;
create policy "timeline_likes_write_self" on timeline_likes
  for all
  using (auth.role() = 'authenticated' and user_id = auth.uid())
  with check (auth.role() = 'authenticated' and user_id = auth.uid());

-- 评论表
create table if not exists timeline_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references timeline_posts(id) on delete cascade,
  user_id uuid references profiles(id),
  content text not null,
  created_at timestamptz default now()
);
alter table timeline_comments enable row level security;
drop policy if exists "timeline_comments_select_auth" on timeline_comments;
create policy "timeline_comments_select_auth" on timeline_comments for select using (auth.role() = 'authenticated');
drop policy if exists "timeline_comments_write_self" on timeline_comments;
create policy "timeline_comments_write_self" on timeline_comments
  for all
  using (auth.role() = 'authenticated' and user_id = auth.uid())
  with check (auth.role() = 'authenticated' and user_id = auth.uid());

-- 点赞/评论计数维护
create or replace function public.update_timeline_counts()
returns trigger
language plpgsql
as $$
begin
  if TG_TABLE_NAME = 'timeline_likes' then
    if TG_OP = 'INSERT' then
      update timeline_posts set likes_count = likes_count + 1 where id = NEW.post_id;
    elsif TG_OP = 'DELETE' then
      update timeline_posts set likes_count = greatest(likes_count - 1, 0) where id = OLD.post_id;
    end if;
  elsif TG_TABLE_NAME = 'timeline_comments' then
    if TG_OP = 'INSERT' then
      update timeline_posts set comments_count = comments_count + 1 where id = NEW.post_id;
    elsif TG_OP = 'DELETE' then
      update timeline_posts set comments_count = greatest(comments_count - 1, 0) where id = OLD.post_id;
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_timeline_likes_count on timeline_likes;
create trigger trg_timeline_likes_count
after insert or delete on timeline_likes
for each row execute function public.update_timeline_counts();

drop trigger if exists trg_timeline_comments_count on timeline_comments;
create trigger trg_timeline_comments_count
after insert or delete on timeline_comments
for each row execute function public.update_timeline_counts();

-- 兼容旧结构：为已有的 timeline_posts 表补充 author_id 列，并用 coach_id 回填
do $$
begin
  begin
    alter table timeline_posts add column author_id uuid references profiles(id);
  exception
    when others then
      null;
  end;

  begin
    update timeline_posts
    set author_id = coach_id
    where author_id is null;
  exception
    when others then
      null;
  end;
end $$;

-- Training materials
create table if not exists training_materials (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text,
  type text check (type in ('video','document','image','link')) default 'video',
  content_url text,
  thumbnail_url text,
  key_points text[],
  tags text[],
  visibility text check (visibility in ('public','coaches','internal')) default 'public',
  author_id uuid references profiles(id),
  view_count int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz
);
alter table training_materials enable row level security;
drop policy if exists "materials_select_auth" on training_materials;
create policy "materials_select_auth" on training_materials for select using (auth.role() = 'authenticated');
drop policy if exists "materials_write_admin_or_coach" on training_materials;
create policy "materials_write_admin_or_coach" on training_materials for all using (
  exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('admin','coach'))
);

-- Coach shifts
create table if not exists coach_shifts (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid references profiles(id),
  session_id uuid references sessions(id),
  class_id uuid references class_groups(id),
  class_name text,
  date date not null,
  start_time text,
  end_time text,
  status text check (status in ('scheduled','completed','cancelled')) default 'scheduled',
  clock_in_at timestamptz,
  clock_out_at timestamptz,
  clock_in_lat double precision,
  clock_in_lng double precision,
  clock_out_lat double precision,
  clock_out_lng double precision
);
alter table coach_shifts enable row level security;
drop policy if exists "shifts_select_self_or_admin" on coach_shifts;
create policy "shifts_select_self_or_admin" on coach_shifts for select using (
  coach_id = auth.uid() or exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
);
drop policy if exists "shifts_write_self_or_admin" on coach_shifts;
create policy "shifts_write_self_or_admin" on coach_shifts for all using (
  coach_id = auth.uid() or exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- 教练月度汇总视图
create or replace view coach_session_summary as
select
  coach_id,
  date_trunc('month', start_time) as month,
  count(*) filter (where status = 'completed') as total_sessions,
  coalesce(max(rate_per_session),0) as rate_per_session,
  coalesce(count(*) filter (where status = 'completed'),0) * coalesce(max(rate_per_session),0) as total_salary
from sessions
left join profiles on profiles.id = sessions.coach_id
group by coach_id, date_trunc('month', start_time);

-- =====================================================
-- Storage Bucket RLS：timeline / playbook 上传权限
-- =====================================================

-- 尝试为 storage.objects 启用 RLS（Supabase 默认已启用）。
-- 某些环境下当前角色不是 owner，会报错 42501，这里通过匿名块忽略该错误。
do $$
begin
  begin
    alter table storage.objects enable row level security;
  exception
    when others then
      null;
  end;
end $$;

-- 1. timeline 动态媒体：允许教练和管理员上传，所有人可读
drop policy if exists "timeline_read_public" on storage.objects;
create policy "timeline_read_public" on storage.objects
  for select
  using (bucket_id = 'timeline');

drop policy if exists "timeline_upload_coach_admin" on storage.objects;
create policy "timeline_upload_coach_admin" on storage.objects
  for insert
  with check (
    bucket_id = 'timeline'
    and auth.role() = 'authenticated'
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role in ('coach','admin')
    )
  );

-- 2. playbook 教学资料：允许教练和管理员上传，所有认证用户可读
drop policy if exists "playbook_read_auth" on storage.objects;
create policy "playbook_read_auth" on storage.objects
  for select
  using (
    bucket_id = 'playbook'
    and auth.role() = 'authenticated'
  );

drop policy if exists "playbook_upload_coach_admin" on storage.objects;
create policy "playbook_upload_coach_admin" on storage.objects
  for insert
  with check (
    bucket_id = 'playbook'
    and auth.role() = 'authenticated'
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role in ('coach','admin')
    )
  );
