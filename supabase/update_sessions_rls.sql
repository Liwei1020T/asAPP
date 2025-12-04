-- Update RLS policies for sessions to allow claiming unassigned sessions

-- Drop existing update policy
drop policy if exists "sessions_update_admin_or_coach" on sessions;

-- Create new update policy
create policy "sessions_update_admin_or_coach" on sessions
  for update
  using (
    auth.role() = 'authenticated'
    and (
      coach_id = auth.uid()
      or actual_coach_id = auth.uid()
      or coach_id is null -- Allow any coach to update if unassigned (to claim it)
      or exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'admin'
      )
    )
  )
  with check (
    auth.role() = 'authenticated'
    and (
      coach_id = auth.uid()
      or actual_coach_id = auth.uid()
      or coach_id is null
      or exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'admin'
      )
    )
  );

-- Also update insert policy to allow coaches to create unassigned sessions if needed (optional, but good for flexibility)
drop policy if exists "sessions_write_admin_or_coach" on sessions;

create policy "sessions_write_admin_or_coach" on sessions
  for insert
  with check (
    auth.role() = 'authenticated'
    and (
      coach_id = auth.uid()
      or actual_coach_id = auth.uid()
      or coach_id is null -- Allow creating unassigned sessions
      or exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'admin'
      )
    )
  );
