import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';
import 'package:rideon_admin/models/user_model.dart';
import 'package:rideon_admin/services/supabase_service.dart';
import 'package:rideon_admin/services/notification_service.dart';
import 'package:rideon_admin/widgets/status_badge.dart';
import 'package:rideon_admin/widgets/doc_image_viewer.dart';
import 'package:rideon_admin/widgets/loading_widget.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  int _selectedTab = 0; // 0=pending, 1=approved, 2=rejected
  List<UserModel> _users = [];
  bool _loading = true;
  final Map<String, bool> _processingIds = {}; // approve/reject in progress

  final _tabs = ['Pending', 'Approved', 'Rejected'];
  final _statuses = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (mounted) setState(() => _loading = true);
    try {
      final status = _statuses[_selectedTab];
      final data = await SupabaseService.client
          .from('users')
          .select()
          .eq('doc_verification_status', status)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _users = (data as List).map((e) => UserModel.fromJson(e)).toList());
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yy • hh:mm a').format(dt);
  }

  Future<void> _approve(UserModel user) async {
    setState(() => _processingIds[user.id] = true);
    try {
      await SupabaseService.client.from('users').update({
        'doc_verification_status': 'approved',
        'doc_reviewed_at': DateTime.now().toIso8601String(),
        'doc_reviewed_by': SupabaseService.currentUserId,
      }).eq('id', user.id);
      
      await NotificationService().notify(
        userId: user.id,
        title: 'Documents Approved ✅',
        message: 'Badhai ho ${user.fullName?.split(' ').first ?? ''}! Aapke documents verify ho gaye. Ab aap rides publish kar sakte hain.',
        type: 'document_approved',
      );
      
      if (mounted) {
        setState(() {
          _users.removeWhere((u) => u.id == user.id);
          _processingIds.remove(user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} ke documents approve ho gaye ✅'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingIds.remove(user.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showRejectDialog(UserModel user) {
    final reasonController = TextEditingController();
    bool submitting = false;
    
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rejection Reason'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.fullName} ke documents reject kyun kar rahe hain?'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Reason likhein (required — user ko dikhega)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: reasonController.text.trim().isEmpty || submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      try {
                        await SupabaseService.client.from('users').update({
                          'doc_verification_status': 'rejected',
                          'doc_rejection_reason': reasonController.text.trim(),
                          'doc_reviewed_at': DateTime.now().toIso8601String(),
                          'doc_reviewed_by': SupabaseService.currentUserId,
                        }).eq('id', user.id);
                        
                        await NotificationService().notify(
                          userId: user.id,
                          title: 'Documents Reject Hue ❌',
                          message: 'Reason: ${reasonController.text.trim()}. Sahi documents upload karke dobara submit karein.',
                          type: 'document_rejected',
                        );
                        
                        if (mounted) {
                          Navigator.pop(dialogCtx);
                          setState(() => _users.removeWhere((u) => u.id == user.id));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected — user ko notify kar diya'), backgroundColor: AppColors.error));
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(submitting ? 'Processing...' : 'Reject Karo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(UserModel user) {
    final isProcessing = _processingIds[user.id] == true;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── USER INFO HEADER ───
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(user.fullName?.substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName ?? 'No Name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(user.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    if (user.phone != null) Text('+91 ${user.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: _tabs[_selectedTab].toUpperCase(),
                      color: _selectedTab == 0 ? AppColors.warning : (_selectedTab == 1 ? AppColors.success : AppColors.error),
                      bgColor: _selectedTab == 0 ? AppColors.warningLight : (_selectedTab == 1 ? AppColors.successLight : AppColors.errorLight),
                    ),
                    const SizedBox(height: 4),
                    Text(_formatDate(user.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ─── 3 DOCUMENT IMAGES (side by side/Wrap) ───
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: 250, child: DocImageViewer(label: 'Driving License (Front)', path: user.docDrivingLicenseFront)),
                SizedBox(width: 250, child: DocImageViewer(label: 'Driving License (Back)', path: user.docDrivingLicenseBack)),
                SizedBox(width: 250, child: DocImageViewer(label: 'Vehicle RC Book', path: user.docVehicleRc)),
              ],
            ),
            
            // ─── REJECTION REASON (agar rejected tab pe hai) ───
            if (_selectedTab == 2 && user.docRejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Rejection Reason: ${user.docRejectionReason}', style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),
            ],
            
            // ─── ACTION BUTTONS (sirf pending tab pe) ───
            if (_selectedTab == 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject Karo'),
                    onPressed: isProcessing ? null : () => _showRejectDialog(user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: isProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check, size: 16),
                    label: Text(isProcessing ? 'Processing...' : 'Approve Karo'),
                    onPressed: isProcessing ? null : () => _approve(user),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ],
              ),
            ],
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
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
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
            // ─── TAB SELECTOR ───
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: _tabs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final label = entry.value;
                        final isActive = _selectedTab == i;
                        return GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _selectedTab = i;
                                _users = [];
                                _loadUsers();
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isActive ? Colors.white : AppColors.textPrimary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_users.length} users',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Use conditional rendering with ternary operator for widget list
            _loading
                ? const Expanded(child: Center(child: LoadingWidget()))
                : _users.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedTab == 0 ? Icons.check_circle : Icons.description,
                                color: Colors.grey,
                                size: 56,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 0
                                    ? 'Koi pending verification nahi! ✅'
                                    : 'Koi ${_tabs[_selectedTab].toLowerCase()} document nahi',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (ctx, i) => _buildDocumentCard(_users[i]),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
