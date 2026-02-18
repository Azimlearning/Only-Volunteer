import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _descriptiveInsights;
  String? _prescriptiveInsights;
  bool _loadingInsights = false;

  @override
  void initState() {
    super.initState();
    _loadAIInsights();
  }

  Future<void> _loadAIInsights() async {
    setState(() => _loadingInsights = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateAIInsights');
      final result = await callable.call();
      setState(() {
        _descriptiveInsights = result.data['descriptive'] as String?;
        _prescriptiveInsights = result.data['prescriptive'] as String?;
        _loadingInsights = false;
      });
    } catch (e) {
      print('Error loading AI insights: $e');
      setState(() => _loadingInsights = false);
    }
  }

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Error loading analytics: ${snapshot.error}', 
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Trigger rebuild
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final counts = data['counts'] as Map<String, int>;
        final totalDonations = data['totalDonations'] as double;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(_loadingInsights ? Icons.refresh : Icons.auto_awesome),
                    onPressed: _loadingInsights ? null : _loadAIInsights,
                    tooltip: 'Generate AI Insights',
                  ),
                ],
              ),
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
              if (_descriptiveInsights != null || _prescriptiveInsights != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: figmaOrange),
                          const SizedBox(width: 8),
                          const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (_descriptiveInsights != null) ...[
                        const SizedBox(height: 16),
                        const Text('What Happened:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(_descriptiveInsights!, style: const TextStyle(height: 1.5)),
                      ],
                      if (_prescriptiveInsights != null) ...[
                        const SizedBox(height: 16),
                        const Text('Recommendations:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(_prescriptiveInsights!, style: const TextStyle(height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    try {
      final counts = await FirestoreService().getAnalyticsCounts().timeout(
        const Duration(seconds: 10),
        onTimeout: () => {
          'users': 0,
          'listings': 0,
          'drives': 0,
          'certificates': 0,
          'attendances': 0,
        },
      );
      final totalDonations = await FirestoreService().getTotalDonations().timeout(
        const Duration(seconds: 10),
        onTimeout: () => 0.0,
      );
      return {'counts': counts, 'totalDonations': totalDonations};
    } catch (e) {
      print('Error loading analytics: $e');
      // Return default values on error
      return {
        'counts': {
          'users': 0,
          'listings': 0,
          'drives': 0,
          'certificates': 0,
          'attendances': 0,
        },
        'totalDonations': 0.0,
      };
    }
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
