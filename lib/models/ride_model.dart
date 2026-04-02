import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String? driverPhotoUrl;
  final String fromLocation;
  final String toLocation;
  final DateTime departureDatetime;
  final int availableSeats;
  final int totalSeats;
  final double pricePerSeat;
  final String? vehicleInfo;
  final String? vehicleType;
  final String status; // active/full/completed/cancelled
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhotoUrl,
    required this.fromLocation,
    required this.toLocation,
    required this.departureDatetime,
    required this.availableSeats,
    required this.totalSeats,
    required this.pricePerSeat,
    this.vehicleInfo,
    this.vehicleType,
    required this.status,
    required this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'],
      driverId: json['driver_id'],
      driverName: json['driver_name'] ?? 'Unknown',
      driverPhotoUrl: json['driver_photo_url'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      departureDatetime: DateTime.parse(json['departure_datetime']),
      availableSeats: json['available_seats'] ?? 0,
      totalSeats: json['total_seats'] ?? 0,
      pricePerSeat: (json['price_per_seat'] as num).toDouble(),
      vehicleInfo: json['vehicle_info'],
      vehicleType: json['vehicle_type'],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  int get bookedSeats => totalSeats - availableSeats;
  String get formattedDate =>
    DateFormat('dd MMM • hh:mm a').format(departureDatetime);
  String get formattedPrice => '₹${pricePerSeat.toStringAsFixed(0)}';
  
  Color get statusColor {
    switch (status) {
      case 'active': return AppColors.success;
      case 'full': return AppColors.info;
      case 'cancelled': return AppColors.error;
      case 'completed': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverPhotoUrl,
    String? fromLocation,
    String? toLocation,
    DateTime? departureDatetime,
    int? availableSeats,
    int? totalSeats,
    double? pricePerSeat,
    String? vehicleInfo,
    String? vehicleType,
    String? status,
    DateTime? createdAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      departureDatetime: departureDatetime ?? this.departureDatetime,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      vehicleType: vehicleType ?? this.vehicleType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
