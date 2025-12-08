# Salary Feature

## Overview
The Salary feature provides coaches with a transparent view of their earnings and work history. It calculates estimated income based on completed sessions and the coach's individual pay rate.

## Key Functionalities

### 1. Earnings Dashboard
- **Monthly Overview**: Displays total estimated income for the selected month.
- **Session Stats**: Shows the total number of completed sessions.
- **Rate Information**: Displays the coach's current rate per session.

### 2. History & Navigation
- **Month Selector**: Allows coaches to navigate back and forth to view past months' earnings.
- **Daily Breakdown**: Lists all shifts for the selected month, grouped by date.

### 3. Shift Tracking
- **Today's Shifts**: Prominently displays shifts scheduled for the current day with their status.
- **Status Indicators**: Visual tags for shift status:
    - **Completed**: Successfully attended and tracked.
    - **Scheduled**: Upcoming sessions.
    - **Cancelled**: Sessions that were called off.

## Technical Components

### Presentation Layer
- `SalaryPage` (`lib/features/salary/presentation/salary_page.dart`): Main interface for salary and shift history.
- `_ShiftCard`: Widget for displaying individual shift details.

### Data Layer
- `HrRepository`:
    - `watchCoachShifts`: Real-time stream of a coach's shifts for a specific month.
- **Calculation Logic**:
    - Salary is calculated client-side as `completed_sessions * rate_per_session`.

## Data Models
- **CoachShift**: Represents a single work unit.
    - `id`: Unique identifier.
    - `date`: Date of the shift.
    - `startTime` / `endTime`: Duration.
    - `status`: Enum (scheduled, completed, cancelled).
    - `className`: Name of the class taught.
    - `clockInAt` / `clockOutAt`: Timestamp for attendance.
