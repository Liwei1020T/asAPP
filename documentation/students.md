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
- **Balance Management**: Track Total Sessions vs. Remaining Sessions.
- **Visual Indicators**: Progress bar showing session usage.
- **Attendance Rate**: Calculated percentage of attended classes.
- **Low Balance Alerts**: System identifies students with few remaining sessions.

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
- `StorageRepository`: Handles avatar uploads to local disk under `local_storage/`, returning URLs based on `StorageConfig.publicBaseUrl`.

## Data Models
- **Student**:
    - `id`: Unique identifier.
    - `fullName`: Student's name.
    - `status`: Enum (active, inactive, graduated, suspended).
    - `level`: Enum (beginner, intermediate, advanced, elite).
    - `totalSessions` / `remainingSessions`: Session balance.
    - `parentName` / `emergencyPhone`: Contact details.
    - `birthDate`: Used to calculate age.
