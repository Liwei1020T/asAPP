/// 场地模型
class Venue {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final double? radiusM; // 打卡范围半径（米）

  const Venue({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.radiusM,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      radiusM: json['radius_m'] != null
          ? (json['radius_m'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_m': radiusM,
    };
  }
}
