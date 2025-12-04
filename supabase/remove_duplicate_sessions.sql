-- Remove duplicate sessions
-- Keeps one session for each (class_id, start_time) combination and deletes the others.

DELETE FROM sessions
WHERE id IN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY class_id, start_time
             ORDER BY id
           ) as row_num
    FROM sessions
  ) t
  WHERE t.row_num > 1
);
