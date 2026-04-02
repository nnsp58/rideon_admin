import '../models/booking_model.dart';
import 'supabase_service.dart';

class BookingService {
  /// Book a ride seat
  static Future<Map<String, dynamic>> bookRide({
    required String rideId,
    required String passengerId,
    required String passengerName,
    String? passengerPhone,
    required int seatsBooked,
    required double totalPrice,
  }) async {
    try {
      final response = await SupabaseService.client.rpc('book_ride_seat', params: {
        'p_ride_id': rideId,
        'p_passenger_id': passengerId,
        'p_passenger_name': passengerName,
        'p_passenger_phone': passengerPhone,
        'p_seats_booked': seatsBooked,
        'p_total_price': totalPrice,
      });

      return response;
    } catch (e) {
      throw Exception('Failed to book ride: $e');
    }
  }

  /// Cancel booking
  static Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    required String userId,
    String? reason,
  }) async {
    try {
      final response = await SupabaseService.client.rpc('cancel_booking', params: {
        'p_booking_id': bookingId,
        'p_user_id': userId,
        'p_reason': reason,
      });

      return response;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Get user's bookings
  static Stream<List<BookingModel>> getMyBookings({
    required String passengerId,
  }) {
    return SupabaseService.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('passenger_id', passengerId)
        .order('booked_at', ascending: false)
        .map((data) => data.map((json) => BookingModel.fromJson(json)).toList());
  }

  /// Get bookings for a ride (driver view)
  static Future<List<BookingModel>> getBookingsForRide({
    required String rideId,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('bookings')
          .select()
          .eq('ride_id', rideId)
          .order('booked_at', ascending: false);

      return response.map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get ride bookings: $e');
    }
  }

  /// Update booking status
  static Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? cancelReason,
  }) async {
    try {
      final updates = {'status': status};
      if (cancelReason != null) {
        updates['cancel_reason'] = cancelReason;
        updates['cancelled_at'] = DateTime.now().toIso8601String();
      }

      await SupabaseService.client
          .from('bookings')
          .update(updates)
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update booking: $e');
    }
  }

  /// Get booking by ID
  static Future<BookingModel?> getBookingById({
    required String bookingId,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();

      return response != null ? BookingModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }
}
