-- =====================================================
-- 修复用户注册时自动创建 profiles 记录的触发器
-- 在 Supabase Dashboard > SQL Editor 中执行此脚本
-- =====================================================

-- 1. 创建处理新用户的函数（security definer 绕过 RLS）
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

-- 3. 为已存在但没有 profile 的用户补充创建记录
-- （处理触发器失效期间注册的用户）
insert into public.profiles (id, email, full_name, role, phone_number, created_at, updated_at)
select 
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  coalesce(u.raw_user_meta_data->>'role', 'parent'),
  nullif(u.raw_user_meta_data->>'phone_number', ''),
  now(),
  now()
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
on conflict (id) do nothing;

-- 4. 验证：查看是否所有用户都有 profile（可选执行）
-- select u.id, u.email, p.id as profile_id, p.role
-- from auth.users u
-- left join public.profiles p on p.id = u.id
-- order by u.created_at desc;
