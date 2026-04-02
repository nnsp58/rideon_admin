import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/services/supabase_service.dart';
import 'package:rideon_admin/widgets/stat_card.dart';
import 'package:rideon_admin/widgets/loading_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _loadingStats = true;
  bool _loadingActivity = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshAll();
    // Auto-refresh har 60 second
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshAll());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadStats(),
      _loadActivity(),
    ]);
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _loadingStats = true);
    try {
      final client = SupabaseService.client;
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

      final results = await Future.wait([
        client.from('users').count(CountOption.exact),
        client.from('rides').count(CountOption.exact).eq('status', 'active').gte('departure_datetime', todayStart.toIso8601String()),
        client.from('sos_alerts').count(CountOption.exact).eq('is_active', true),
        client.from('users').count(CountOption.exact).eq('doc_verification_status', 'pending'),
        client.from('bookings').count(CountOption.exact).gte('booked_at', todayStart.toIso8601String()),
      ]);

      if (mounted) {
        setState(() => _stats = {
          'users': results[0],
          'activeRides': results[1],
          'activeSos': results[2],
          'pendingDocs': results[3],
          'bookingsToday': results[4],
        });
      }
    } catch (e) {
      debugPrint('Stats load error: $e');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadActivity() async {
    if (mounted) setState(() => _loadingActivity = true);
    try {
      final client = SupabaseService.client;
      final results = await Future.wait([
        client.from('bookings').select('id, passenger_name, booked_at').order('booked_at', ascending: false).limit(5),
        client.from('rides').select('id, driver_name, created_at').order('created_at', ascending: false).limit(5),
        client.from('sos_alerts').select('id, user_name, created_at').order('created_at', ascending: false).limit(5),
        client.from('users').select('id, full_name, created_at').order('created_at', ascending: false).limit(5),
      ]);
      
      final List<Map<String, dynamic>> activities = [];
      
      for (var b in results[0]) {
        activities.add({
          'type': 'booking',
          'title': '${b['passenger_name'] ?? 'Kisi'} ne nayi ride book ki',
          'message': 'Nayi booking aayi',
          'created_at': b['booked_at'],
        });
      }
      for (var r in results[1]) {
        activities.add({
          'type': 'ride',
          'title': '${r['driver_name'] ?? 'Koi driver'} ne nayi ride add ki',
          'message': 'Nayi ride publish hui',
          'created_at': r['created_at'],
        });
      }
      for (var s in results[2]) {
        activities.add({
          'type': 'sos_alert',
          'title': '${s['user_name'] ?? 'Kisi'} ne SOS bheja!',
          'message': 'Emergency alert generate hua',
          'created_at': s['created_at'],
        });
      }
      for (var u in results[3]) {
        if (u['created_at'] != null) {
          activities.add({
            'type': 'user',
            'title': '${u['full_name'] ?? 'Naye user'} ne account banaya',
            'message': 'Naya user app mein aya',
            'created_at': u['created_at'],
          });
        }
      }
      
      activities.sort((a, b) {
        try {
          return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']));
        } catch (_) {
          return 0;
        }
      });
      
      if (mounted) {
        setState(() => _recentActivity = activities.take(10).toList());
      }
    } catch (e) {
      debugPrint('Activity error: $e');
    } finally {
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'booking': return Icons.book;
      case 'ride': return Icons.directions_car;
      case 'sos_alert': return Icons.warning;
      case 'user': return Icons.person;
      default: return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'sos_alert': return AppColors.error;
      case 'booking': return AppColors.success;
      case 'ride': return AppColors.primary;
      case 'user': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
    if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
    return DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── STATS CARDS ───
              if (_loadingStats && _stats.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: LoadingWidget()))
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardData = [
                      {
                        'title': 'Total Users',
                        'value': '${_stats['users'] ?? 0}',
                        'icon': Icons.people_rounded,
                        'color': AppColors.primary,
                        'route': '/users',
                      },
                      {
                        'title': 'Active Rides (Aaj)',
                        'value': '${_stats['activeRides'] ?? 0}',
                        'icon': Icons.directions_car_rounded,
                        'color': AppColors.success,
                        'route': '/rides',
                      },
                      {
                        'title': 'Active SOS Alerts',
                        'value': '${_stats['activeSos'] ?? 0}',
                        'icon': Icons.warning_rounded,
                        'color': (_stats['activeSos'] ?? 0) > 0 ? AppColors.error : AppColors.success,
                        'route': '/sos',
                      },
                      {
                        'title': 'Pending Verifications',
                        'value': '${_stats['pendingDocs'] ?? 0}',
                        'icon': Icons.description_rounded,
                        'color': AppColors.warning,
                        'route': '/documents',
                      },
                      {
                        'title': 'Bookings (Aaj)',
                        'value': '${_stats['bookingsToday'] ?? 0}',
                        'icon': Icons.event_seat_rounded,
                        'color': AppColors.info,
                        'route': null,
                      },
                    ];

                    if (constraints.maxWidth < 600) {
                      // MOBILE: Use Wrap instead of GridView to avoid aspect ratio overflows
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: cardData.map((card) {
                          return SizedBox(
                            width: (constraints.maxWidth - 12 - 24) / 2, // Exactly 2 columns
                            child: StatCard(
                              title: card['title'] as String,
                              value: card['value'] as String,
                              icon: card['icon'] as IconData,
                              color: card['color'] as Color,
                              onTap: card['route'] != null ? () => context.go(card['route'] as String) : null,
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      // DESKTOP: GridView is fine
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: cardData.length,
                        itemBuilder: (ctx, i) {
                          final card = cardData[i];
                          return StatCard(
                            title: card['title'] as String,
                            value: card['value'] as String,
                            icon: card['icon'] as IconData,
                            color: card['color'] as Color,
                            onTap: card['route'] != null ? () => context.go(card['route'] as String) : null,
                          );
                        },
                      );
                    }
                  },
                ),
            
              const SizedBox(height: 28),
              
              // ─── RECENT ACTIVITY ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    onPressed: _loadActivity,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Card(
                child: _loadingActivity
                    ? const Padding(padding: EdgeInsets.all(32), child: Center(child: LoadingWidget()))
                    : _recentActivity.isEmpty
                        ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Koi activity nahi', style: TextStyle(color: AppColors.textSecondary))))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentActivity.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                            itemBuilder: (ctx, i) {
                              final item = _recentActivity[i];
                              final type = item['type'] as String? ?? '';
                              final createdAt = DateTime.parse(item['created_at']);
                              
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _typeColor(type).withOpacity(0.12),
                                  child: Icon(_typeIcon(type), color: _typeColor(type), size: 16),
                                ),
                                title: Text(item['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: Text(item['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Text(
                                  _formatRelative(createdAt),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              );
                            },
                          ),
              ),
              
              const SizedBox(height: 28),
              
              // ─── QUICK ACTIONS ───
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                      iconSize: 16,
                    ),
                    icon: const Icon(Icons.description),
                    label: const Text('Pending Documents Dekho'),
                    onPressed: () => context.go('/documents'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                      iconSize: 16,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.warning, color: AppColors.error),
                    label: const Text('SOS Monitor Karo', style: TextStyle(color: AppColors.error)),
                    onPressed: () => context.go('/sos'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                      iconSize: 16,
                    ),
                    icon: const Icon(Icons.people),
                    label: const Text('Users Manage Karo'),
                    onPressed: () => context.go('/users'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
