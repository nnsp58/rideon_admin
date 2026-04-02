// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingModelImpl _$$BookingModelImplFromJson(Map<String, dynamic> json) =>
    _$BookingModelImpl(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      passengerId: json['passenger_id'] as String,
      driverId: json['driver_id'] as String,
      passengerName: json['passenger_name'] as String,
      passengerPhone: json['passenger_phone'] as String?,
      seatsBooked: (json['seats_booked'] as num?)?.toInt() ?? 1,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String? ?? 'confirmed',
      bookedAt: DateTime.parse(json['booked_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      cancelReason: json['cancel_reason'] as String?,
    );

Map<String, dynamic> _$$BookingModelImplToJson(_$BookingModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ride_id': instance.rideId,
      'passenger_id': instance.passengerId,
      'driver_id': instance.driverId,
      'passenger_name': instance.passengerName,
      'passenger_phone': instance.passengerPhone,
      'seats_booked': instance.seatsBooked,
      'total_price': instance.totalPrice,
      'status': instance.status,
      'booked_at': instance.bookedAt.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'cancel_reason': instance.cancelReason,
    };
