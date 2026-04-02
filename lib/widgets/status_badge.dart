import 'package:flutter/material.dart';
import 'package:rideon_admin/core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Factory constructors
  factory StatusBadge.approved() => const StatusBadge(
        label: 'Approved',
        color: AppColors.success,
        bgColor: AppColors.successLight,
      );

  factory StatusBadge.pending() => const StatusBadge(
        label: 'Pending',
        color: AppColors.warning,
        bgColor: AppColors.warningLight,
      );

  factory StatusBadge.rejected() => const StatusBadge(
        label: 'Rejected',
        color: AppColors.error,
        bgColor: AppColors.errorLight,
      );

  factory StatusBadge.notSubmitted() => StatusBadge(
        label: 'Not Submitted',
        color: AppColors.textSecondary,
        bgColor: Colors.grey.shade100,
      );

  factory StatusBadge.active() => const StatusBadge(
        label: 'Active',
        color: AppColors.success,
        bgColor: AppColors.successLight,
      );

  factory StatusBadge.full() => const StatusBadge(
        label: 'Full',
        color: AppColors.info,
        bgColor: AppColors.infoLight,
      );

  factory StatusBadge.cancelled() => const StatusBadge(
        label: 'Cancelled',
        color: AppColors.error,
        bgColor: AppColors.errorLight,
      );

  factory StatusBadge.completed() => StatusBadge(
        label: 'Completed',
        color: AppColors.textSecondary,
        bgColor: Colors.grey.shade100,
      );

  factory StatusBadge.confirmed() => const StatusBadge(
        label: 'Confirmed',
        color: AppColors.success,
        bgColor: AppColors.successLight,
      );

  factory StatusBadge.banned() => const StatusBadge(
        label: 'Banned',
        color: AppColors.error,
        bgColor: AppColors.errorLight,
      );

  factory StatusBadge.admin() => const StatusBadge(
        label: 'Admin',
        color: Colors.deepPurple,
        bgColor: Color(0xFFF3E5F5),
      );
}
