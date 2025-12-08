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
    - **Leave**: Student has requested leave.
- **Guest Students**: Allows adding temporary or guest students to the roll call for a specific session.

### 4. Submission & Statistics
- **Real-time Updates**: Syncs attendance status in real-time (using Supabase streams).
- **Summary Stats**: Displays counts for Present, Absent, and Leave students.
- **Submit**: Saves the final attendance record to the database.

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

## User Roles & Permissions
- **Admin**: Can take attendance at any time.
- **Coach**: Can only take attendance and clock in/out during the scheduled session time.
