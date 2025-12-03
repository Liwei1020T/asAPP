/// 公告受众枚举
enum NoticeAudience {
  all,
  coach,
  parent,
}

/// 公告模型
class Notice {
  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final bool isUrgent;
  final NoticeAudience targetAudience;
  final String createdBy;
  final DateTime createdAt;

  const Notice({
    required this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.isUrgent = false,
    this.targetAudience = NoticeAudience.all,
    required this.createdBy,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      isUrgent: json['is_urgent'] as bool? ?? false,
      targetAudience: NoticeAudience.values.firstWhere(
        (e) => e.name == json['target_audience'],
        orElse: () => NoticeAudience.all,
      ),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'is_urgent': isUrgent,
      'target_audience': targetAudience.name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notice copyWith({
    String? id,
    String? title,
    String? content,
    bool? isPinned,
    bool? isUrgent,
    NoticeAudience? targetAudience,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      isUrgent: isUrgent ?? this.isUrgent,
      targetAudience: targetAudience ?? this.targetAudience,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
