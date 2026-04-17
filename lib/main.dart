import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rideon_admin/core/constants/supabase_constants.dart';
import 'package:rideon_admin/core/theme/app_theme.dart';
import 'package:rideon_admin/core/router/app_router.dart';

// Direct credentials for web deployment
const String _supabaseUrl = 'https://yrlsxouhgqfswppubhhn.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlybHN4b3VoZ3Fmc3dwcHViaGhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMTgyMTAsImV4cCI6MjA4ODc5NDIxMH0.eNGJJW21GVjX3kCsav4d0D14GTgjLx3lDO-bxmCwFgI';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Direct credentials - no .env loading needed
  final url = _supabaseUrl;
  final key = _supabaseAnonKey;
  
  await Supabase.initialize(
    url: url,
    anonKey: key,
  );
  
  runApp(
    const ProviderScope(
      child: RideOnAdminApp(),
    ),
  );
}

class RideOnAdminApp extends StatelessWidget {
  const RideOnAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RideOn Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
