import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final canView = auth.appUser?.role == UserRole.ngo || auth.appUser?.role == UserRole.admin;
    if (!canView) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Analytics are available to organizers only.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final counts = data['counts'] as Map<String, int>;
        final totalDonations = data['totalDonations'] as double;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(title: 'Users', value: counts['users']?.toString() ?? '0', icon: Icons.people),
                  _StatCard(title: 'Opportunities', value: counts['listings']?.toString() ?? '0', icon: Icons.work),
                  _StatCard(title: 'Donation Drives', value: counts['drives']?.toString() ?? '0', icon: Icons.volunteer_activism),
                  _StatCard(title: 'E-Certificates', value: counts['certificates']?.toString() ?? '0', icon: Icons.card_membership),
                  _StatCard(title: 'Attendances', value: counts['attendances']?.toString() ?? '0', icon: Icons.event_available),
                  _StatCard(title: 'Total donations', value: totalDonations.toStringAsFixed(0), icon: Icons.attach_money),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Overview chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (counts['users']! + counts['listings']! + counts['drives']! + counts['certificates']!).toDouble() + 10,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                        const labels = ['Users', 'Listings', 'Drives', 'Certs'];
                        final i = v.toInt();
                        if (i >= 0 && i < labels.length) return Text(labels[i]);
                        return const Text('');
                      })),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: (counts['users'] ?? 0).toDouble(), color: Colors.blue)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: (counts['listings'] ?? 0).toDouble(), color: Colors.green)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: (counts['drives'] ?? 0).toDouble(), color: Colors.orange)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: (counts['certificates'] ?? 0).toDouble(), color: Colors.purple)]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    final counts = await FirestoreService().getAnalyticsCounts();
    final totalDonations = await FirestoreService().getTotalDonations();
    return {'counts': counts, 'totalDonations': totalDonations};
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
