# Timeline Feature (Moments)

## Overview
The Timeline feature, also known as "Moments," is a social feed where coaches can share training updates, photos, and videos with parents and students. It fosters engagement and keeps the community connected.

## Key Functionalities

### 1. Social Feed
- **Posts**: View a chronological feed of updates from coaches.
- **Media**: Posts can include multiple images or videos.
- **Visibility**: Posts can be marked as internal (staff only) or public.

### 2. Interactions
- **Likes**: Users can like posts to show appreciation.
- **Comments**: Users can comment on posts to engage in discussions.
- **Sharing**: Posts can be shared via a generated link.
- **Deletion**: Authors and admins can delete a post; associated likes/comments are removed.

### 3. Content Creation (Coach/Admin)
- **Create Post**: Compose text and attach media (images/videos).
- **Media Upload**: Integrated file picker and upload to local storage.

## Technical Components

### Presentation Layer
- `TimelineListPage` (`lib/features/timeline/presentation/timeline_list_page.dart`): Main feed interface.
- `_TimelinePostCard`: Widget for displaying a single post.
- `_PostDetailSheet`: Detailed view for comments and full content.
- `_CreatePostDialog`: Interface for creating new posts.

### Data Layer
- `TimelineRepository`:
    - `watchAllPosts`: Real-time stream of timeline posts.
    - `toggleLike`: Handles like/unlike actions.
    - `createPost`: Publishes a new post.
    - `deletePost`: Deletes a post and its likes/comments (author or admin).
- `StorageRepository`: Handles media uploads to local disk under `local_storage/timeline/...`, returning URLs based on `StorageConfig.publicBaseUrl`.

## Data Models
- **TimelinePost**:
    - `id`: Unique identifier.
    - `content`: Text body.
    - `mediaUrls`: List of image/video URLs.
    - `mediaType`: Enum (image, video).
    - `likesCount` / `commentsCount`: Engagement metrics.
    - `authorId`: ID of the creator.
- **TimelineComment**:
    - `id`: Unique identifier.
    - `content`: Comment text.
    - `userId`: Author of the comment.
