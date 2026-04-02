import 'package:rideon_admin/services/supabase_service.dart';

class NotificationService {
  final _client = SupabaseService.client;

  // User ko notification bhejo (admin actions ke baad)
  Future<void> notify({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? rideId,
    String? bookingId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'ride_id': rideId,
      'booking_id': bookingId,
      'is_read': false,
    });
  }
}
