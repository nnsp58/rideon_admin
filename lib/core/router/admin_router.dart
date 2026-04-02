import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_documents_screen.dart';
import '../../screens/admin/admin_sos_screen.dart';
import '../../screens/admin/admin_rides_screen.dart';

// Splash and Login for Admin
class AdminSplash extends StatelessWidget {
  const AdminSplash({super.key});
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () => context.go('/admin'));
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AdminRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _adminNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminSplash(),
      ),
      
      // Admin Panel Shell
      ShellRoute(
        navigatorKey: _adminNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/documents',
            builder: (context, state) => const AdminDocumentsScreen(),
          ),
          GoRoute(
            path: '/admin/sos',
            builder: (context, state) => const AdminSOSScreen(),
          ),
          GoRoute(
            path: '/admin/rides',
            builder: (context, state) => const AdminRidesScreen(),
          ),
        ],
      ),
    ],
  );
}
