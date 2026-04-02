import 'package:rideon_admin/services/supabase_service.dart';

class StorageService {
  final _client = SupabaseService.client;

  // Admin ke liye document signed URL (24 hours)
  Future<String?> getDocumentSignedUrl(String path) async {
    if (path.isEmpty) return null;
    try {
      // remove bucket name if it's already in the path
      final cleanPath = path.startsWith('user-documents/') 
          ? path.replaceFirst('user-documents/', '') 
          : path;
          
      return await _client.storage
          .from('user-documents')
          .createSignedUrl(cleanPath, 86400);  // 24 hours
    } catch (e) {
      print('Error getting signed URL: $e');
      return null;
    }
  }

  // Profile photo public URL
  String getProfilePhotoUrl(String uid) {
    return _client.storage
        .from('profile-photos')
        .getPublicUrl('$uid/avatar.jpg');
  }
}
