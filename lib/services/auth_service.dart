import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rideon_admin/models/user_model.dart';
import 'package:rideon_admin/services/supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;

  // Admin login only — email + password
  Future<UserModel?> signInAdmin(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('User account not found.');
      }

      // is_admin check
      final data = await _client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (data == null) {
        // User created in auth but not in users table yet?
        // This is where tr_master_admin trigger should have worked!
        throw Exception('User profile not found in database.');
      }

      final user = UserModel.fromJson(data);

      if (!user.isAdmin) {
        await _client.auth.signOut();
        throw Exception('Unauthorized: Admin access required.');
      }

      return user;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Email ya password galat hai.');
      } else if (e.message.contains('Email not confirmed')) {
        throw Exception('Email confirm nahi hai. Dashboard se manually confirm karein.');
      } else {
        throw Exception('Auth Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<UserModel?> getCurrentAdmin() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      final user = UserModel.fromJson(data);
      return user.isAdmin ? user : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;
}
