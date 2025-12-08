# Attendance Feature

## Overview
The Attendance feature allows coaches and admins to manage class attendance and coach shifts for specific sessions. It provides a digital roll call system and tracks coach working hours.

## Key Functionalities

### 1. Session Management
- **Load Session Details**: Displays class name, date, and time range.
- **Time Validation**: Enforces strict time windows for taking attendance (only during class time), except for Admins who have unrestricted access.

### 2. Coach Check-in (Shift Management)
- **Clock In/Out**: Coaches can clock in at the start of the session and clock out when finished.
- **Shift Tracking**: Records the start and end times for coach shifts.
- **Multiple Coaches**: Supports adding multiple coaches to a single session.
- **Coach Selection**: Allows selecting from available coaches to add them to the session.

### 3. Student Roll Call
- **Student List**: Automatically loads students enrolled in the class.
- **Status Tracking**: Mark students as:
    - **Present**: Student is attending the class.
    - **Absent**: Student is missing.
    - **Leave**: Student is marked on leave (see Leave & Makeup below).
- **Guest Students**: Allows adding temporary or guest students to the roll call for a specific session.

### 4. Submission & Statistics
- **Real-time Updates**: Syncs attendance status in real-time (using Supabase streams).
- **Summary Stats**: Displays counts for Present, Absent, and Leave students.
- **Submit**: Saves the final attendance record to the database.

### 5. Leave Requests & Makeup Rights
- **Auto Leave Request**: When a student is marked as **Leave** on the Attendance Page, the system will:
  - Upsert a record into `leave_requests` for `(student_id, session_id)` (default status `approved`).
  - Auto-generate a **makeup right** in `session_makeup_rights` with:
    - `student_id`: The student on leave.
    - `source_session_id`: The original session.
    - `class_id`: The class of that session.
    - `max_uses`: Default `1`.
    - `expires_at`: Default 30 days after the session start time.
  - Ensure there is an `attendance` row with status `leave` for that session/student.
- **Idempotent Behavior**: Re-marking the same student/session as Leave will not create duplicate records thanks to unique indexes and `upsert` logic.

### 6. Admin Leave List
- **Admin View**: An admin-only page `/admin/leaves` shows all leave requests in reverse chronological order.
- **Displayed Fields**:
  - Student name (looked up from `students.full_name`).
  - Session date (from `sessions.start_time`).
  - Leave status (`pending / approved / rejected` as a tag).
- **Navigation**:
  - In the Admin shell side menu, there is a **“请假记录”** destination pointing to `/admin/leaves`.


## Technical Components

### Presentation Layer
- `AttendancePage` (`lib/features/attendance/presentation/attendance_page.dart`): The main UI for the attendance feature.
    - Manages state for session data, student list, and coach shifts.
    - Handles user interactions for marking attendance and coach check-ins.

### Data Layer
- `AttendanceRepository`: Handles fetching students and submitting attendance records.
- `HrRepository`: Manages coach shifts (clock-in/clock-out).
- `SessionsRepository`: Fetches session details.
- `AuthRepository`: Fetches coach and admin profiles.
- `LeaveRepository`:
  - `createLeaveWithMakeup`: Creates/updates a leave request, generates a corresponding `session_makeup_rights` record, and sets the student's attendance status to `leave`.

## User Roles & Permissions
- **Admin**: Can take attendance at any time.
- **Coach**: Can only take attendance and clock in/out during the scheduled session time.
