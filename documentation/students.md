# Students Feature

## Overview
The Students feature is a comprehensive management system for student profiles, enrollment status, and session tracking. It allows administrators to maintain accurate records of all academy members.

## Key Functionalities

### 1. Student Management
- **List View**: Browse all students with key details (Name, Level, Status).
- **Filtering & Search**:
    - Filter by **Status** (Active, Inactive, Graduated, Suspended).
    - Filter by **Level** (Beginner, Intermediate, Advanced, etc.).
    - Search by **Student Name** or **Parent Name**.
- **CRUD Operations**: Add new students and edit existing profiles.

### 2. Profile Details
- **Personal Info**: Name, Gender, Birth Date, Age.
- **Contact Info**: Parent Name, Emergency Contact, Phone Numbers.
- **Academic Status**: Current Level, Enrollment Date.
- **Avatar**: Upload and manage student profile pictures.

### 3. Session Tracking
- **Attendance Rate**: Calculated percentage of attended classes for each student.
- **Monthly Overview**: Parent dashboard shows per‑child attendance rate for the current month.
- **History Drill‑down**: From the dashboard, parents can open detailed attendance/leave history per child.

## Technical Components

### Presentation Layer
- `StudentListPage` (`lib/features/students/presentation/student_list_page.dart`): Main directory of students.
- `StudentDetailPage` (`lib/features/students/presentation/student_detail_page.dart`): Detailed view of a single student.
- `_StudentCard`: List item widget.
- `_showStudentFormDialog`: Form for adding/editing students.

### Data Layer
- `StudentRepository`:
    - `watchStudents`: Real-time stream of student list.
    - `getStudentById`: Fetches detailed profile.
    - `createStudent` / `updateStudent`: Manages student data persistence.
- `StorageRepository`: Handles avatar uploads by sending files to the HTTP upload endpoint configured via
  `StorageConfig.publicBaseUrl` (typically a Cloudflare‑exposed server that serves files from `local_storage/`).

## Data Models
- **Student**:
    - `id`: Unique identifier.
    - `fullName`: Student's name.
    - `status`: Enum (active, inactive, graduated, suspended).
    - `level`: Enum (beginner, intermediate, advanced, elite).
    - `attendanceRate`: Aggregated attendance percentage.
    - `totalSessions` / `remainingSessions` *(optional/legacy)*: Fields reserved for quota/balance style billing, not shown in the current parent UI.
    - `parentName` / `emergencyPhone`: Contact details.
    - `birthDate`: Used to calculate age.
