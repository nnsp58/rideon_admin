import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/models/ride_model.dart';
import 'package:rideon_admin/models/booking_model.dart';
import 'package:rideon_admin/services/supabase_service.dart';
import 'package:rideon_admin/services/notification_service.dart';
import 'package:rideon_admin/widgets/status_badge.dart';
import 'package:rideon_admin/widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

extension StringExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : this;
}

class _RidesScreenState extends State<RidesScreen> {
  List<RideModel> _rides = [];
  String _statusFilter = 'all';
  String _searchQuery = '';
  bool _loading = true;
  DateTimeRange? _dateRange;
  static const _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    if (mounted) setState(() => _loading = true);
    try {
      var query = SupabaseService.client.from('rides').select();

      if (_statusFilter != 'all') {
        query = query.eq('status', _statusFilter);
      }

      if (_dateRange != null) {
        query = query
            .gte('departure_datetime', _dateRange!.start.toIso8601String())
            .lte('departure_datetime', _dateRange!.end.toIso8601String());
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or(
            'from_location.ilike.%$_searchQuery%,to_location.ilike.%$_searchQuery%,driver_name.ilike.%$_searchQuery%');
      }

      final data = await query
          .order('departure_datetime', ascending: false)
          .limit(_pageSize);

      if (mounted) {
        final allRides = (data as List).map((e) => RideModel.fromJson(e)).toList();
        _rides = _filterExpiredRides(allRides);
        setState(() => _loading = false);
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RideModel> _filterExpiredRides(List<RideModel> rides) {
    final now = DateTime.now().toUtc();
    return rides.where((ride) {
      final hoursSince = now.difference(ride.departureDatetime.toUtc()).inHours;
      // Hide active/scheduled/full rides older than 2 hours from admin view
      if (hoursSince > 2 &&
          (ride.status == 'active' || ride.status == 'scheduled' || ride.status == 'full')) {
        return false;
      }
      return true;
    }).toList();
  }



  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _loadRides();
    }
  }

  void _showLocationOnMap(Map<String, dynamic> rideData) {
    if (rideData['current_lat'] != null && rideData['current_lng'] != null) {
      final lat = rideData['current_lat'];
      final lng = rideData['current_lng'];
      final url = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=15';
      launchUrl(Uri.parse(url));
    }
  }

  void _showRideDetail(BuildContext context, RideModel ride) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: FutureBuilder(
                future: Future.wait([
                  SupabaseService.client.from('bookings').select().eq('ride_id', ride.id).order('booked_at', ascending: true),
                  SupabaseService.client.from('users').select().eq('id', ride.driverId).maybeSingle(),
                  SupabaseService.client.from('rides').select().eq('id', ride.id).maybeSingle(), // get current loc
                ]),
                builder: (ctx, AsyncSnapshot<List<dynamic>> snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final bookingsData = snap.data?[0] as List? ?? [];
                  final driverData = snap.data?[1] as Map<String, dynamic>?;
                  final rideData = snap.data?[2] as Map<String, dynamic>?;
                  
                  final bookings = bookingsData.map((e) => BookingModel.fromJson(e)).toList();

                  return ListView(
                    controller: controller,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ride Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // ─── SECTION 1: RIDE INFO ───
                      const Text('1. Ride Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: AppColors.background,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${ride.fromLocation} → ${ride.toLocation}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('${ride.formattedDate} • ${ride.status.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w600, color: ride.statusColor)),
                              const SizedBox(height: 4),
                              Text('Seats: ${ride.bookedSeats} booked / ${ride.availableSeats} available / ${ride.totalSeats} total'),
                              const SizedBox(height: 4),
                              Text('Fare: ${ride.formattedPrice} per seat'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ─── SECTION 2: DRIVER INFO ───
                      const Text('2. Driver Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: AppColors.background,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${driverData?['full_name'] ?? ride.driverName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (driverData?['phone'] != null) Text('Phone: +91 ${driverData!['phone']}'),
                              if (driverData?['email'] != null) Text('Email: ${driverData!['email']}'),
                              if (ride.vehicleInfo != null) Text('Vehicle: ${ride.vehicleInfo}'),
                              const SizedBox(height: 4),
                              if (driverData != null)
                                Row(
                                  children: [
                                    const Text('Docs Status: '),
                                    StatusBadge(label: (driverData['doc_verification_status'] ?? 'pending').toUpperCase(), color: AppColors.primary, bgColor: AppColors.primaryLight),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── SECTION 4: LOCATION (IF ACTIVE) ───
                      if (ride.status == 'active' && rideData != null && rideData['current_lat'] != null) ...[
                        const Text('3. Live Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          color: AppColors.background,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Lat: ${rideData['current_lat']}, Lng: ${rideData['current_lng']}')),
                                ElevatedButton.icon(
                                  onPressed: () => _showLocationOnMap(rideData),
                                  icon: const Icon(Icons.map, size: 16),
                                  label: const Text('OpenStreetMap mein dekho'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('4. Passengers List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ] else ...[
                        const Text('3. Passengers List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],

                      // ─── SECTION 3: PASSENGERS LIST ───
                      const SizedBox(height: 12),
                      if (bookings.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text('Abhi koi passenger nahi', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookings.length,
                          itemBuilder: (ctx, i) {
                            final b = bookings[i];
                            return Card(
                              elevation: 0,
                              color: AppColors.background,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(b.passengerName.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(b.passengerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (b.passengerPhone != null) Text('+91 ${b.passengerPhone}'),
                                    Text('Seats Booked: ${b.seatsBooked} • ${b.formattedTotal}'),
                                    Text('Booked At: ${DateFormat('dd MMM hh:mm a').format(b.bookedAt)}'),
                                  ],
                                ),
                                trailing: StatusBadge(
                                  label: b.status.toUpperCase(),
                                  color: b.status == 'confirmed' ? AppColors.success : AppColors.error,
                                  bgColor: b.status == 'confirmed' ? AppColors.successLight : AppColors.errorLight,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _forceCancel(RideModel ride) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ride Force Cancel Karein?'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${ride.fromLocation} → ${ride.toLocation}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(ride.formattedDate, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '⚠️ Sabhi ${ride.totalSeats - ride.availableSeats} passengers ko cancel notification jaayegi.',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Force Cancel Karo'),
          ),
        ],
      ),
    );
  
    if (confirm == true) {
      try {
        await SupabaseService.client.from('rides').update({'status': 'cancelled'}).eq('id', ride.id);
        
        final bookingsRes = await SupabaseService.client
            .from('bookings')
            .select('id, passenger_id, passenger_name')
            .eq('ride_id', ride.id)
            .eq('status', 'confirmed');
        
        final bookings = bookingsRes as List;
        
        await SupabaseService.client.from('bookings')
            .update({
              'status': 'cancelled',
              'cancelled_at': DateTime.now().toIso8601String()
            })
            .eq('ride_id', ride.id)
            .eq('status', 'confirmed');
        
        for (final b in bookings) {
          await NotificationService().notify(
            userId: b['passenger_id'],
            title: 'Ride Cancel Ho Gayi',
            message: 'Admin ne tumhari ride (${ride.fromLocation} → ${ride.toLocation}) cancel ki hai.',
            type: 'ride_cancelled',
            rideId: ride.id,
          );
        }
        
        _loadRides();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Ride cancel ho gayi, ${bookings.length} passengers notify kiye'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: Column(
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
          // ─── FILTERS BAR ───
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Route ya driver name...', prefixIcon: Icon(Icons.search, size: 18)),
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadRides();
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8), color: Colors.white),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'full', child: Text('Full')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v!);
                      _loadRides();
                    },
                  ),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(_dateRange != null ? '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}' : 'Date Range'),
                onPressed: _pickDateRange,
              ),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: 'Date filter hatao',
                  onPressed: () {
                    setState(() => _dateRange = null);
                    _loadRides();
                  },
                ),
              const SizedBox(width: 8),
              Text('${_rides.length} rides', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRides),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: _loading
                ? const Center(child: LoadingWidget())
                : _rides.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_outlined, color: Colors.grey, size: 48),
                            const SizedBox(height: 12),
                            const Text('Koi ride nahi mili', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _rides.length,
                        itemBuilder: (context, index) {
                          final ride = _rides[index];
                          final driverInitial = ride.driverName.isNotEmpty ? ride.driverName[0].toUpperCase() : '?';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        child: Text(driverInitial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${ride.fromLocation} → ${ride.toLocation}',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Driver: ${ride.driverName}', style: const TextStyle(fontSize: 13)),
                                            Text(ride.formattedDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            Text('Seats: ${ride.bookedSeats}/${ride.totalSeats} booked • ${ride.formattedPrice} per seat', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ride.statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          ride.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: ride.statusColor,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _showRideDetail(context, ride),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryLight,
                                              foregroundColor: AppColors.primary,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            child: const Text('Dekho'),
                                          ),
                                          if (ride.status == 'active' || ride.status == 'full') ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.cancel, color: AppColors.error),
                                              tooltip: 'Force Cancel',
                                              onPressed: () => _forceCancel(ride),
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
