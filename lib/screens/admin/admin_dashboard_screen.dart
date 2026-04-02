import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int totalUsers = 0;
  int activeRides = 0;
  int pendingVerifications = 0;
  int activeSos = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      final supabase = SupabaseService.client;
      
      final usersCount = await supabase.from('users').count(CountOption.exact);
      final ridesCount = await supabase.from('rides').count(CountOption.exact).eq('status', 'active');
      final docsCount = await supabase.from('users').count(CountOption.exact).eq('doc_verification_status', 'pending');
      final sosCount = await supabase.from('sos_alerts').count(CountOption.exact).eq('is_active', true);

      if (mounted) {
        setState(() {
          totalUsers = usersCount;
          activeRides = ridesCount;
          pendingVerifications = docsCount;
          activeSos = sosCount;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatGrid(isMobile),
              const SizedBox(height: 32),
              if (isMobile) ...[
                _buildGrowthChart(),
                const SizedBox(height: 24),
                _buildActivityDistribution(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildGrowthChart()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildActivityDistribution()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Command Center',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          'Real-time overview',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 2.5 : 1.8,
      children: [
        _buildKpiCard('Total Users', totalUsers.toString(), Icons.people_rounded, AppColors.primary),
        _buildKpiCard('Active Rides', activeRides.toString(), Icons.local_taxi_rounded, AppColors.success),
        _buildKpiCard('Pending Docs', pendingVerifications.toString(), Icons.verified_user_rounded, AppColors.warning),
        _buildKpiCard('Active SOS', activeSos.toString(), Icons.emergency_rounded, AppColors.error),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [const FlSpot(0, 5), const FlSpot(5, 15), const FlSpot(10, 10), const FlSpot(15, 25)],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityDistribution() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(color: Colors.blue, value: 60, title: 'Cars', radius: 40),
            PieChartSectionData(color: Colors.orange, value: 40, title: 'Bikes', radius: 40),
          ],
        ),
      ),
    );
  }
}
