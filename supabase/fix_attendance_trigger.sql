-- 修复/重建自动扣减课时的触发器

-- 1. 创建或更新函数
create or replace function public.update_student_sessions_from_attendance()
returns trigger
language plpgsql
security definer
set search_path = public
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

  -- 更新 students 表
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

-- 2. 重建触发器
drop trigger if exists trg_attendance_update_sessions on attendance;
create trigger trg_attendance_update_sessions
after insert or update or delete on attendance
for each row
execute function public.update_student_sessions_from_attendance();
