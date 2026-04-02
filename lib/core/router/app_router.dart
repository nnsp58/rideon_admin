import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideon_admin/screens/login/login_screen.dart';
import 'package:rideon_admin/screens/shell/admin_shell.dart';
import 'package:rideon_admin/services/supabase_service.dart';
import 'package:rideon_admin/screens/dashboard/dashboard_screen.dart';
import 'package:rideon_admin/screens/users/users_screen.dart';
import 'package:rideon_admin/screens/documents/documents_screen.dart';
import 'package:rideon_admin/screens/sos/sos_screen.dart';
import 'package:rideon_admin/screens/sos/sos_screen.dart';
import 'package:rideon_admin/screens/rides/rides_screen.dart';
import 'package:rideon_admin/screens/bookings/bookings_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = SupabaseService.isLoggedIn;
    final loc = state.matchedLocation;
    
    if (!isLoggedIn && loc != '/login') {
      return '/login';
    }
    if (isLoggedIn && loc == '/login') {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/documents',
          builder: (context, state) => const DocumentsScreen(),
        ),
        GoRoute(
          path: '/sos',
          builder: (context, state) => const SosScreen(),
        ),
        GoRoute(
          path: '/rides',
          builder: (context, state) => const RidesScreen(),
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const BookingsScreen(),
        ),
      ],
    ),
  ],
);
