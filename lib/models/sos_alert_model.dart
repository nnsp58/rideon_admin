class SosAlertModel {
  final String id;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? emergencyType; // accident/breakdown/harassment/medical/other
  final bool isActive;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  SosAlertModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.emergencyType,
    required this.isActive,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    return SosAlertModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown User',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['location_name'],
      emergencyType: json['emergency_type'],
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      resolvedBy: json['resolved_by'],
    );
  }

  String get mapUrl =>
    'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude';

  String get emergencyLabel {
    const labels = {
      'accident': 'Accident',
      'breakdown': 'Breakdown',
      'harassment': 'Harassment',
      'medical': 'Medical',
      'other': 'Emergency',
    };
    return labels[emergencyType] ?? 'Emergency';
  }

  String get timeElapsed {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
    return '${diff.inHours} ghante pehle';
  }
}
