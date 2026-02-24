import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../services/gemini_service.dart';
import '../../services/firestore_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<MapEntry<bool, String>> _messages = [];
  List<String> _lastSuggestions = [];
  String? _lastToolUsed;
  dynamic _lastToolData;
  bool _loading = false;
  bool _initialized = false;
  AppUser? _appUser;
  String? _locationSummary;
  List<String> _recentActivitySummary = [];

  static const _suggestionChips = [
    'Where can I help today?',
    'Find donation drives',
    'What are current alerts?',
    'Suggest things I can do',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _firestore.getUser(uid);
      _appUser = user ?? AppUser(uid: uid, email: FirebaseAuth.instance.currentUser?.email ?? '');
      final attendances = await _firestore.getAttendancesForUser(uid);
      final certs = await _firestore.getCertificatesForUser(uid);
      _recentActivitySummary = [];
      for (final a in attendances.take(3)) {
        _recentActivitySummary.add('Volunteered (${a.hours ?? 0} hrs)');
      }
      for (final c in certs.take(2)) {
        _recentActivitySummary.add('E-certificate: ${c.listingTitle}');
      }
    }
    _gemini.startChatWithContext(
      user: _appUser,
      locationSummary: _locationSummary,
      recentActivitySummary: _recentActivitySummary,
    );
    if (mounted) setState(() => _initialized = true);
  }

  void _startNewChat() {
    _gemini.startChatWithContext(
      user: _appUser,
      locationSummary: _locationSummary,
      recentActivitySummary: _recentActivitySummary,
    );
    setState(() {
      _messages.clear();
      _lastSuggestions = [];
      _lastToolUsed = null;
      _lastToolData = null;
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    if (trimmed.length > Config.chatbotMaxInputLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message must be ${Config.chatbotMaxInputLength} characters or less')),
      );
      return;
    }
    _controller.clear();
    setState(() {
      _messages.add(MapEntry(true, trimmed));
      _loading = true;
      _lastSuggestions = [];
    });
    String reply;
    List<String> suggestions = [];
    String? toolUsed;
    dynamic toolData;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && _appUser != null) {
        final result = await _gemini.chatWithOrchestratorFull(trimmed, uid, pageContext: 'chat');
        reply = result.text;
        suggestions = result.suggestions ?? [];
        toolUsed = result.toolUsed;
        toolData = result.data;
      } else {
        reply = await _gemini.chat(trimmed);
      }
    } catch (e) {
      print('Chatbot error: $e');
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          reply = await _gemini.chatWithRAG(trimmed, uid);
        } else {
          reply = await _gemini.chat(trimmed);
        }
      } catch (e2) {
        print('RAG fallback error: $e2');
        try {
          reply = await _gemini.chat(trimmed);
        } catch (e3) {
          print('Client chat fallback error: $e3');
          reply = Config.chatbotFallbackMessage;
        }
      }
    }
    if (mounted) {
      setState(() {
        _messages.add(MapEntry(false, reply));
        _lastSuggestions = suggestions;
        _lastToolUsed = toolUsed;
        _lastToolData = toolData;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildUserIdentityBlock() {
    final name = _appUser?.displayName ?? _appUser?.email ?? 'User';
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: figmaPurple.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: figmaPurple),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: figmaBlack),
          ),
          const SizedBox(height: 2),
          Text(
            'New Chat',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildToolResultCards(BuildContext context) {
    final list = <Widget>[
      const SizedBox(height: 12),
    ];
    final tool = _lastToolUsed!;
    final data = _lastToolData is Map ? _lastToolData as Map<String, dynamic> : null;
    if (data == null) return list;

    if (tool == 'aidfinder') {
      final nearbyAid = data['nearbyAid'];
      if (nearbyAid is List && nearbyAid.isNotEmpty) {
        list.add(Text('Nearby aid', style: Theme.of(context).textTheme.titleSmall));
        list.add(const SizedBox(height: 8));
        for (final item in nearbyAid) {
          if (item is! Map) continue;
          final id = item['id']?.toString() ?? '';
          final title = item['title']?.toString() ?? '';
          final category = item['category']?.toString();
          final location = item['location']?.toString();
          list.add(_AidSuggestionCard(
            id: id,
            title: title,
            category: category,
            location: location,
          ));
          list.add(const SizedBox(height: 8));
        }
      }
    } else if (tool == 'donation_drives') {
      final drives = data['drives'];
      if (drives is List && drives.isNotEmpty) {
        list.add(Text('Suggested for you', style: Theme.of(context).textTheme.titleSmall));
        list.add(const SizedBox(height: 8));
        for (final item in drives) {
          if (item is! Map) continue;
          list.add(_RecommendationCard(
            type: 'drive',
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? 'Donation drive',
          ));
          list.add(const SizedBox(height: 8));
        }
      }
    } else if (tool == 'matching') {
      final topMatches = data['topMatches'];
      if (topMatches is List && topMatches.isNotEmpty) {
        list.add(Text('Suggested for you', style: Theme.of(context).textTheme.titleSmall));
        list.add(const SizedBox(height: 8));
        for (final item in topMatches) {
          if (item is! Map) continue;
          list.add(_RecommendationCard(
            type: 'activity',
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? 'Volunteer opportunity',
          ));
          list.add(const SizedBox(height: 8));
        }
      }
    } else if (tool == 'alerts') {
      final activeAlerts = data['activeAlerts'];
      if (activeAlerts is List && activeAlerts.isNotEmpty) {
        list.add(Text('Current alerts', style: Theme.of(context).textTheme.titleSmall));
        list.add(const SizedBox(height: 8));
        for (final item in activeAlerts) {
          if (item is! Map) continue;
          list.add(_AlertSuggestionCard(
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? 'Alert',
            region: item['region']?.toString(),
            severity: item['severity']?.toString(),
          ));
          list.add(const SizedBox(height: 8));
        }
      }
    } else if (tool == 'analytics') {
      final metrics = data['metrics'];
      if (metrics is Map && metrics.isNotEmpty) {
        list.add(Text('Your analytics', style: Theme.of(context).textTheme.titleSmall));
        list.add(const SizedBox(height: 8));
        list.add(_AnalyticsSummaryCard(metrics: Map<String, dynamic>.from(metrics)));
        list.add(const SizedBox(height: 8));
      }
    }
    return list;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Page header - Figma / KitaHack 2026 style
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: figmaOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(kCardRadius),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: figmaOrange, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Chatbot',
                      style: TextStyle(
                        fontSize: kHeaderTitleSize,
                        fontWeight: FontWeight.bold,
                        color: figmaBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask anything — alerts, insights, matching, nearby aid',
                      style: TextStyle(
                        fontSize: kHeaderSubtitleSize,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: _initialized && !_loading ? _startNewChat : null,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'New chat',
                style: IconButton.styleFrom(
                  backgroundColor: figmaPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: !_initialized
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                  children: [
                    if (_messages.isEmpty) ...[
                      if (_appUser != null) ...[
                        _buildUserIdentityBlock(),
                        const SizedBox(height: 20),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Hi${_appUser?.displayName != null ? ', ${_appUser!.displayName}' : ''}! I can help you find opportunities, donation drives, and answer questions about OnlyVolunteer.",
                          style: TextStyle(color: Colors.grey[700], height: 1.4),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _suggestionChips.map((label) {
                          return ActionChip(
                            label: Text(label),
                            onPressed: _loading ? null : () => _send(label),
                            backgroundColor: figmaPurple.withOpacity(0.08),
                            side: BorderSide(color: figmaPurple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kCardRadius),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      ..._messages.asMap().entries.map((entry) {
                        final isUser = entry.value.key;
                        final content = entry.value.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? figmaOrange.withOpacity(0.15)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isUser
                                      ? Border.all(color: figmaOrange.withOpacity(0.3))
                                      : null,
                                ),
                                child: isUser
                                    ? Text(
                                        content,
                                        style: TextStyle(
                                          height: 1.4,
                                          color: figmaBlack,
                                          fontSize: 15,
                                        ),
                                      )
                                    : MarkdownBody(
                                        data: content,
                                        styleSheet: MarkdownStyleSheet(
                                          p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                height: 1.4,
                                                color: Colors.black87,
                                                fontSize: 15,
                                              ) ??
                                              const TextStyle(
                                                height: 1.4,
                                                color: Colors.black87,
                                                fontSize: 15,
                                              ),
                                          strong: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      if (_lastToolUsed != null && _lastToolData != null) ...[
                        ..._buildToolResultCards(context),
                      ],
                    ],
                  ],
                ),
        ),
        if (_lastSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _lastSuggestions.map((label) {
                return ActionChip(
                  label: Text(label),
                  onPressed: _loading ? null : () => _send(label),
                  backgroundColor: figmaPurple.withOpacity(0.08),
                  side: BorderSide(color: figmaPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kCardRadius),
                  ),
                );
              }).toList(),
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 12, kPagePadding, 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _loading ? null : _startNewChat,
                icon: const Icon(Icons.add_circle_outline),
                color: figmaPurple,
                tooltip: 'New chat',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _messages.isEmpty
                        ? 'Ask for help, get information, create a volunteer task or more!'
                        : 'Ask me anything...',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      borderSide: const BorderSide(color: figmaOrange, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  maxLength: Config.chatbotMaxInputLength,
                  maxLines: null,
                  enabled: !_loading,
                  onSubmitted: (_) => _send(_controller.text),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _loading ? null : () => _send(_controller.text),
                icon: const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: figmaOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsSummaryCard extends StatelessWidget {
  const _AnalyticsSummaryCard({required this.metrics});

  final Map<String, dynamic> metrics;

  static String _label(String key) {
    switch (key) {
      case 'hoursVolunteerism':
        return 'Hours volunteered';
      case 'rmDonations':
        return 'Donations (RM)';
      case 'pointsCollected':
        return 'Points';
      case 'totalVolunteers':
        return 'Total volunteers';
      case 'activeCampaigns':
        return 'Active campaigns';
      case 'impactFunds':
        return 'Impact funds (RM)';
      case 'numberOfUsers':
        return 'Users';
      case 'numberOfOrganisations':
        return 'Organisations';
      case 'activeEvents':
        return 'Active events';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = metrics.entries.take(3).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: figmaPurple.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: entries.map((e) {
            final v = e.value;
            final str = v is num ? (v is double ? v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1) : v.toString()) : v.toString();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(str, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: figmaBlack)),
                const SizedBox(height: 4),
                Text(_label(e.key), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.type, required this.id, required this.title});

  final String type;
  final String id;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDrive = type == 'drive';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: figmaOrange.withOpacity(0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: figmaOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(isDrive ? Icons.volunteer_activism : Icons.work_rounded, color: figmaOrange, size: 22),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, color: figmaBlack),
        ),
        subtitle: Text(
          isDrive ? 'Donation drive' : 'Volunteer opportunity',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: figmaOrange),
        onTap: () {
          if (isDrive) {
            context.go('/drives');
          } else {
            context.go('/opportunities');
          }
        },
      ),
    );
  }
}

class _AidSuggestionCard extends StatelessWidget {
  const _AidSuggestionCard({
    required this.id,
    required this.title,
    this.category,
    this.location,
  });

  final String id;
  final String title;
  final String? category;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: figmaOrange.withOpacity(0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: figmaOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.handshake_rounded, color: figmaOrange, size: 22),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, color: figmaBlack),
        ),
        subtitle: Text(
          [
            if (category != null && category!.isNotEmpty) category,
            if (location != null && location!.isNotEmpty) location,
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: figmaOrange),
        onTap: () => context.go('/finder'),
      ),
    );
  }
}

class _AlertSuggestionCard extends StatelessWidget {
  const _AlertSuggestionCard({
    required this.id,
    required this.title,
    this.region,
    this.severity,
  });

  final String id;
  final String title;
  final String? region;
  final String? severity;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: figmaOrange.withOpacity(0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: figmaOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning_amber_rounded, color: figmaOrange, size: 22),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, color: figmaBlack),
        ),
        subtitle: Text(
          [
            if (region != null && region!.isNotEmpty) region,
            if (severity != null && severity!.isNotEmpty) severity,
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: figmaOrange),
        onTap: () => context.go('/alerts'),
      ),
    );
  }
}
