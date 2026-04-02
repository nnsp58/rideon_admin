import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/models/user_model.dart';
import 'package:rideon_admin/services/auth_service.dart';
import 'package:rideon_admin/services/supabase_service.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? _currentAdmin;
  bool _loadingAdmin = true;
  int _activeSosCount = 0;
  StreamSubscription? _sosSubscription;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
    _subscribeToSos();
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAdmin() async {
    setState(() => _loadingAdmin = true);
    final admin = await AuthService().getCurrentAdmin();
    if (admin == null && mounted) {
      context.go('/login');
      return;
    }
    if (mounted) {
      setState(() {
        _currentAdmin = admin;
        _loadingAdmin = false;
      });
    }
  }

  void _subscribeToSos() {
    _sosSubscription = SupabaseService.client
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .listen(
      (data) {
        if (mounted) {
          setState(() => _activeSosCount = data.length);
        }
      },
      onError: (err) {
        debugPrint('SOS Stream error: $err');
        // Handle network timeout or server being unreachable
      },
      cancelOnError: false,
    );
  }

  String _getPageTitle(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/dashboard')) return 'Dashboard';
    if (loc.startsWith('/users')) return 'User Management';
    if (loc.startsWith('/documents')) return 'Document Verification';
    if (loc.startsWith('/sos')) return 'SOS Alerts';
    if (loc.startsWith('/rides')) return 'Ride Management';
    if (loc.startsWith('/bookings')) return 'Bookings';
    return 'Admin Panel';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout Karein?'),
        content: const Text('Kya aap admin panel se logout karna chahte hain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _showAddAdminDialog() async {
    final emailCtrl = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, setState) {
            return AlertDialog(
              title: const Text('Naya Admin Add Karein'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pehle us user ko RideOn app me register hona zaroori hai. Unka registered email yahan daalein unhe Admin rights dene ke liye:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Registered User Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty) return;
                          
                          setState(() => isLoading = true);
                          
                          try {
                            final data = await SupabaseService.client
                                .from('users')
                                .select()
                                .eq('email', email)
                                .maybeSingle();
                                
                            if (data == null) {
                              if (stCtx.mounted) {
                                ScaffoldMessenger.of(stCtx).showSnackBar(const SnackBar(
                                  content: Text('Yeh email registered nahi hai! Pehle app me signup karwayein.'),
                                  backgroundColor: AppColors.error,
                                ));
                              }
                            } else {
                              if (data['is_admin'] == true) {
                                if (stCtx.mounted) {
                                  ScaffoldMessenger.of(stCtx).showSnackBar(const SnackBar(
                                    content: Text('Yeh user pehle se hi admin hai!'),
                                    backgroundColor: AppColors.warning,
                                  ));
                                }
                              } else {
                                await SupabaseService.client
                                    .from('users')
                                    .update({'is_admin': true})
                                    .eq('id', data['id']);
                                    
                                if (stCtx.mounted) {
                                  ScaffoldMessenger.of(stCtx).showSnackBar(const SnackBar(
                                    content: Text('User ko successfully Admin bana diya gaya hai! 🎉'),
                                    backgroundColor: AppColors.success,
                                  ));
                                  Navigator.pop(ctx);
                                }
                              }
                            }
                          } catch (e) {
                            if (stCtx.mounted) {
                               ScaffoldMessenger.of(stCtx).showSnackBar(SnackBar(
                                 content: Text('Error: $e'),
                                 backgroundColor: AppColors.error,
                               ));
                            }
                          } finally {
                            if (stCtx.mounted) setState(() => isLoading = false);
                          }
                        },
                  child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Make Admin'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAdmin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isMobile
          ? Drawer(
              width: 220,
              backgroundColor: AppColors.sidebarBg,
              child: _buildSidebarContent(context),
            )
          : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                _getPageTitle(context),
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Badge(
                    isLabelVisible: _activeSosCount > 0,
                    label: Text('$_activeSosCount'),
                    child: const Icon(Icons.notifications_outlined, color: Colors.black54),
                  ),
                  onPressed: () => context.go('/sos'),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
                  onPressed: _showAddAdminDialog,
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: Row(
        children: [
          // ─── DESKTOP SIDEBAR ───
          if (!isMobile)
            Container(
              width: _isCollapsed ? 64 : 220,
              color: AppColors.sidebarBg,
              child: _buildSidebarContent(context),
            ),

          // ─── MAIN CONTENT ───
          Expanded(
            child: Column(
              children: [
                // Top bar (Only show title on Desktop)
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getPageTitle(context),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        // Notification Icon
                        IconButton(
                          icon: Badge(
                            isLabelVisible: _activeSosCount > 0,
                            label: Text('$_activeSosCount'),
                            child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                          ),
                          onPressed: () => context.go('/sos'),
                          tooltip: 'Notifications & Alerts',
                        ),
                        const SizedBox(width: 4),
                        // Add Admin Icon
                        IconButton(
                          icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
                          onPressed: _showAddAdminDialog,
                          tooltip: 'Naya Admin Add Karein',
                        ),
                        const SizedBox(width: 16),
                        // Current admin name
                        Flexible(
                          child: Text(
                            'Namaste, ${_currentAdmin?.fullName?.split(' ').first ?? 'Admin'}',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;
    final effectiveCollapsed = isMobile ? false : _isCollapsed;

    return Column(
      children: [
        // Top: Logo + collapse button
        Container(
          padding: EdgeInsets.symmetric(horizontal: effectiveCollapsed ? 12 : 20, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
              ),
              if (!effectiveCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RideOn Admin',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Control Panel',
                        style: TextStyle(color: AppColors.sidebarText, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  IconButton(
                    icon: const Icon(Icons.menu, size: 18, color: Colors.white),
                    onPressed: () => setState(() => _isCollapsed = true),
                    tooltip: 'Collapse sidebar',
                  ),
              ] else
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
                    onPressed: () => setState(() => _isCollapsed = false),
                    tooltip: 'Expand sidebar',
                  ),
                ),
            ],
          ),
        ),

        Divider(color: Colors.white.withOpacity(0.1), height: 1),

        const SizedBox(height: 8),

        // Nav items
        _navItem(context, Icons.dashboard_rounded, 'Dashboard', '/dashboard', isMobile: isMobile),
        _navItem(context, Icons.people_rounded, 'Users', '/users', isMobile: isMobile),
        _navItem(context, Icons.description_rounded, 'Documents', '/documents', isMobile: isMobile),
        _navItem(context, Icons.warning_rounded, 'SOS Alerts', '/sos', isMobile: isMobile, badgeCount: _activeSosCount),
        _navItem(context, Icons.directions_car_rounded, 'Rides', '/rides', isMobile: isMobile),
        _navItem(context, Icons.book_online_rounded, 'Bookings', '/bookings', isMobile: isMobile),

        const Spacer(),

        Divider(color: Colors.white.withOpacity(0.1), height: 1),

        // Bottom: Admin profile + logout
        Padding(
          padding: EdgeInsets.symmetric(horizontal: effectiveCollapsed ? 8 : 16, vertical: 16),
          child: Row(
            mainAxisAlignment: effectiveCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  _currentAdmin?.fullName?.substring(0, 1).toUpperCase() ?? 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (!effectiveCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentAdmin?.fullName ?? 'Admin',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _currentAdmin?.email ?? '',
                        style: const TextStyle(color: AppColors.sidebarText, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.sidebarText, size: 20),
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route, {int badgeCount = 0, required bool isMobile}) {
    final location = GoRouterState.of(context).matchedLocation;
    final isActive = location.startsWith(route);

    return InkWell(
      onTap: () {
        if (isMobile) {
          Navigator.pop(context); // Close drawer on mobile
        }
        if (_isCollapsed && !isMobile && mounted) {
          setState(() {
            _isCollapsed = false;
          });
        }
        context.go(route);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: (isMobile || !_isCollapsed) ? 12 : 8, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: (isMobile || !_isCollapsed) ? 12 : 0, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: (isMobile || !_isCollapsed) ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : AppColors.sidebarText, size: 20),
            if (isMobile || !_isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.sidebarText,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            if ((isMobile || !_isCollapsed) && badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
