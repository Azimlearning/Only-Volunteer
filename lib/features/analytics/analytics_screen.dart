import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_data_service.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';
import 'analytics_data.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsDataService _analyticsData = AnalyticsDataService();
  final FirestoreService _firestore = FirestoreService();
  String? _insightText;
  bool _loadingInsights = false;
  bool _bypassCache = false;
  /// When current user is admin, which view to show (Admin / User / Org).
  UserRole _viewAsRole = UserRole.admin;

  void _retry() {
    setState(() => _bypassCache = true);
  }

  Widget _buildViewAsDropdown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text('View as:', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(width: 12),
          DropdownButton<UserRole>(
            value: _viewAsRole,
            items: const [
              DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
              DropdownMenuItem(value: UserRole.volunteer, child: Text('User')),
              DropdownMenuItem(value: UserRole.ngo, child: Text('Org')),
            ],
            onChanged: (UserRole? v) {
              if (v != null) setState(() { _viewAsRole = v; _bypassCache = true; });
            },
          ),
        ],
      ),
    );
  }

  Future<AnalyticsPayload> _getPayloadFuture(String uid, UserRole role) async {
    UserRole effectiveRole = role;
    String effectiveUid = uid;
    if (role == UserRole.admin) {
      effectiveRole = _viewAsRole;
      if (_viewAsRole == UserRole.ngo) {
        effectiveUid = await _firestore.getFirstNgoUserId() ?? uid;
      }
    }
    return _analyticsData.getData(effectiveUid, effectiveRole, bypassCache: _bypassCache);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final role = auth.appUser?.role ?? UserRole.volunteer;
    final uid = auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return const Center(child: Text('Please sign in to view analytics.'));
    }

    return FutureBuilder<AnalyticsPayload>(
      future: _getPayloadFuture(uid, role),
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
                  Text(
                    'Error loading analytics: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final payload = snapshot.data!;
        if (payload.hasError && payload.userData == null && payload.organizerData == null && payload.adminData == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(payload.error ?? 'Error loading analytics.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final effectiveRole = role == UserRole.admin ? _viewAsRole : role;
        final belowHeader = role == UserRole.admin ? _buildViewAsDropdown(context) : null;
        Widget content;
        switch (effectiveRole) {
          case UserRole.volunteer:
            content = _UserAnalyticsView(
              data: payload.userData ?? UserAnalyticsData.empty,
              insightText: _insightText,
              loadingInsights: _loadingInsights,
              onGenerateInsights: _loadAIInsights,
              belowHeader: belowHeader,
            );
            break;
          case UserRole.ngo:
            content = _OrganizerAnalyticsView(
              data: payload.organizerData ?? OrganizerAnalyticsData.empty,
              insightText: _insightText,
              loadingInsights: _loadingInsights,
              onGenerateInsights: _loadAIInsights,
              belowHeader: belowHeader,
            );
            break;
          case UserRole.admin:
            content = _AdminAnalyticsView(
              data: payload.adminData ?? AdminAnalyticsData.empty,
              insightText: _insightText,
              loadingInsights: _loadingInsights,
              onGenerateInsights: _loadAIInsights,
              belowHeader: belowHeader,
            );
            break;
        }
        if (role != UserRole.admin) return content;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: content)],
        );
      },
    );
  }

  Future<void> _loadAIInsights() async {
    setState(() => _loadingInsights = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateAnalyticalInsight');
      final result = await callable.call().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Request timed out'),
      );
      final descriptive = result.data['descriptive'] as String?;
      final prescriptive = result.data['prescriptive'] as String?;
      setState(() {
        _insightText = [descriptive, prescriptive].where((e) => e != null && e.isNotEmpty).join('\n\n');
        _loadingInsights = false;
      });
    } catch (e) {
      setState(() {
        _insightText = 'Insights temporarily unavailable. Try again later.';
        _loadingInsights = false;
      });
    }
  }
}

Widget _buildHeader(BuildContext context, {VoidCallback? onGenerateInsights, bool loadingInsights = false}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(kPagePadding, 20, kPagePadding, 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          figmaPurple.withOpacity(0.08),
          figmaOrange.withOpacity(0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(kCardRadius),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: kHeaderTitleSize,
                  fontWeight: FontWeight.bold,
                  color: figmaBlack,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Take a look back on your contributions.',
                style: TextStyle(fontSize: kHeaderSubtitleSize, color: Colors.grey[700], height: 1.3),
              ),
            ],
          ),
        ),
        if (onGenerateInsights != null)
          FilledButton(
            onPressed: loadingInsights ? null : onGenerateInsights,
            style: FilledButton.styleFrom(
              backgroundColor: figmaOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(loadingInsights ? 'Generating…' : 'Generate insights'),
          ),
      ],
    ),
  );
}

Widget _metricCard(BuildContext context, {required String value, required String label, required IconData icon, bool highlight = false, Color? valueColor}) {
  final effectiveValueColor = valueColor ?? (highlight ? Colors.white : figmaBlack);
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCardRadius),
      side: BorderSide(color: highlight ? figmaOrange : Colors.grey.shade200),
    ),
    color: highlight ? figmaOrange : Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: highlight ? Colors.white : (valueColor == Colors.red ? Colors.red : figmaOrange)),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: effectiveValueColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: highlight ? Colors.white70 : Colors.grey[700]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAIInsightSection(BuildContext context, {required String title, String? body}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kCardRadius),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: figmaPurple),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack)),
          ],
        ),
        if (body != null && body.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(body, style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800])),
        ] else
          const SizedBox(height: 8),
        if (body == null || body.isEmpty)
          Text('Generate insights to see a summary here.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    ),
  );
}

class _UserAnalyticsView extends StatelessWidget {
  const _UserAnalyticsView({
    required this.data,
    this.insightText,
    required this.loadingInsights,
    required this.onGenerateInsights,
    this.belowHeader,
  });

  final UserAnalyticsData data;
  final String? insightText;
  final bool loadingInsights;
  final VoidCallback? onGenerateInsights;
  final Widget? belowHeader;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, onGenerateInsights: onGenerateInsights, loadingInsights: loadingInsights),
          if (belowHeader != null) belowHeader!,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
            child: Row(
              children: [
                Expanded(
                  child: _metricCard(
                    context,
                    value: '${data.hoursVolunteerism.toStringAsFixed(0)} Hrs',
                    label: 'Spent on Volunteerism',
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    value: 'RM${data.rmDonations.toStringAsFixed(0)}',
                    label: 'Spent on Donations',
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAIInsightSection(
            context,
            title: 'What these contribution says about you?',
            body: insightText,
          ),
        ],
      ),
    );
  }
}

class _OrganizerAnalyticsView extends StatelessWidget {
  const _OrganizerAnalyticsView({
    required this.data,
    this.insightText,
    required this.loadingInsights,
    required this.onGenerateInsights,
    this.belowHeader,
  });

  final OrganizerAnalyticsData data;
  final String? insightText;
  final bool loadingInsights;
  final VoidCallback? onGenerateInsights;
  final Widget? belowHeader;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, onGenerateInsights: onGenerateInsights, loadingInsights: loadingInsights),
          if (belowHeader != null) belowHeader!,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
            child: Row(
              children: [
                Expanded(
                  child: _metricCard(
                    context,
                    value: '${data.totalVolunteers}',
                    label: 'Total Volunteers',
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    value: '${data.activeCampaigns}',
                    label: 'Active Campaigns',
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    value: data.impactFunds >= 1000 ? 'RM${(data.impactFunds / 1000).toStringAsFixed(1)}K' : 'RM${data.impactFunds.toStringAsFixed(0)}',
                    label: 'Impact Funds',
                    icon: Icons.attach_money,
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAIInsightSection(
            context,
            title: 'What these metrics say about your impact?',
            body: insightText,
          ),
        ],
      ),
    );
  }
}

class _AdminAnalyticsView extends StatelessWidget {
  const _AdminAnalyticsView({
    required this.data,
    this.insightText,
    required this.loadingInsights,
    required this.onGenerateInsights,
    this.belowHeader,
  });

  final AdminAnalyticsData data;
  final String? insightText;
  final bool loadingInsights;
  final VoidCallback? onGenerateInsights;
  final Widget? belowHeader;

  @override
  Widget build(BuildContext context) {
    final activeEventsStr = data.activeEvents >= 1000 ? '${(data.activeEvents / 1000).toStringAsFixed(2)}K' : '${data.activeEvents}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, onGenerateInsights: onGenerateInsights, loadingInsights: loadingInsights),
          if (belowHeader != null) belowHeader!,
          Padding(
            padding: const EdgeInsets.fromLTRB(kPagePadding, 16, kPagePadding, 8),
            child: Row(
              children: [
                Expanded(
                  child: _metricCard(
                    context,
                    value: '${data.numberOfUsers}',
                    label: 'Number of Users',
                    icon: Icons.people,
                    valueColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    value: '${data.numberOfOrganisations}',
                    label: 'Number of Organisations',
                    icon: Icons.groups,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    value: activeEventsStr,
                    label: 'Active Events',
                    icon: Icons.calendar_today,
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
          _buildAIInsightSection(
            context,
            title: 'What these metrics say about your impact?',
            body: insightText,
          ),
        ],
      ),
    );
  }
}
