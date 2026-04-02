class BookingModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String driverId;
  final String passengerName;
  final String? passengerPhone;
  final int seatsBooked;
  final double totalPrice;
  final String status; // confirmed/cancelled/completed
  final DateTime bookedAt;

  BookingModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.driverId,
    required this.passengerName,
    this.passengerPhone,
    required this.seatsBooked,
    required this.totalPrice,
    required this.status,
    required this.bookedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      rideId: json['ride_id'],
      passengerId: json['passenger_id'],
      driverId: json['driver_id'],
      passengerName: json['passenger_name'] ?? 'Unknown',
      passengerPhone: json['passenger_phone'],
      seatsBooked: json['seats_booked'] ?? 0,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] ?? 'confirmed',
      bookedAt: DateTime.parse(json['booked_at']),
    );
  }

  String get formattedTotal => '₹${totalPrice.toStringAsFixed(0)}';
}
