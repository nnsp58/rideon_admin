import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'auth_provider.dart';


// My Bookings Provider - real-time stream
final myBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser.maybeWhen(
    data: (user) {
      if (user != null) {
        return BookingService.getMyBookings(passengerId: user.id);
      }
      return Stream.value([]);
    },
    orElse: () => Stream.value([]),
  );
});

// Book Ride Provider
final bookRideProvider = StateNotifierProvider<BookRideNotifier, AsyncValue<void>>((ref) {
  return BookRideNotifier();
});

class BookRideNotifier extends StateNotifier<AsyncValue<void>> {
  BookRideNotifier() : super(const AsyncValue.data(null));

  Future<void> book({
    required String rideId,
    required String passengerId,
    required String passengerName,
    String? passengerPhone,
    required int seatsBooked,
    required double totalPrice,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await BookingService.bookRide(
        rideId: rideId,
        passengerId: passengerId,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        seatsBooked: seatsBooked,
        totalPrice: totalPrice,
      );

      if (result['success'] == true) {
        state = const AsyncValue.data(null);
      } else {
        throw Exception(result['error'] ?? 'Booking failed');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> cancel({
    required String bookingId,
    required String userId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await BookingService.cancelBooking(
        bookingId: bookingId,
        userId: userId,
        reason: reason,
      );

      if (result['success'] == true) {
        state = const AsyncValue.data(null);
      } else {
        throw Exception(result['error'] ?? 'Cancellation failed');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Booking Details Provider
final bookingDetailsProvider = FutureProvider.family<BookingModel?, String>((ref, bookingId) async {
  return await BookingService.getBookingById(bookingId: bookingId);
});

// Ride Bookings Provider (for driver)
final rideBookingsProvider = FutureProvider.family<List<BookingModel>, String>((ref, rideId) async {
  return await BookingService.getBookingsForRide(rideId: rideId);
});
