/// 训练教材类型
enum TrainingMaterialType {
  video,
  document,
  image,
  link,
}

/// 教材可见性
enum MaterialVisibility {
  public,    // 所有用户
  coaches,   // 仅教练
  internal,  // 内部员工
}

/// 训练教材模型
class TrainingMaterial {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final TrainingMaterialType type;
  final String? contentUrl;
  final String? thumbnailUrl;
  final List<String>? keyPoints;
  final List<String>? tags;
  final MaterialVisibility visibility;
  final String? authorId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewCount;

  const TrainingMaterial({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.type = TrainingMaterialType.video,
    this.contentUrl,
    this.thumbnailUrl,
    this.keyPoints,
    this.tags,
    this.visibility = MaterialVisibility.public,
    this.authorId,
    required this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
  });

  // 兼容旧字段
  String? get videoUrl => type == TrainingMaterialType.video ? contentUrl : null;

  factory TrainingMaterial.fromJson(Map<String, dynamic> json) {
    return TrainingMaterial(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      type: TrainingMaterialType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TrainingMaterialType.video,
      ),
      contentUrl: json['content_url'] as String? ?? json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      keyPoints: json['key_points'] != null
          ? List<String>.from(json['key_points'])
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      visibility: MaterialVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => MaterialVisibility.public,
      ),
      authorId: json['author_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      viewCount: json['view_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'type': type.name,
      'content_url': contentUrl,
      'thumbnail_url': thumbnailUrl,
      'key_points': keyPoints,
      'tags': tags,
      'visibility': visibility.name,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'view_count': viewCount,
    };
  }
}

/// 教材分类模型
class MaterialCategory {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final int sortOrder;

  const MaterialCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon = 'folder',
    this.color = '#9E9E9E',
    this.sortOrder = 0,
  });

  factory MaterialCategory.fromJson(Map<String, dynamic> json) {
    return MaterialCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'folder',
      color: json['color'] as String? ?? '#9E9E9E',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    };
  }
}
