-- 学员请假 + 自动生成补课资格
-- 在 Supabase Dashboard 的 SQL Editor 中执行本脚本

-- 1) 请假申请表：leave_requests
create table if not exists leave_requests (
  id uuid primary key default gen_random_uuid(),
  student_id text not null references students(id) on delete cascade,
  session_id uuid not null references sessions(id) on delete cascade,
  reason text,
  status text not null check (status in ('pending','approved','rejected')) default 'approved',
  need_makeup boolean not null default true,
  expires_at timestamptz,
  max_uses int not null default 1,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

-- 确保一个学生对同一堂课只会有一条请假记录
do $$
begin
  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and indexname = 'idx_leave_requests_unique_student_session'
  ) then
    create unique index idx_leave_requests_unique_student_session
      on leave_requests (student_id, session_id);
  end if;
end $$;

alter table leave_requests enable row level security;

-- RLS：所有已登录用户可读，请假、审批仅管理员
drop policy if exists "leave_requests_select_auth" on leave_requests;
create policy "leave_requests_select_auth" on leave_requests
  for select using (auth.role() = 'authenticated');

drop policy if exists "leave_requests_write_admin" on leave_requests;
create policy "leave_requests_write_admin" on leave_requests
  for all using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );


-- 2) 补课资格表：session_makeup_rights
create table if not exists session_makeup_rights (
  id uuid primary key default gen_random_uuid(),
  student_id text not null references students(id) on delete cascade,
  source_session_id uuid not null references sessions(id) on delete cascade,
  class_id uuid not null references class_groups(id) on delete cascade,
  leave_request_id uuid references leave_requests(id) on delete set null,
  status text not null check (status in ('active','used','expired','cancelled')) default 'active',
  max_uses int not null default 1,
  used_count int not null default 0,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 确保每堂课只生成一条补课资格（每个学生）
do $$
begin
  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and indexname = 'idx_session_makeup_rights_unique_source'
  ) then
    create unique index idx_session_makeup_rights_unique_source
      on session_makeup_rights (student_id, source_session_id);
  end if;
end $$;

alter table session_makeup_rights enable row level security;

drop policy if exists "session_makeup_rights_select_auth" on session_makeup_rights;
create policy "session_makeup_rights_select_auth" on session_makeup_rights
  for select using (auth.role() = 'authenticated');

drop policy if exists "session_makeup_rights_write_admin" on session_makeup_rights;
create policy "session_makeup_rights_write_admin" on session_makeup_rights
  for all using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

