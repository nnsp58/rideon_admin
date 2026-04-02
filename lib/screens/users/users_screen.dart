import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/models/user_model.dart';
import 'package:rideon_admin/models/booking_model.dart';
import 'package:rideon_admin/services/supabase_service.dart';
import 'package:rideon_admin/widgets/status_badge.dart';
import 'package:rideon_admin/widgets/loading_widget.dart';
import 'package:data_table_2/data_table_2.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  String _searchQuery = '';
  String _filterStatus = 'all'; // all/admin/banned/verified/pending
  bool _loading = true;
  int _page = 0;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await SupabaseService.client
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .range(_page * _pageSize, (_page + 1) * _pageSize - 1);

      if (mounted) {
        setState(() {
          _allUsers = (data as List).map((e) => UserModel.fromJson(e)).toList();
          _applyFilter();
        });
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var list = [..._allUsers];

    // Search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((u) =>
          (u.fullName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (u.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (u.phone?.contains(_searchQuery) ?? false)).toList();
    }

    // Status filter
    switch (_filterStatus) {
      case 'admin':
        list = list.where((u) => u.isAdmin).toList();
        break;
      case 'banned':
        list = list.where((u) => u.isBanned).toList();
        break;
      case 'verified':
        list = list.where((u) => u.isVerified).toList();
        break;
      case 'pending':
        list = list.where((u) => u.hasPendingDocs).toList();
        break;
    }

    setState(() => _filteredUsers = list);
  }

  String _docStatusLabel(String status) {
    switch (status) {
      case 'approved': return 'Verified';
      case 'pending': return 'Pending';
      case 'rejected': return 'Rejected';
      default: return 'Not Submitted';
    }
  }

  Color _docStatusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'rejected': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Color _docStatusBgColor(String status) {
    switch (status) {
      case 'approved': return AppColors.successLight;
      case 'pending': return AppColors.warningLight;
      case 'rejected': return AppColors.errorLight;
      default: return Colors.grey.shade100;
    }
  }

  Future<void> _toggleBan(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user.isBanned ? '${user.fullName} ko Unban Karein?' : '${user.fullName} ko Ban Karein?'),
        content: Text(user.isBanned ? 'User ab app use kar sakta hai.' : 'User app access nahi kar payega.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: user.isBanned ? null : ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(user.isBanned ? 'Unban Karo' : 'Ban Karo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.client.from('users').update({'is_banned': !user.isBanned}).eq('id', user.id);
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(user.isBanned ? 'User unban ho gaya' : 'User ban ho gaya'),
            backgroundColor: user.isBanned ? AppColors.success : AppColors.error,
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _toggleAdmin(UserModel user) async {
    final currentAdminId = SupabaseService.currentUserId;
    final isSelf = user.id == currentAdminId;

    if (isSelf) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aap khud ke rights nahi hata sakte!'),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }

    final confirm = user.isAdmin
        ? await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('${user.fullName?.isNotEmpty == true ? user.fullName! : user.email?.split('@')[0]} ke admin rights hatana chahte hain?'),
              content: const Text('Yeh user admin access nahi kar payega.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('Admin Hatao'),
                ),
              ],
            ),
          )
        : await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Kya aap ${user.fullName?.isNotEmpty == true ? user.fullName! : user.email?.split('@')[0]} ko admin banana chahte hain?'),
              content: const Text('Yeh user full admin panel access kar sakega.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('Admin Banao'),
                ),
              ],
            ),
          );

    if (confirm == true && mounted) {
      try {
        await SupabaseService.client
            .from('users')
            .update({'is_admin': !user.isAdmin})
            .eq('id', user.id);

        _loadUsers();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(user.isAdmin ? '${user.fullName?.isNotEmpty == true ? user.fullName! : user.email?.split('@')[0]} ka admin status hata diya' : '${user.fullName?.isNotEmpty == true ? user.fullName! : user.email?.split('@')[0]} ab admin hai!'),
          backgroundColor: user.isAdmin ? AppColors.error : AppColors.success,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _showUserDetail(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text((user.fullName != null && user.fullName!.isNotEmpty ? user.fullName!.substring(0, 1).toUpperCase() : '?'), style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.fullName?.isNotEmpty == true
                                      ? user.fullName!
                                      : (user.email ?? 'Admin'),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purple, width: 1.2),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(user.email ?? '', style: const TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                          Text(user.phone != null ? '+91 ${user.phone}' : 'Phone nahi', style: const TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _detailStat('Rating', '${user.rating} ★'),
                    _detailStat('Rides Diye', '${user.totalRidesGiven}'),
                    _detailStat('Rides Liye', '${user.totalRidesTaken}'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Documents: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    StatusBadge(
                      label: _docStatusLabel(user.docVerificationStatus),
                      color: _docStatusColor(user.docVerificationStatus),
                      bgColor: _docStatusBgColor(user.docVerificationStatus),
                    ),
                  ],
                ),
                if (user.vehicleModel != null) ...[
                  const SizedBox(height: 8),
                  Text('Vehicle: ${user.vehicleModel} (${user.vehicleColor ?? ''}) • ${user.vehicleType ?? ''}'),
                ],
                const SizedBox(height: 16),
                const Text('Recent Bookings (last 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: SupabaseService.client.from('bookings').select().eq('passenger_id', user.id).order('booked_at', ascending: false).limit(5),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
                    if (!snap.hasData || (snap.data as List).isEmpty) return const Text('Koi booking nahi', style: TextStyle(color: AppColors.textSecondary));
                    final bookings = (snap.data as List).map((e) => BookingModel.fromJson(e)).toList();
                    return Column(
                      children: bookings.map((b) => ListTile(
                        dense: true,
                        title: Text('${b.passengerName} (Seats: ${b.seatsBooked})'),
                        subtitle: Text(b.formattedTotal),
                        trailing: StatusBadge(
                          label: b.status.toUpperCase(),
                          color: b.status == 'cancelled' ? AppColors.error : AppColors.success,
                          bgColor: b.status == 'cancelled' ? AppColors.errorLight : AppColors.successLight,
                        ),
                      )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (user.isAdmin)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.remove_circle, size: 16),
                        label: const Text('Admin Hatao'),
                        onPressed: () => _toggleAdmin(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.admin_panel_settings, size: 16),
                        label: const Text('Admin Banao'),
                        onPressed: () => _toggleAdmin(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
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
          // ─── TOP BAR (search + filter) ───
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Naam, email ya phone se search...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { setState(() => _searchQuery = ''); _applyFilter(); }) : null,
                  ),
                  onChanged: (v) { setState(() => _searchQuery = v); _applyFilter(); },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                      DropdownMenuItem(value: 'banned', child: Text('Banned')),
                      DropdownMenuItem(value: 'verified', child: Text('Verified Drivers')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending Docs')),
                    ],
                    onChanged: (v) { setState(() => _filterStatus = v!); _applyFilter(); },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${_filteredUsers.length} users', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
            ],
          ),
          const SizedBox(height: 24),
          // ─── DATA TABLE ───
          Expanded(
            child: Card(
              child: _loading
                  ? const Center(child: LoadingWidget())
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, color: Colors.grey, size: 48),
                              const SizedBox(height: 12),
                              const Text('Koi user nahi mila', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 800, // Reduced from 900
                            child: DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 8,
                              minWidth: 600,
                              columns: [
                                DataColumn2(label: Text('User'), size: ColumnSize.L),
                                DataColumn2(label: Text('Contact'), size: ColumnSize.M),
                                DataColumn2(label: Text('Rides'), fixedWidth: 60),
                                DataColumn2(label: Text('Status'), size: ColumnSize.M),
                                DataColumn2(label: Text('Join Date'), fixedWidth: isMobile ? 80 : 100),
                                DataColumn2(label: Text('Actions'), fixedWidth: isMobile ? 150 : 160),
                              ],
                              rows: _filteredUsers.map((user) => DataRow(cells: [
                                DataCell(Row(children: [
                              CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withOpacity(0.1), child: Text((user.fullName != null && user.fullName!.isNotEmpty ? user.fullName!.substring(0, 1).toUpperCase() : '?'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text(
                                    user.fullName?.isNotEmpty == true
                                        ? user.fullName!
                                        : (user.email?.split('@')[0] ?? 'Admin'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(user.email ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                ]),
                              ),
                            ])),
                            DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(user.phone != null ? '+91 ${user.phone}' : '-', style: const TextStyle(fontSize: 12)),
                              if (user.vehicleModel != null) Text(user.vehicleModel!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                            ])),
                            DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('${user.totalRidesGiven} up', style: const TextStyle(fontSize: 12)),
                              Text('${user.totalRidesTaken} down', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ])),
                            DataCell(Wrap(spacing: 4, runSpacing: 4, children: [
                              if (user.isAdmin) StatusBadge.admin(),
                              if (user.isBanned) StatusBadge.banned(),
                              StatusBadge(
                                label: _docStatusLabel(user.docVerificationStatus),
                                color: _docStatusColor(user.docVerificationStatus),
                                bgColor: _docStatusBgColor(user.docVerificationStatus),
                              ),
                            ])),
                            DataCell(Text(user.createdAt != null ? DateFormat('dd MMM yy').format(user.createdAt!) : '-', style: const TextStyle(fontSize: 12))),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.visibility, color: AppColors.primary, size: 14), tooltip: 'Details', onPressed: () => _showUserDetail(context, user), padding: EdgeInsets.all(isMobile ? 2 : 4), constraints: const BoxConstraints()),
                                IconButton(icon: Icon(user.isBanned ? Icons.lock_open : Icons.block, color: user.isBanned ? AppColors.success : AppColors.error, size: 14), tooltip: user.isBanned ? 'Unban' : 'Ban', onPressed: () => _toggleBan(user), padding: EdgeInsets.all(isMobile ? 2 : 4), constraints: const BoxConstraints()),
                                IconButton(icon: Icon(user.isAdmin ? Icons.admin_panel_settings : Icons.person_add, color: user.isAdmin ? AppColors.primary : AppColors.textSecondary, size: 14), tooltip: user.isAdmin ? 'No Admin' : 'Make Admin', onPressed: () => _toggleAdmin(user), padding: EdgeInsets.all(isMobile ? 2 : 4), constraints: const BoxConstraints()),
                              ],
                            )),
                            ])).toList(),
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
