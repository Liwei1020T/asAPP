## ADDED Requirements

### Requirement: Parent Replacement Eligibility
Parents SHALL be able to start a replacement request only after marking the child absent for a specific session and before the target session starts.

#### Scenario: Start replacement from an absence
- **WHEN** a parent marks a child absent for a session and selects to request a replacement
- **THEN** the system SHALL verify the absence is recorded, ensure no existing replacement for that source session, and open replacement slot discovery.

#### Scenario: Block when no absence recorded
- **WHEN** a parent attempts to request a replacement without a recorded absence for the source session
- **THEN** the system SHALL reject the request and prompt the parent to mark the absence first.

### Requirement: Replacement Slot Discovery
The system SHALL list eligible sessions for replacement with filters and capacity visibility.

#### Scenario: List eligible sessions
- **WHEN** the parent opens the replacement search with optional filters (date range, venue, level)
- **THEN** the system SHALL show sessions that match the filters, have remaining capacity, and do not overlap with the child¡¯s existing bookings.

### Requirement: Replacement Request Submission
The system SHALL validate and record replacement requests, auto-confirming when rules are satisfied and otherwise queuing for review.

#### Scenario: Auto-confirm when eligibility passes
- **WHEN** the parent submits a replacement for a session that matches level rules, has capacity, and does not conflict with the child¡¯s schedule
- **THEN** the system SHALL create a replacement request with status `confirmed`, associate the student with the target session, and reduce available capacity.

#### Scenario: Pending when rules require review
- **WHEN** the submission fails auto-confirm criteria (e.g., capacity reached or rule mismatch)
- **THEN** the system SHALL create the request with status `pending`, leave capacity unchanged, and surface it for admin/coach review.

### Requirement: Replacement Status & Updates
Parents SHALL be able to track and manage their replacement requests.

#### Scenario: Track replacement status
- **WHEN** a parent views the ¡°My Replacements¡± list
- **THEN** the system SHALL display each request with status (pending, confirmed, rejected, cancelled) and source/target session details.

#### Scenario: Cancel before start
- **WHEN** a parent cancels a pending or confirmed replacement before the target session starts
- **THEN** the system SHALL mark it `cancelled`, release any held capacity, and remove the child from the target session roster.

### Requirement: Replacement Notifications
The system SHALL notify parents when a replacement request is confirmed, rejected, or cancelled.

#### Scenario: Notify on confirmation or rejection
- **WHEN** a replacement request transitions to `confirmed` or `rejected`
- **THEN** the system SHALL send a notification to the parent with the decision, target session details, and (when rejected) a reason.

#### Scenario: Notify on cancellation
- **WHEN** a replacement request is cancelled before the target session starts
- **THEN** the system SHALL notify the parent that the replacement was cancelled and that the child is removed from the target session roster.
