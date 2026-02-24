import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
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
  String? _insightText;
  bool _loadingInsights = false;
  bool _bypassCache = false;

  void _retry() {
    setState(() => _bypassCache = true);
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
      future: _analyticsData.getData(uid, role, bypassCache: _bypassCache),
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

        switch (role) {
          case UserRole.volunteer:
            return _UserAnalyticsView(
              data: payload.userData ?? UserAnalyticsData.empty,
              points: payload.userData?.pointsCollected ?? 0,
              insightText: _insightText,
              loadingInsights: _loadingInsights,
              onGenerateInsights: _loadAIInsights,
            );
          case UserRole.ngo:
            return _OrganizerAnalyticsView(
              data: payload.organizerData ?? OrganizerAnalyticsData.empty,
              insightText: _insightText,
              loadingInsights: _loadingInsights,
              onGenerateInsights: _loadAIInsights,
            );
          case UserRole.admin:
            return _AdminAnalyticsView(
              data: payload.adminData ?? AdminAnalyticsData.empty,
              insightText: _insightText,
              loadingInsights: _loadingInsights,
              onGenerateInsights: _loadAIInsights,
            );
        }
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
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: figmaPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
          child: const Icon(Icons.bar_chart_rounded, color: figmaPurple, size: 28),
        ),
        const SizedBox(width: 16),
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
          IconButton.filled(
            onPressed: loadingInsights ? null : onGenerateInsights,
            icon: Icon(loadingInsights ? Icons.hourglass_empty : Icons.auto_awesome),
            tooltip: 'Generate AI Insights',
            style: IconButton.styleFrom(
              backgroundColor: figmaOrange,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    ),
  );
}

Widget _buildProgressBar(BuildContext context, {required String leftLabel, required String rightLabel, required double fraction, required String message}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(kPagePadding, 0, kPagePadding, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: figmaPurple)),
            Text(rightLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber[700])),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(figmaPurple),
          ),
        ),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
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

Widget _buildSuggestionSection(BuildContext context, {required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(kPagePadding, 0, kPagePadding, 24),
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
            Icon(Icons.lightbulb_outline, size: 20, color: figmaOrange),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: figmaBlack)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _UserAnalyticsView extends StatelessWidget {
  const _UserAnalyticsView({
    required this.data,
    required this.points,
    this.insightText,
    required this.loadingInsights,
    required this.onGenerateInsights,
  });

  final UserAnalyticsData data;
  final int points;
  final String? insightText;
  final bool loadingInsights;
  final VoidCallback? onGenerateInsights;

  @override
  Widget build(BuildContext context) {
    const eliteThreshold = 1000;
    final fraction = (points / eliteThreshold).clamp(0.0, 1.0);
    final toGo = (eliteThreshold - points).clamp(0, eliteThreshold);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, onGenerateInsights: onGenerateInsights, loadingInsights: loadingInsights),
          _buildProgressBar(
            context,
            leftLabel: 'GOLD',
            rightLabel: 'ELITE',
            fraction: fraction,
            message: toGo > 0 ? '$toGo points to Elite. Contribute $toGo points more to unlock Elite.' : 'Elite unlocked!',
          ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    value: '${data.pointsCollected}',
                    label: 'Points Collected',
                    icon: Icons.star,
                    highlight: true,
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
          _buildSuggestionSection(
            context,
            title: 'Suggestion',
            child: _UserSuggestionContent(),
          ),
        ],
      ),
    );
  }
}

class _UserSuggestionContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirestoreService().getVolunteerListings(showPrivate: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Row(
            children: [
              Expanded(child: Text('Find an opportunity that fits you.', style: TextStyle(color: Colors.grey[700]))),
              IconButton(
                onPressed: () => context.go('/opportunities'),
                icon: const Icon(Icons.arrow_forward_rounded),
                color: figmaOrange,
              ),
            ],
          );
        }
        final listing = snapshot.data!.first;
        return InkWell(
          onTap: () => context.go('/opportunities'),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w600, color: figmaBlack)),
                    if (listing.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        listing.description!.length > 80 ? '${listing.description!.substring(0, 80)}...' : listing.description!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                    if (listing.organizationName != null || listing.location != null)
                      Text(
                        '${listing.organizationName ?? ''}${listing.organizationName != null && listing.location != null ? ' | ' : ''}${listing.location ?? ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: figmaOrange),
            ],
          ),
        );
      },
    );
  }
}

class _OrganizerAnalyticsView extends StatelessWidget {
  const _OrganizerAnalyticsView({
    required this.data,
    this.insightText,
    required this.loadingInsights,
    required this.onGenerateInsights,
  });

  final OrganizerAnalyticsData data;
  final String? insightText;
  final bool loadingInsights;
  final VoidCallback? onGenerateInsights;

  @override
  Widget build(BuildContext context) {
    const impactPartnerThreshold = 1000;
    final fraction = (data.impactFunds / impactPartnerThreshold).clamp(0.0, 1.0);
    final toGo = (impactPartnerThreshold - data.impactFunds).clamp(0.0, impactPartnerThreshold);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, onGenerateInsights: onGenerateInsights, loadingInsights: loadingInsights),
          _buildProgressBar(
            context,
            leftLabel: 'GRASSROOTS',
            rightLabel: 'IMPACT PARTNER',
            fraction: fraction,
            message: toGo > 0 ? '50% to Impact Partner. Contribute 500 points more to unlock Impact Partner.' : 'Impact Partner level.',
          ),
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
          _buildSuggestionSection(
            context,
            title: 'Suggestion',
            child: Text(
              'Targeted Invite: Skill-Based Outreach. Invite volunteers with matching skills to your campaigns.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
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
  });

  final AdminAnalyticsData data;
  final String? insightText;
  final bool loadingInsights;
  final VoidCallback? onGenerateInsights;

  @override
  Widget build(BuildContext context) {
    final activeEventsStr = data.activeEvents >= 1000 ? '${(data.activeEvents / 1000).toStringAsFixed(2)}K' : '${data.activeEvents}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, onGenerateInsights: onGenerateInsights, loadingInsights: loadingInsights),
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
          _buildSuggestionSection(
            context,
            title: 'Suggestion',
            child: Text(
              'System Flag: Review high-activity or flagged accounts from the Developer or Admin tools.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
