import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/services/supabase_service.dart';
import 'package:rideon_admin/widgets/status_badge.dart';
import 'package:rideon_admin/widgets/loading_widget.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

extension StringExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : this;
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  String _statusFilter = 'all';
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (mounted) setState(() => _loading = true);
    try {
      var query = SupabaseService.client
          .from('bookings')
          .select('''
            *,
            ride:rides(
              from_location,
              to_location,
              departure_datetime,
              price_per_seat
            ),
            passenger:users!bookings_passenger_id_fkey(
              full_name,
              phone,
              email
            )
          ''');

      if (_statusFilter != 'all') {
        query = query.eq('status', _statusFilter);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('passenger_name', '%$_searchQuery%');
      }

      final data = await query.order('created_at', ascending: false).limit(100);

      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading bookings: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => context.go('/dashboard'),
                tooltip: 'Dashboard pe wapas jao',
              ),
              const Expanded(
                child: Text(
                  'Bookings Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ─── FILTERS BAR ───
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Passenger name search...', prefixIcon: Icon(Icons.search, size: 18)),
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadBookings();
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
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _statusFilter = v);
                        _loadBookings();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${_bookings.length} bookings', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Card(
              child: _loading
                  ? const Center(child: LoadingWidget())
                  : _bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_seat_outlined, color: Colors.grey, size: 48),
                              const SizedBox(height: 12),
                              const Text('Koi booking nahi mili', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                            ],
                          ),
                        )
                      : DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 1000,
                          columns: const [
                            DataColumn2(label: Text('Passenger'), size: ColumnSize.L),
                            DataColumn2(label: Text('Route'), size: ColumnSize.L),
                            DataColumn2(label: Text('Ride Date'), size: ColumnSize.M),
                            DataColumn2(label: Text('Seats'), fixedWidth: 80),
                            DataColumn2(label: Text('Status'), fixedWidth: 100),
                            DataColumn2(label: Text('Booking Time'), size: ColumnSize.M),
                          ],
                          rows: _bookings.map((b) {
                            final status = b['status'] as String? ?? 'unknown';
                            final ride = b['ride'] as Map<String, dynamic>?;
                            final origin = ride?['from_location']?.toString() ?? 'Route nahi mila';
                            final destination = ride?['to_location']?.toString() ?? '';
                            final route = '$origin → $destination';
                            final rideDate = ride != null && ride['departure_datetime'] != null
                                ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(ride['departure_datetime'].toString()))
                                : 'N/A';
                            final bookedAt = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(b['booked_at']));
                            
                            Color statusColor = AppColors.textSecondary;
                            if (status == 'confirmed') statusColor = AppColors.success;
                            if (status == 'cancelled') statusColor = AppColors.error;
                            
                            final passenger = b['passenger'] as Map<String, dynamic>?;

                            return DataRow(
                              cells: [
                                DataCell(Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(passenger?['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    if (passenger?['phone'] != null) Text('+91 ${passenger?['phone']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                )),
                                DataCell(Text(route, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                DataCell(Text(rideDate, style: const TextStyle(fontSize: 12))),
                                DataCell(Text('${b['seats_booked']} seats', style: const TextStyle(fontSize: 12))),
                                DataCell(StatusBadge(label: status.toUpperCase(), color: statusColor, bgColor: statusColor.withValues(alpha: 0.1))),
                                DataCell(Text(bookedAt, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                              ],
                            );
                          }).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
