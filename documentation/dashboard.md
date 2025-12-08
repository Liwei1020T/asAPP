# Dashboard Feature

## Overview
The Dashboard feature serves as the central landing page for all users, providing role-specific overviews, quick actions, and key statistics. It is tailored to the needs of Admins, Coaches, and Parents.

## Key Functionalities

### 1. Admin Dashboard
- **Overview Stats**: Displays key metrics like Active Classes, Total Students, and Coach Count.
- **Attendance Trend**: Visual chart showing weekly student attendance trends.
- **Recent Activity**: Feed of recent system activities or notices.
- **Quick Actions**: Shortcuts for common tasks like adding new students.

### 2. Coach Dashboard
- **Schedule Management**:
    - **Today's Classes**: List of classes scheduled for the current day.
    - **Upcoming**: Preview of future sessions.
- **Shift Actions**:
    - **Clock In/Out**: Integrated time clock with geolocation support for tracking work hours.
    - **Shift Status**: View status of current and recent shifts.
- **Performance**:
    - **Monthly Stats**: Track number of sessions conducted and estimated monthly income.
- **Notices**: View announcements relevant to coaches.

### 3. Parent Dashboard
- **Children Overview**:
    - **Attendance**: Summary of each child's attendance record (Present/Total).
    - **Session Balance**: View remaining sessions for each child.
- **Training Moments**: Feed of photos and videos (Timeline posts) featuring their children.
- **Notices**: View announcements relevant to parents.
- **Child Management**: Link new children to the parent account using Student ID.

## Technical Components

### Presentation Layer
- `AdminDashboardPage`: Main view for administrators.
- `CoachDashboardPage`: Main view for coaches.
- `ParentDashboardPage`: Main view for parents and students.
- `DashboardWidgets`: Reusable widgets for stats cards, charts, and lists.

### Data Layer
- **Repositories Used**:
    - `AuthRepository`: User profile and role data.
    - `SessionsRepository`: Class schedules and session data.
    - `HrRepository`: Coach shifts and salary stats.
    - `AttendanceRepository`: Student attendance summaries.
    - `NoticeRepository`: System announcements.
    - `TimelineRepository`: Media posts for the "Moments" section.
