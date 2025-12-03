-- =====================================================
-- 使用 Supabase Auth 创建用户，由数据库触发器自动写入 profiles
-- 在 Supabase Dashboard > SQL Editor 中执行此脚本
-- =====================================================

-- 删除旧的 admin_create_user 函数（如存在）
DROP FUNCTION IF EXISTS admin_create_user;

-- 1. 确保 profiles 表包含需要的列
alter table public.profiles
  add column if not exists email text,
  add column if not exists updated_at timestamptz default now();

-- 2. profiles 表的 updated_at 自动更新时间触发器
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

-- 3. 当有新 auth.users 创建时，自动在 profiles 中建档
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
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    coalesce(new.raw_user_meta_data->>'role', 'student'),
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
        phone_number = excluded.phone_number,
        parent_id = excluded.parent_id,
        rate_per_session = excluded.rate_per_session,
        avatar_url = excluded.avatar_url,
        updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_user_created on auth.users;
create trigger on_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();
