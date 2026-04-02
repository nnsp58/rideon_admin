import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/admin_router.dart';
import 'core/theme/app_theme.dart';
import 'services/supabase_service.dart';

class RideOnAdminApp extends ConsumerWidget {
  const RideOnAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'RideOn Admin',
      theme: AppTheme.lightTheme,
      routerConfig: AdminRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Initialize Supabase when app starts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SupabaseService.initialize().catchError((error) {
            debugPrint('Failed to initialize Supabase: $error');
          });
        });

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
