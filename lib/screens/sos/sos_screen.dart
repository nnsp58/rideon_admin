import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/models/sos_alert_model.dart';
import 'package:rideon_admin/services/supabase_service.dart';
import 'package:rideon_admin/widgets/loading_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  List<SosAlertModel> _activeAlerts = [];
  List<SosAlertModel> _resolvedAlerts = [];
  StreamSubscription? _subscription;
  Timer? _refreshTimer;
  final Map<String, bool> _resolvingIds = {};

  @override
  void initState() {
    super.initState();
    _subscribeToAlerts();
    _loadResolved();
    // Elapsed time auto-update
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _subscribeToAlerts() {
    _subscription = SupabaseService.client
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .listen((data) {
          if (mounted) {
            setState(() => _activeAlerts = data.map((e) => SosAlertModel.fromJson(e)).toList());
          }
        });
  }

  Future<void> _loadResolved() async {
    try {
      final data = await SupabaseService.client
          .from('sos_alerts')
          .select()
          .eq('is_active', false)
          .order('resolved_at', ascending: false)
          .limit(20);
      if (mounted) {
        setState(() => _resolvedAlerts = (data as List).map((e) => SosAlertModel.fromJson(e)).toList());
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _resolve(String alertId) async {
    setState(() => _resolvingIds[alertId] = true);
    try {
      print('Attempting to resolve SOS alert ID: $alertId');
      
      final response = await SupabaseService.client
          .from('sos_alerts')
          .update({
            'is_active': false,
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId)
          .select();
      
      if (response.isNotEmpty) {
        print('SOS Resolve Success!');
        _handleResolveSuccess(alertId);
      } else {
        print('SOS Resolve: Empty response (check RLS or ID)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Alert resolve nahi hua — check database!'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      print('SOS Resolve Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _resolvingIds.remove(alertId));
      }
    }
  }

  void _handleResolveSuccess(String alertId) async {
    // Remove immediately from active alerts list
    setState(() {
      _activeAlerts.removeWhere((a) => a.id == alertId);
    });
    // Also reload resolved alerts list
    await _loadResolved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('SOS resolve ho gaya!'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Widget _buildActiveAlertCard(SosAlertModel alert) {
    final isResolving = _resolvingIds[alert.id] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.sosLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sosRed, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
              // Header row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emergency icon + type
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.sosRed, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.warning, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.userName, style: const TextStyle(color: AppColors.sosRed, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          alert.emergencyLabel,
                          style: TextStyle(color: AppColors.sosRed.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.sosRed, borderRadius: BorderRadius.circular(12)),
                      child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(alert.timeElapsed, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Location row
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.locationName ?? '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // ─── MINI MAP ───
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(alert.latitude, alert.longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rideon.admin',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(alert.latitude, alert.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: AppColors.sosRed, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            
            // Action buttons row
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // OSM link
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(alert.mapUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('OpenStreetMap mein dekho'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                
                // Resolve button
                ElevatedButton.icon(
                  onPressed: isResolving ? null : () => _resolve(alert.id),
                  icon: isResolving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle, size: 16),
                  label: Text(isResolving ? 'Resolving...' : 'Resolve Karo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () => context.go('/dashboard'),
                  tooltip: 'Dashboard pe wapas jao',
                ),
                const SizedBox(width: 8),
              ],
            ),
            // ─── ACTIVE ALERTS SECTION ───
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  children: [
                    if (_activeAlerts.isNotEmpty)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8, top: 8),
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      ),
                    Text(
                      'Active SOS Alerts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _activeAlerts.isNotEmpty ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    if (_activeAlerts.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_activeAlerts.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const Text('Auto-refresh: haan (realtime)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Active alerts list
            if (_activeAlerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Koi active SOS alert nahi. Sab theek hai ✅',
                        style: TextStyle(color: AppColors.success, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(children: _activeAlerts.map((alert) => _buildActiveAlertCard(alert)).toList()),
            
            const SizedBox(height: 28),
            
            // ─── RESOLVED HISTORY ───
            const Text('Resolved Alerts (last 20)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (_resolvedAlerts.isEmpty)
              Container(padding: const EdgeInsets.all(20), child: const Center(child: Text('Koi resolved alert nahi', style: TextStyle(color: AppColors.textSecondary))))
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _resolvedAlerts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (ctx, i) {
                    final alert = _resolvedAlerts[i];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      ),
                      title: Text(alert.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Row(
                        children: [
                          Text(alert.emergencyLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          if (alert.locationName != null) Expanded(child: Text(' • ${alert.locationName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Alert: ${DateFormat('dd MMM hh:mm a').format(alert.createdAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          if (alert.resolvedAt != null) Text('Resolved: ${DateFormat('dd MMM hh:mm a').format(alert.resolvedAt!)}', style: const TextStyle(fontSize: 11, color: AppColors.success)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
