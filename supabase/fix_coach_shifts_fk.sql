-- 修复删除班级时的外键约束错误
-- 允许删除班级时自动删除关联的教练排班记录

ALTER TABLE coach_shifts
DROP CONSTRAINT IF EXISTS coach_shifts_class_id_fkey;

ALTER TABLE coach_shifts
ADD CONSTRAINT coach_shifts_class_id_fkey
FOREIGN KEY (class_id)
REFERENCES class_groups(id)
ON DELETE CASCADE;
