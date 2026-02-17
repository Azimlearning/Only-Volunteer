import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  List<Map<String, String>> _recommendations = [];
  bool _loading = false;
  bool _initialized = false;
  AppUser? _appUser;
  String? _locationSummary;
  List<String> _recentActivitySummary = [];

  static const _suggestionChips = [
    'Where can I help today?',
    'Find donation drives',
    'How do I earn e-certificates?',
    'What are current alerts?',
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
    _loadRecommendations();
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _loadRecommendations() async {
    if (_appUser == null) return;
    try {
      final drives = await _firestore.getDonationDrives();
      final listings = await _firestore.getVolunteerListings();
      final recs = await _gemini.getConciergeRecommendations(
        user: _appUser!,
        drives: drives,
        listings: listings,
        locationSummary: _locationSummary,
        limit: 5,
      );
      if (mounted) setState(() => _recommendations = recs);
    } catch (_) {}
  }

  void _startNewChat() {
    _gemini.startChatWithContext(
      user: _appUser,
      locationSummary: _locationSummary,
      recentActivitySummary: _recentActivitySummary,
    );
    setState(() {
      _messages.clear();
      _recommendations = [];
    });
    _loadRecommendations();
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
    });
    String reply;
    try {
      reply = await _gemini.chat(trimmed);
    } catch (_) {
      reply = Config.chatbotFallbackMessage;
    }
    if (mounted) {
      setState(() {
        _messages.add(MapEntry(false, reply));
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
        // Header with gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Chatbot',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get personalized recommendations and answers',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'New chat',
                onPressed: _initialized && !_loading ? _startNewChat : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: !_initialized
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_messages.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Hi${_appUser?.displayName != null ? ', ${_appUser!.displayName}' : ''}! I can help you find opportunities, donation drives, and answer questions about OnlyVolunteer.",
                          style: TextStyle(color: Colors.grey[700], height: 1.4),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestionChips.map((label) {
                          return ActionChip(
                            label: Text(label),
                            onPressed: _loading ? null : () => _send(label),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          );
                        }).toList(),
                      ),
                      if (_recommendations.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Suggested for you', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ..._recommendations.map((r) => _RecommendationCard(
                              type: r['type']!,
                              id: r['id']!,
                              title: r['title']!,
                            )),
                      ],
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(content, style: TextStyle(height: 1.4, color: isUser ? null : Colors.black87)),
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
                      if (_recommendations.isNotEmpty && _messages.length >= 2) ...[
                        const SizedBox(height: 12),
                        Text('Suggested for you', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ..._recommendations.map((r) => _RecommendationCard(
                              type: r['type']!,
                              id: r['id']!,
                              title: r['title']!,
                            )),
                      ],
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask the concierge...',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  maxLength: Config.chatbotMaxInputLength,
                  maxLines: null,
                  enabled: !_loading,
                  onSubmitted: (_) => _send(_controller.text),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _loading ? null : () => _send(_controller.text),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isDrive ? Icons.volunteer_activism : Icons.work, color: Theme.of(context).colorScheme.primary),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(isDrive ? 'Donation drive' : 'Volunteer opportunity'),
        trailing: const Icon(Icons.arrow_forward),
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
