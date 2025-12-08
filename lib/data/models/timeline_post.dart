/// 媒体类型枚举
enum MediaType {
  video,
  image,
}

/// 动态可见性
enum PostVisibility {
  public,
  internal,
  private,
}

/// 训练动态模型
class TimelinePost {
  final String id;
  final String authorId;
  final String content;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final String? thumbnailUrl;
  final PostVisibility visibility;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  // 关联数据（兼容旧字段）
  final String? coachName;
  final List<String>? mentionedStudentIds;
  final List<String>? mentionedStudentNames;

  // 兼容旧字段
  String get coachId => authorId;
  String get mediaUrl => mediaUrls.isNotEmpty ? mediaUrls.first : '';
  String? get caption => content.isNotEmpty ? content : null;

  const TimelinePost({
    required this.id,
    required this.authorId,
    this.content = '',
    this.mediaUrls = const [],
    required this.mediaType,
    this.thumbnailUrl,
    this.visibility = PostVisibility.public,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.coachName,
    this.mentionedStudentIds,
    this.mentionedStudentNames,
  });

  factory TimelinePost.fromJson(Map<String, dynamic> json) {
    return TimelinePost(
      id: json['id'] as String,
      authorId: json['author_id'] as String? ?? json['coach_id'] as String,
      content: json['content'] as String? ?? json['caption'] as String? ?? '',
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'])
          : (json['media_url'] != null ? [json['media_url'] as String] : []),
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == json['media_type'],
        orElse: () => MediaType.image,
      ),
      thumbnailUrl: json['thumbnail_url'] as String?,
      visibility: PostVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => PostVisibility.public,
      ),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      coachName: json['coach_name'] as String?,
      mentionedStudentIds: json['mentioned_student_ids'] != null
          ? List<String>.from(json['mentioned_student_ids'])
          : null,
      mentionedStudentNames: json['mentioned_student_names'] != null
          ? List<String>.from(json['mentioned_student_names'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'content': content,
      'media_urls': mediaUrls,
      'media_type': mediaType.name,
      'thumbnail_url': thumbnailUrl,
      'visibility': visibility.name,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 动态提及关系
class PostMention {
  final String postId;
  final String studentId;

  const PostMention({
    required this.postId,
    required this.studentId,
  });

  factory PostMention.fromJson(Map<String, dynamic> json) {
    return PostMention(
      postId: json['post_id'] as String,
      studentId: json['student_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'student_id': studentId,
    };
  }
}
