// SAME credentials as user app — same Supabase project
class SupabaseConstants {
  // Credentials moved to .env

  // Tables (user app ke saath exactly same names)
  static const usersTable = 'users';
  static const ridesTable = 'rides';
  static const bookingsTable = 'bookings';
  static const notificationsTable = 'notifications';
  static const sosAlertsTable = 'sos_alerts';
  static const messagesTable = 'messages';

  // Storage (same buckets)
  static const profilePhotosBucket = 'profile-photos';
  static const documentsBucket = 'user-documents';
}
