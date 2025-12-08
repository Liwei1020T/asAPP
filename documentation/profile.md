# Profile Feature

## Overview
The Profile feature allows users to manage their personal account information, security settings, and preferences. It is accessible to all user roles (Admin, Coach, Parent, Student).

## Key Functionalities

### 1. Account Management
- **Personal Details**: View and update display name and phone number.
- **Avatar**: Upload and update profile picture.
- **Role Display**: View current user role (e.g., Coach, Parent).

### 2. Security Settings
- **Password Update**: Change login password securely.
- **Logout**: Sign out of the current session.

## Technical Components

### Presentation Layer
- `ProfilePage` (`lib/features/profile/presentation/profile_page.dart`): Main user interface for profile management.

### Data Layer
- `AuthRepository`:
    - `updateProfile`: Updates user metadata (name, phone, avatar).
    - `updatePassword`: Handles password changes.
    - `signOut`: Logs the user out.
- `StorageRepository` (`lib/data/repositories/storage_repository.dart`):
    - `uploadFile`: Uploads avatar images to the HTTP upload API at `StorageConfig.publicBaseUrl` and
      returns a public URL (typically pointing to a file stored under `local_storage/` on the central server).

## Data Models
- **Profile**: User profile data including `fullName`, `phoneNumber`, `avatarUrl`, and `role`.
