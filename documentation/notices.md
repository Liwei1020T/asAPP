# Notices Feature

## Overview
The Notices feature allows administrators to broadcast announcements to specific user groups (Coaches, Parents, or All). It supports pinning important messages and marking urgent alerts.

## Key Functionalities

### 1. Notice Management (Admin)
- **Create Notice**: Publish new announcements with a title, content, and target audience.
- **Edit Notice**: Modify existing notices.
- **Delete Notice**: Remove outdated announcements.
- **Pin/Unpin**: Pin important notices to the top of the list for better visibility.
- **Urgent Flag**: Mark critical notices as "Urgent" to highlight them visually.

### 2. Notice Viewing
- **List View**: Browse all notices sorted by date (pinned items first).
- **Filtering**: Filter notices by target audience (All, Coach, Parent) or pinned status.
- **Detail View**: Read the full content of a notice in a dedicated view.

## Technical Components

### Presentation Layer
- `NoticeListPage` (`lib/features/notices/presentation/notice_list_page.dart`): Admin interface for managing notices.
- `NoticeDetailSheet` (`lib/features/notices/presentation/notice_detail_sheet.dart`): Bottom sheet for viewing notice details.
- `_CreateNoticeDialog`: Dialog for creating and editing notices.
- `_NoticeCard`: Widget for displaying a single notice item in the list.

### Data Layer
- `NoticeRepository`:
    - `watchNotices`: Real-time stream of all notices.
    - `createNotice`: Adds a new notice to the database.
    - `updateNotice`: Updates an existing notice.
    - `deleteNotice`: Removes a notice.
    - `fetchNotices`: Fetches notices for a specific audience (used in Dashboards).

## Data Models
- **Notice**: Represents an announcement.
    - `id`: Unique identifier.
    - `title`: Title of the notice.
    - `content`: Body text.
    - `targetAudience`: Enum (all, coach, parent).
    - `isPinned`: Boolean flag for pinning.
    - `isUrgent`: Boolean flag for urgency.
    - `createdAt`: Timestamp.
    - `createdBy`: ID of the admin who created it.
