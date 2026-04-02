import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AdminService {
  static final _client = SupabaseService.client;

  static Future<Map<String, int>> getStats() async {
    final futures = await Future.wait<int>([
      _client.from('users').count(CountOption.exact),
      _client.from('rides').count(CountOption.exact),
      _client.from('sos_alerts').count(CountOption.exact),
      _client.from('users').count(CountOption.exact).eq('doc_verification_status', 'pending'),
    ]);
    
    return {
      'totalUsers': futures[0],
      'totalRides': futures[1],
      'sosAlerts': futures[2],
      'pendingVerifications': futures[3],
    };
  }

  static Future<void> forceCancelRide(String rideId) async {
    await _client.from('rides').update({'status': 'cancelled'}).eq('id', rideId);
  }

  static Future<void> updateVerificationStatus(String userId, String status, {String? reason}) async {
    await _client.from('users').update({
      'doc_verification_status': status,
      'doc_rejection_reason': reason,
      'doc_reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
