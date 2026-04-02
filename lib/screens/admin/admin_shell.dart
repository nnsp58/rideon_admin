import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if the screen is mobile or desktop
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('RideOn Admin'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      drawer: isMobile ? _buildSidebar(context) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'RideOn Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          _buildSidebarItem(context, 'Dashboard', Icons.dashboard_rounded, '/admin'),
          _buildSidebarItem(context, 'Users', Icons.people_rounded, '/admin/users'),
          _buildSidebarItem(context, 'Rides', Icons.local_taxi_rounded, '/admin/rides'),
          _buildSidebarItem(context, 'Verifications', Icons.verified_user_rounded, '/admin/documents'),
          _buildSidebarItem(context, 'SOS Alerts', Icons.emergency_rounded, '/admin/sos'),
          const Spacer(),
          const Divider(color: Colors.white24, height: 1),
          _buildSidebarItem(context, 'Logout', Icons.logout, '/logout'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title, IconData icon, String route) {
    return InkWell(
      onTap: () {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold?.hasDrawer ?? false) {
          Navigator.pop(context); // Close drawer if open
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
