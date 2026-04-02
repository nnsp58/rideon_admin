// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) {
  return _BookingModel.fromJson(json);
}

/// @nodoc
mixin _$BookingModel {
  String get id => throw _privateConstructorUsedError;
  String get rideId => throw _privateConstructorUsedError;
  String get passengerId => throw _privateConstructorUsedError;
  String get driverId => throw _privateConstructorUsedError;
  String get passengerName => throw _privateConstructorUsedError;
  String? get passengerPhone => throw _privateConstructorUsedError;
  int get seatsBooked => throw _privateConstructorUsedError;
  double get totalPrice => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get bookedAt => throw _privateConstructorUsedError;
  DateTime? get cancelledAt => throw _privateConstructorUsedError;
  String? get cancelReason => throw _privateConstructorUsedError;

  /// Serializes this BookingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingModelCopyWith<BookingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingModelCopyWith<$Res> {
  factory $BookingModelCopyWith(
          BookingModel value, $Res Function(BookingModel) then) =
      _$BookingModelCopyWithImpl<$Res, BookingModel>;
  @useResult
  $Res call(
      {String id,
      String rideId,
      String passengerId,
      String driverId,
      String passengerName,
      String? passengerPhone,
      int seatsBooked,
      double totalPrice,
      String status,
      DateTime bookedAt,
      DateTime? cancelledAt,
      String? cancelReason});
}

/// @nodoc
class _$BookingModelCopyWithImpl<$Res, $Val extends BookingModel>
    implements $BookingModelCopyWith<$Res> {
  _$BookingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? rideId = null,
    Object? passengerId = null,
    Object? driverId = null,
    Object? passengerName = null,
    Object? passengerPhone = freezed,
    Object? seatsBooked = null,
    Object? totalPrice = null,
    Object? status = null,
    Object? bookedAt = null,
    Object? cancelledAt = freezed,
    Object? cancelReason = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      rideId: null == rideId
          ? _value.rideId
          : rideId // ignore: cast_nullable_to_non_nullable
              as String,
      passengerId: null == passengerId
          ? _value.passengerId
          : passengerId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: null == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String,
      passengerName: null == passengerName
          ? _value.passengerName
          : passengerName // ignore: cast_nullable_to_non_nullable
              as String,
      passengerPhone: freezed == passengerPhone
          ? _value.passengerPhone
          : passengerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      seatsBooked: null == seatsBooked
          ? _value.seatsBooked
          : seatsBooked // ignore: cast_nullable_to_non_nullable
              as int,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      bookedAt: null == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelReason: freezed == cancelReason
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookingModelImplCopyWith<$Res>
    implements $BookingModelCopyWith<$Res> {
  factory _$$BookingModelImplCopyWith(
          _$BookingModelImpl value, $Res Function(_$BookingModelImpl) then) =
      __$$BookingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String rideId,
      String passengerId,
      String driverId,
      String passengerName,
      String? passengerPhone,
      int seatsBooked,
      double totalPrice,
      String status,
      DateTime bookedAt,
      DateTime? cancelledAt,
      String? cancelReason});
}

/// @nodoc
class __$$BookingModelImplCopyWithImpl<$Res>
    extends _$BookingModelCopyWithImpl<$Res, _$BookingModelImpl>
    implements _$$BookingModelImplCopyWith<$Res> {
  __$$BookingModelImplCopyWithImpl(
      _$BookingModelImpl _value, $Res Function(_$BookingModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? rideId = null,
    Object? passengerId = null,
    Object? driverId = null,
    Object? passengerName = null,
    Object? passengerPhone = freezed,
    Object? seatsBooked = null,
    Object? totalPrice = null,
    Object? status = null,
    Object? bookedAt = null,
    Object? cancelledAt = freezed,
    Object? cancelReason = freezed,
  }) {
    return _then(_$BookingModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      rideId: null == rideId
          ? _value.rideId
          : rideId // ignore: cast_nullable_to_non_nullable
              as String,
      passengerId: null == passengerId
          ? _value.passengerId
          : passengerId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: null == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String,
      passengerName: null == passengerName
          ? _value.passengerName
          : passengerName // ignore: cast_nullable_to_non_nullable
              as String,
      passengerPhone: freezed == passengerPhone
          ? _value.passengerPhone
          : passengerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      seatsBooked: null == seatsBooked
          ? _value.seatsBooked
          : seatsBooked // ignore: cast_nullable_to_non_nullable
              as int,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      bookedAt: null == bookedAt
          ? _value.bookedAt
          : bookedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelReason: freezed == cancelReason
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingModelImpl extends _BookingModel {
  const _$BookingModelImpl(
      {required this.id,
      required this.rideId,
      required this.passengerId,
      required this.driverId,
      required this.passengerName,
      this.passengerPhone,
      this.seatsBooked = 1,
      required this.totalPrice,
      this.status = 'confirmed',
      required this.bookedAt,
      this.cancelledAt,
      this.cancelReason})
      : super._();

  factory _$BookingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingModelImplFromJson(json);

  @override
  final String id;
  @override
  final String rideId;
  @override
  final String passengerId;
  @override
  final String driverId;
  @override
  final String passengerName;
  @override
  final String? passengerPhone;
  @override
  @JsonKey()
  final int seatsBooked;
  @override
  final double totalPrice;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime bookedAt;
  @override
  final DateTime? cancelledAt;
  @override
  final String? cancelReason;

  @override
  String toString() {
    return 'BookingModel(id: $id, rideId: $rideId, passengerId: $passengerId, driverId: $driverId, passengerName: $passengerName, passengerPhone: $passengerPhone, seatsBooked: $seatsBooked, totalPrice: $totalPrice, status: $status, bookedAt: $bookedAt, cancelledAt: $cancelledAt, cancelReason: $cancelReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.rideId, rideId) || other.rideId == rideId) &&
            (identical(other.passengerId, passengerId) ||
                other.passengerId == passengerId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.passengerName, passengerName) ||
                other.passengerName == passengerName) &&
            (identical(other.passengerPhone, passengerPhone) ||
                other.passengerPhone == passengerPhone) &&
            (identical(other.seatsBooked, seatsBooked) ||
                other.seatsBooked == seatsBooked) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.bookedAt, bookedAt) ||
                other.bookedAt == bookedAt) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
            (identical(other.cancelReason, cancelReason) ||
                other.cancelReason == cancelReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      rideId,
      passengerId,
      driverId,
      passengerName,
      passengerPhone,
      seatsBooked,
      totalPrice,
      status,
      bookedAt,
      cancelledAt,
      cancelReason);

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingModelImplCopyWith<_$BookingModelImpl> get copyWith =>
      __$$BookingModelImplCopyWithImpl<_$BookingModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingModelImplToJson(
      this,
    );
  }
}

abstract class _BookingModel extends BookingModel {
  const factory _BookingModel(
      {required final String id,
      required final String rideId,
      required final String passengerId,
      required final String driverId,
      required final String passengerName,
      final String? passengerPhone,
      final int seatsBooked,
      required final double totalPrice,
      final String status,
      required final DateTime bookedAt,
      final DateTime? cancelledAt,
      final String? cancelReason}) = _$BookingModelImpl;
  const _BookingModel._() : super._();

  factory _BookingModel.fromJson(Map<String, dynamic> json) =
      _$BookingModelImpl.fromJson;

  @override
  String get id;
  @override
  String get rideId;
  @override
  String get passengerId;
  @override
  String get driverId;
  @override
  String get passengerName;
  @override
  String? get passengerPhone;
  @override
  int get seatsBooked;
  @override
  double get totalPrice;
  @override
  String get status;
  @override
  DateTime get bookedAt;
  @override
  DateTime? get cancelledAt;
  @override
  String? get cancelReason;

  /// Create a copy of BookingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingModelImplCopyWith<_$BookingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
