class UserModel {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final double rating;
  final int totalRidesGiven;
  final int totalRidesTaken;
  final bool isAdmin;
  final bool isBanned;
  final bool setupComplete;
  final String? vehicleModel;
  final String? vehicleType;
  final String? vehicleLicensePlate;
  final String? vehicleColor;
  final String? docDrivingLicenseFront;
  final String? docDrivingLicenseBack;
  final String? docVehicleRc;
  final String docVerificationStatus; // not_submitted/pending/approved/rejected
  final String? docRejectionReason;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.photoUrl,
    required this.rating,
    required this.totalRidesGiven,
    required this.totalRidesTaken,
    required this.isAdmin,
    required this.isBanned,
    required this.setupComplete,
    this.vehicleModel,
    this.vehicleType,
    this.vehicleLicensePlate,
    this.vehicleColor,
    this.docDrivingLicenseFront,
    this.docDrivingLicenseBack,
    this.docVehicleRc,
    required this.docVerificationStatus,
    this.docRejectionReason,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'],
      photoUrl: json['photo_url'],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalRidesGiven: json['total_rides_given'] ?? 0,
      totalRidesTaken: json['total_rides_taken'] ?? 0,
      isAdmin: json['is_admin'] ?? false,
      isBanned: json['is_banned'] ?? false,
      setupComplete: json['setup_complete'] ?? false,
      vehicleModel: json['vehicle_model'],
      vehicleType: json['vehicle_type'],
      vehicleLicensePlate: json['vehicle_license_plate'],
      vehicleColor: json['vehicle_color'],
      docDrivingLicenseFront: json['doc_driving_license_front'],
      docDrivingLicenseBack: json['doc_driving_license_back'],
      docVehicleRc: json['doc_vehicle_rc'],
      docVerificationStatus: json['doc_verification_status'] ?? 'not_submitted',
      docRejectionReason: json['doc_rejection_reason'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'photo_url': photoUrl,
      'rating': rating,
      'total_rides_given': totalRidesGiven,
      'total_rides_taken': totalRidesTaken,
      'is_admin': isAdmin,
      'is_banned': isBanned,
      'setup_complete': setupComplete,
      'vehicle_model': vehicleModel,
      'vehicle_type': vehicleType,
      'vehicle_license_plate': vehicleLicensePlate,
      'vehicle_color': vehicleColor,
      'doc_driving_license_front': docDrivingLicenseFront,
      'doc_driving_license_back': docDrivingLicenseBack,
      'doc_vehicle_rc': docVehicleRc,
      'doc_verification_status': docVerificationStatus,
      'doc_rejection_reason': docRejectionReason,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? photoUrl,
    double? rating,
    int? totalRidesGiven,
    int? totalRidesTaken,
    bool? isAdmin,
    bool? isBanned,
    bool? setupComplete,
    String? vehicleModel,
    String? vehicleType,
    String? vehicleLicensePlate,
    String? vehicleColor,
    String? docDrivingLicenseFront,
    String? docDrivingLicenseBack,
    String? docVehicleRc,
    String? docVerificationStatus,
    String? docRejectionReason,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      totalRidesGiven: totalRidesGiven ?? this.totalRidesGiven,
      totalRidesTaken: totalRidesTaken ?? this.totalRidesTaken,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      setupComplete: setupComplete ?? this.setupComplete,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      docDrivingLicenseFront: docDrivingLicenseFront ?? this.docDrivingLicenseFront,
      docDrivingLicenseBack: docDrivingLicenseBack ?? this.docDrivingLicenseBack,
      docVehicleRc: docVehicleRc ?? this.docVehicleRc,
      docVerificationStatus: docVerificationStatus ?? this.docVerificationStatus,
      docRejectionReason: docRejectionReason ?? this.docRejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isVerified => docVerificationStatus == 'approved';
  bool get hasPendingDocs => docVerificationStatus == 'pending';
  bool get hasAllDocuments =>
    docDrivingLicenseFront != null &&
    docDrivingLicenseBack != null &&
    docVehicleRc != null;
}
