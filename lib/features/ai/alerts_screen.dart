import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/alerts_service.dart';
import '../../core/theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Timer? _refreshTimer;
  bool _generating = false;
  // Keep stream reference stable so refresh/pull-to-refresh does not recreate it
  // (recreating caused the list to briefly disappear when the StreamBuilder re-subscribed).
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _alertsStream;

  @override
  void initState() {
    super.initState();
    _alertsStream = FirestoreService().alertsStream();
    _refreshTimer = Timer.periodic(const Duration(hours: 12), (_) {
      if (mounted) _runAutoGenerate();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoGenerate());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _runAutoGenerate() async {
    if (!mounted) return;
    final auth = context.read<AuthNotifier>();
    final location = auth.appUser?.location;
    final userLocation = (location != null && location.isNotEmpty && location != 'Not set')
        ? location
        : null;
    await triggerNewsAlertsGeneration(userLocation: userLocation);
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    await _runAutoGenerate();
  }

  Future<void> _onGenerateNow() async {
    if (_generating || !mounted) return;
    setState(() => _generating = true);
    try {
      final auth = context.read<AuthNotifier>();
      final location = auth.appUser?.location;
      final userLocation = (location != null && location.isNotEmpty && location != 'Not set')
          ? location
          : null;
      final result = await triggerNewsAlertsGeneration(userLocation: userLocation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.ok
              ? 'Done! ${result.alertsCreated} alerts generated from ${result.articlesProcessed} news articles.'
              : 'Failed: ${result.message}'),
          backgroundColor: result.ok ? Colors.green : Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(AlertType type) {
    switch (type) {
      case AlertType.flood:
        return Colors.blue;
      case AlertType.sos:
        return Colors.red;
      case AlertType.general:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.flood:
        return Icons.water_drop;
      case AlertType.sos:
        return Icons.warning;
      case AlertType.general:
        return Icons.info;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final isAdmin = auth.appUser?.role == UserRole.admin || auth.appUser?.role == UserRole.ngo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page header with refresh + admin Generate Now
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(kPagePadding, 20, kPagePadding, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                figmaOrange.withOpacity(0.08),
                figmaPurple.withOpacity(0.08),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: figmaOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(kCardRadius),
                    ),
                    child: const Icon(Icons.notifications_active, color: figmaOrange, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Alerts',
                          style: TextStyle(
                            fontSize: kHeaderTitleSize,
                            fontWeight: FontWeight.bold,
                            color: figmaBlack,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time alerts from AI news monitoring',
                          style: TextStyle(
                            fontSize: kHeaderSubtitleSize,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _onRefresh,
                    tooltip: 'Refresh list',
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: _generating ? null : _onGenerateNow,
                      icon: _generating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.autorenew, size: 18),
                      label: Text(_generating ? 'Generating…' : 'Generate Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: figmaOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Alerts List (stream already ordered by createdAt desc in FirestoreService)
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _alertsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('Error loading alerts: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              final alerts = docs.map((d) => Alert.fromFirestore(d)).toList();

              // Filter out expired alerts
              final now = DateTime.now();
              final activeAlerts = alerts.where((a) {
                if (a.expiresAt == null) return true;
                return a.expiresAt!.isAfter(now);
              }).toList();

              if (activeAlerts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No active alerts',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All clear! Check back for updates.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                padding: const EdgeInsets.all(kPagePadding),
                itemCount: activeAlerts.length,
                itemBuilder: (_, i) {
                  final a = activeAlerts[i];
                  final typeColor = _getTypeColor(a.type);
                  final severityColor = _getSeverityColor(a.severity);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      side: BorderSide(color: typeColor.withOpacity(0.35), width: 1.5),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      onTap: () {
                        // Could navigate to alert details if needed
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row with icon, type, and severity
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getTypeIcon(a.type),
                                    color: typeColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            a.type.name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: typeColor,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          if (a.severity != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: severityColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                a.severity!.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: severityColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (a.createdAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(a.createdAt),
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Title
                            Text(
                              a.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (a.body != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                a.body!,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                              ),
                            ],
                            if (a.region != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.region!,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                            if (a.expiresAt != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires: ${_formatDate(a.expiresAt)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
            },
          ),
        ),
      ],
    );
  }
}
