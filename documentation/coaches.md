# Coaches Feature

## Overview
The Coaches feature allows administrators to manage coach profiles, track their performance, and monitor their schedules and earnings. It provides a centralized view of all coaching staff.

## Key Functionalities

### 1. Coach Management
- **Coach List**: View a directory of all coaches with key statistics (Monthly sessions, Estimated income).
- **Search**: Filter coaches by name.
- **Create Coach**: Admins can create new coach accounts, setting up their login credentials (email/password), personal details, and pay rate.

### 2. Coach Details & Analytics
- **Profile Information**: Displays contact details and per-session pay rate.
- **Performance Stats**:
    - **Monthly Sessions**: Number of sessions conducted in the current month.
    - **Estimated Salary**: Calculated earnings for the current month based on session count and rate.
    - **Total Classes**: Cumulative count of all classes attended.
- **History**: View monthly salary history for the past few months.

### 3. Schedule Monitoring
- **Upcoming Sessions**: List of scheduled sessions assigned to the coach.
- **Shift Records**: Recent clock-in/clock-out records and their status (Completed/Scheduled).

## Technical Components

### Presentation Layer
- `CoachListPage` (`lib/features/coaches/presentation/coach_list_page.dart`): Displays the list of coaches and search functionality.
- `CoachDetailPage` (`lib/features/coaches/presentation/coach_detail_page.dart`): Detailed view for a specific coach, including stats and history.
- `_CreateCoachDialog`: UI for registering a new coach.

### Data Layer
- `AuthRepository`:
    - `watchCoaches`: Real-time stream of coach profiles.
    - `createCoachAccount`: Creates a new user account with the 'coach' role.
    - `getProfile`: Fetches detailed profile information.
- `HrRepository`:
    - `getMonthlySummary`: Calculates monthly session counts and salary.
    - `getHistorySummaries`: Fetches historical salary data.
    - `getCoachShifts`: Retrieves shift records.
- `SessionsRepository`:
    - `getUpcomingSessionsForCoach`: Fetches future sessions assigned to the coach.

## Data Models
- **Profile**: User profile with role 'coach'.
- **CoachSessionSummary**: Aggregated data for a coach's monthly performance.
- **CoachShift**: Record of a coach's attendance at a specific session.
