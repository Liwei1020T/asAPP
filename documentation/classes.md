# Classes Feature

## Overview
The Classes feature is the core module for managing training groups, student enrollments, and scheduling sessions. It allows admins to organize students into classes and plan their training schedules.

## Key Functionalities

### 1. Class Management
- **Create Class**: Admins can create new classes with default settings (Name, Level, Default Coach, Default Venue, Default Schedule).
- **List Classes**: View all active and inactive classes with summary information (Student count, Schedule, Venue).
- **Delete Class**: Remove a class and its associated data (with confirmation).
- **Class Details**: Detailed view of a specific class, including its students and sessions.

### 2. Student Enrollment
- **Manage Students**: Add or remove students from a class.
- **Student List**: View all students currently enrolled in the class, along with their remaining session counts.
- **Add Student**: Select from existing students in the system to add them to the class.

### 3. Session Scheduling
- **Session List**: View all scheduled sessions for the class (Upcoming and Completed).
- **Single Session Creation**: Schedule a specific training session with custom details (Title, Date, Time, Venue, Coach).
- **Batch Scheduling**: Efficiently schedule multiple recurring sessions at once (e.g., every Monday for the next 3 months).
- **Edit/Delete Session**: Modify or cancel existing sessions.
- **Access Control**: Only Admins and the assigned Coach can manage sessions.

## Technical Components

### Presentation Layer
- `AdminClassListPage` (`lib/features/classes/presentation/admin_class_list_page.dart`): Displays the list of all classes.
- `AdminClassDetailPage` (`lib/features/classes/presentation/admin_class_detail_page.dart`): The main hub for managing a specific class.
- `CreateClassDialog`: UI for creating a new class.
- `BatchScheduleDialog`: UI for generating multiple sessions.
- `SelectStudentDialog`: UI for selecting students to add to a class.

### Data Layer
- `ClassesRepository`:
    - `watchAllClasses`: Real-time stream of all classes.
    - `getClass`: Fetches details of a single class.
    - `addStudentToClass` / `removeStudentFromClass`: Manages student enrollment.
- `SessionsRepository`:
    - `getSessionsForClass`: Fetches sessions associated with a class.
    - `createSession` / `updateSession` / `deleteSession`: Manages individual session records.

## Data Models
- **ClassGroup**: Represents a class entity (Name, Level, Defaults).
- **Session**: Represents a single training event (Time, Venue, Coach, Status).
