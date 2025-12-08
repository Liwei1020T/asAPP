# Playbook Feature

## Overview
The Playbook feature serves as a digital library for training resources. It allows coaches and admins to organize and share educational content like videos, documents, and guides with students and other coaches.

## Key Functionalities

### 1. Material Management
- **Categorization**: Resources are organized into predefined categories:
    - **Basic Technology**: Fundamental badminton skills.
    - **Footwork**: Movement drills.
    - **Hitting Technology**: Stroke techniques.
    - **Tactics**: Singles and doubles strategies.
    - **Fitness**: Strength and conditioning guides.
- **Search**: Users can search for materials by title or description.
- **CRUD Operations**: Admins can create, edit, and delete training materials.

### 2. Content Types
The system supports various media formats:
- **Video**: Instructional videos (hosted or linked).
- **Document**: PDF guides or text documents.
- **Image**: Diagrams or photo guides.
- **Link**: External resources (e.g., YouTube links).

### 3. Viewing Experience
- **Preview**: Thumbnail previews for materials.
- **Detail View**: Full description, tags, and view count.
- **Direct Access**: One-click access to open links or preview images.

## Technical Components

### Presentation Layer
- `PlaybookListPage` (`lib/features/playbook/presentation/playbook_list_page.dart`): Main interface for browsing and managing the playbook.
- `_CreateMaterialDialog`: Form for adding or editing materials.
- `_MaterialCard`: Widget for displaying individual resources.

### Data Layer
- `PlaybookRepository`:
    - `watchMaterials`: Real-time stream of all training materials.
    - `createMaterial` / `updateMaterial` / `deleteMaterial`: Manages the lifecycle of playbook entries.
- `StorageRepository`: Upload helper that sends files to the HTTP upload endpoint configured via
  `StorageConfig.publicBaseUrl` (for example a Cloudflare‑exposed server writing into `local_storage/playbook/...`)
  and returns a public URL saved in `TrainingMaterial.contentUrl`.

## Data Models
- **TrainingMaterial**:
    - `id`: Unique identifier.
    - `title`: Resource title.
    - `description`: Detailed explanation.
    - `type`: Enum (video, document, image, link).
    - `category`: Category name.
    - `contentUrl`: URL to the file or external link.
    - `thumbnailUrl`: Preview image URL.
    - `viewCount`: Usage metric.
