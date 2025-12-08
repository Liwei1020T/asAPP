# Authentication Feature

## Overview
The Authentication feature manages user access, registration, and the association between parents and students. It supports multiple user roles (Admin, Coach, Parent, Student) and provides mechanisms for secure login and account management.

## Key Functionalities

### 1. User Login
- **Email/Password Login**: Standard authentication using email and password.
- **Role-Based Redirection**: Automatically redirects users to their specific dashboard based on their role:
    - **Admin** -> Admin Dashboard
    - **Coach** -> Coach Dashboard
    - **Parent/Student** -> Parent Dashboard
- **Quick Login (Dev Mode)**: Provides one-click login for different roles (Coach, Parent, Admin) for testing purposes.

### 2. Registration & Verification
- **User Registration**: Allows new users to create accounts.
- **Email Verification**: Handles the verification process for new accounts.

### 3. Parent-Student Linking
- **Automatic Matching**: Automatically finds potential children matches based on the parent's registered phone number.
- **Manual Search**: Allows parents to search for their children by Name and Phone Number.
- **Binding Process**: Securely links selected student accounts to the parent's account, enabling access to the child's data.
- **Conflict Resolution**: Filters out students who are already linked to a parent.

## Technical Components

### Presentation Layer
- `LoginPage` (`lib/features/auth/presentation/login_page.dart`): Handles user login interactions.
- `LinkChildrenPage` (`lib/features/auth/presentation/link_children_page.dart`): UI for parents to find and link their children.
- `RegisterPage`: Handles user registration.
- `EmailVerificationPage`: Handles email verification.

### Data Layer
- `AuthRepository`:
    - `signInWithEmail`: Authenticates users with Supabase.
    - `getLinkedStudents`: Fetches students already linked to a parent.
    - `findStudentsByPhone`: Searches for students by phone number.
    - `findStudentsByNameAndPhone`: Searches for students by name and phone.
    - `bindStudentsToParent`: Updates student records to link them to a parent.

### State Management
- `authProviders`: Manages the current user state and authentication status.
- `currentUserProvider`: Provides global access to the currently logged-in user's profile.
