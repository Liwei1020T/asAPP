# ArtSport Management System (ASP-MS)

ASP-MS is a comprehensive management system designed specifically for Art Sport Penang Badminton Academy. Built with Flutter Web (PWA) and adopting a modern Clean Architecture, it aims to provide an efficient and seamless management and interaction experience for administrators, coaches, parents, and students.

## 🌟 Core Features

The system is designed around four core roles (Admin, Coach, Parent, Student) and covers the following main modules:

*   **🔐 Authentication & Permissions**
    *   Multi-role login support (Admin, Coach, Parent, Student).
    *   Secure authentication based on Supabase Auth.
    *   Role-Based Access Control (RBAC).

*   **📊 Dashboard**
    *   **Admin**: Global data overview, quick access shortcuts.
    *   **Coach**: View **all** upcoming sessions (not just assigned ones), to-do list, income overview.
    *   **Parent/Student**: Class schedule, attendance records, latest updates.

*   **📅 Class & Attendance Management**
    *   **Class Management**: Create classes of different levels (Basic/Advanced), set schedules, venues, and default coaches.
    *   **Flexible Scheduling**:
        *   **Batch Scheduling**: Automatically generate course sessions for a date range (even without a default coach).
        *   **Unassigned Sessions**: Create sessions without a specific coach (visible to all, claimable by clocking in).
        *   Support for ad-hoc adjustments.
    *   **Real-time Attendance**: Coaches can quickly take attendance (Present/Absent/Late/Leave) and add evaluations with AI feedback.
    *   **Smart Clock-In**: Coaches automatically clock in when starting a class, claiming the session if it was unassigned.

*   **👥 Personnel Management**
    *   **Student Profiles**: Manage student basic info, remaining sessions, and parent associations.
    *   **Coach Profiles**: Manage coach info and session rates.

*   **💰 Salary & Finance**
    *   **Automatic Calculation**: Automatically calculate monthly salaries based on completed sessions and rates.
    *   **Salary Reports**: View detailed monthly income breakdowns.

*   **📢 Communication & Interaction**
    *   **Timeline**: A social media-like feed where coaches post training photos/videos, parents can like and comment, and authors/admins can delete posts.
    *   **Notices**: Publish important announcements (holidays, tournaments) with support for pinning and urgent marking.
    *   **Playbook**: Shared teaching materials (videos/documents) with category management.

## 🛠 Tech Stack

This project utilizes the cutting-edge technology stack within the Flutter ecosystem:

*   **Frontend Framework**: [Flutter](https://flutter.dev/) (Web / PWA)
*   **Language**: Dart 3.x
*   **State Management**: [Riverpod 2.x/3.x](https://riverpod.dev/) (Generator syntax)
*   **Routing**: [GoRouter](https://pub.dev/packages/go_router)
*   **Backend Service**: [Supabase](https://supabase.com/) (PostgreSQL + Auth + Realtime) + local filesystem storage (`local_storage/` served over HTTP)
*   **UI Component Library**: Material 3 Design with Custom Premium System
*   **Animations**: [flutter_animate](https://pub.dev/packages/flutter_animate)
*   **Skeleton Screens**: [shimmer](https://pub.dev/packages/shimmer)
*   **Utilities**:
    *   `intl`: Date formatting and internationalization
    *   `shared_preferences`: Local configuration storage
    *   `file_picker`: File uploading

## 📂 Project Structure

The project follows the **Clean Architecture** layered approach to ensure code maintainability and scalability:

```
lib/
├── core/                   # Core shared modules
│   ├── config/             # Global config (Supabase, etc.)
│   ├── constants/          # Constants (Colors, Spacing, Animations)
│   ├── router/             # Router configuration (AppRouter)
│   ├── theme/              # Theme definitions (Light/Dark Mode)
│   ├── utils/              # Utilities (Date formatting, Responsive utils)
│   └── widgets/            # Common UI components (ASCard, ASButton, etc.)
├── data/                   # Data Layer
│   ├── models/             # Data Models (Dart Data Classes)
│   └── repositories/       # Repositories (Supabase API calls)
├── features/               # Business Features
│   ├── auth/               # Authentication (Login/Register)
│   ├── dashboard/          # Role-based Dashboards
│   ├── classes/            # Classes & Sessions
│   ├── attendance/         # Attendance Taking
│   ├── students/           # Student Management
│   ├── coaches/            # Coach Management
│   ├── salary/             # Salary Management
│   ├── timeline/           # Training Timeline
│   ├── playbook/           # Training Playbook
│   └── notices/            # Announcements
└── main.dart               # App Entry Point
```

## 🚀 Quick Start

### 1. Prerequisites

*   Flutter SDK (Recommended 3.10+)
*   Git

### 2. Get the Code

```bash
git clone <repository_url>
cd asp_ms
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Supabase & Storage Configuration

1.  Create a new [Supabase](https://supabase.com/) project.
2.  **Schema Setup**: Run the `dataSetUp.sql` script (located in the project root) in your Supabase SQL Editor. This script will:
    *   Create all necessary tables (Profiles, Sessions, Attendance, etc.).
    *   Set up Row Level Security (RLS) policies.
    *   Create test users and initial data.
3.  **Storage**: File uploads are saved locally under `local_storage/` (auto-created) and served via your own HTTP endpoint. Default public base URL is `http://localhost:9000` (see `lib/core/config/storage_config.dart`). Start a static server, e.g.:

```bash
python3 -m http.server 9000 --directory local_storage
```
4.  **App Credentials**:
    *   Enter your `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `lib/main.dart` (or your environment configuration file).
5.  **Essential Fixes & Updates**: Run the following scripts in order to ensure correct functionality:
    *   `supabase/fix_attendance_trigger.sql`: Fixes remaining session deduction logic.
    *   `supabase/fix_coach_shifts_fk.sql`: Fixes foreign key constraints for class deletion.
    *   `supabase/update_sessions_rls.sql`: Updates RLS to allow coaches to claim unassigned sessions.
    *   `supabase/remove_duplicate_sessions.sql`: (Optional) Cleans up any duplicate sessions.

### 5. Run the Project

```bash
# Run in Chrome
flutter run -d chrome --web-port=8080
```

Visit [http://localhost:8080](http://localhost:8080) to see the application.

## 🧪 Test Accounts

The `dataSetUp.sql` script creates the following test accounts by default (Password for all is `password123`):

| Role | Email | Description |
|------|-------|-------------|
| **Coach** | `mike@example.com` | Senior coach with existing schedule data |
| **Coach** | `sarah@example.com` | Intermediate coach |
| **Student** | `alice@example.com` | Basic level student |
| **Student** | `bob@example.com` | Advanced level student |

> **Note**: Admin accounts need to be manually created in Supabase Auth, and then have their `role` set to `admin` in the `profiles` table.

## 🎨 UI/UX Features

*   **Responsive Design**: Perfectly adapted for Desktop, Tablet, and Mobile devices.
*   **Dark Mode**: Supports system automatic switching or manual toggle between Light/Dark themes.
*   **Interactive Animations**: Staggered list entries, button feedback, and card hover effects to enhance user experience.

## 📝 Database Design (Schema)

Key data table relationships:

*   **profiles**: User profiles (linked to auth.users)
*   **class_groups**: Class definitions
*   **sessions**: Specific class sessions (linked to class_groups, coaches, venues)
*   **attendance**: Attendance records (linked to sessions, students)
*   **coach_shifts**: Coach shift records
*   **timeline_posts**: Timeline posts
*   **notices**: System announcements

For detailed SQL definitions, please refer to `dataSetUp.sql`.
