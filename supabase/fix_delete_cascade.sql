-- Add ON DELETE CASCADE to coach_shifts.session_id
ALTER TABLE coach_shifts
DROP CONSTRAINT IF EXISTS coach_shifts_session_id_fkey;

ALTER TABLE coach_shifts
ADD CONSTRAINT coach_shifts_session_id_fkey
FOREIGN KEY (session_id)
REFERENCES sessions(id)
ON DELETE CASCADE;

-- Also ensure attendance table has cascade delete if not already
ALTER TABLE attendance
DROP CONSTRAINT IF EXISTS attendance_session_id_fkey;

ALTER TABLE attendance
ADD CONSTRAINT attendance_session_id_fkey
FOREIGN KEY (session_id)
REFERENCES sessions(id)
ON DELETE CASCADE;
