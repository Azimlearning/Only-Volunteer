import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchResult {
  final String id;
  final String title;
  final String? organizationName;
  final String? location;
  final int matchScore;
  final String matchExplanation;

  _MatchResult({
    required this.id,
    required this.title,
    this.organizationName,
    this.location,
    required this.matchScore,
    required this.matchExplanation,
  });

  factory _MatchResult.fromMap(Map<String, dynamic> map) {
    return _MatchResult(
      id: map['id'] as String,
      title: map['title'] as String,
      organizationName: map['organizationName'] as String?,
      location: map['location'] as String?,
      matchScore: (map['matchScore'] as num?)?.toInt() ?? 0,
      matchExplanation: map['matchExplanation'] as String? ?? 'Good match',
    );
  }
}

class _MatchScreenState extends State<MatchScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<MapEntry<bool, String>> _conversation = [];
  String? _currentQuestion;
  bool _loading = false;
  String? _error;
  List<_MatchResult> _matched = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndStart();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndStart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'Sign in to get matched');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await _fetchNextQuestion();
  }

  Future<void> _fetchNextQuestion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('getNextProfileQuestion');
      final history = _conversation.map((e) => {
        'role': e.key ? 'user' : 'model',
        'content': e.value,
      }).toList();
      final result = await callable.call({'conversationHistory': history}).timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      final data = result.data as Map<String, dynamic>?;
      if (data == null || !mounted) return;
      final done = data['done'] as bool? ?? false;
      if (done) {
        final profile = data['profile'] as Map<String, dynamic>?;
        if (profile != null) {
          await _runAssessment(uid, profile);
          return;
        }
      }
      final question = data['question'] as String?;
      if (mounted) {
        setState(() {
          _currentQuestion = question;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
          _loading = false;
          _currentQuestion = 'What skills or interests could you volunteer with?';
        });
      }
    }
  }

  Future<void> _runAssessment(String uid, Map<String, dynamic> profile) async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('runMatchAssessment');
      final answers = {
        'skills': profile['skills'] is List ? profile['skills'] : [],
        'interests': profile['skills'] is List ? profile['skills'] : [],
        'availability': profile['availability']?.toString() ?? '',
        'location': profile['location']?.toString() ?? '',
        'causes': profile['causes'] is List ? profile['causes'] : [],
      };
      final result = await callable.call({'userId': uid, 'answers': answers}).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException('Matching timed out'),
      );
      final data = result.data as Map<String, dynamic>?;
      final topMatches = data?['topMatches'] as List<dynamic>?;
      if (mounted) {
        Provider.of<AuthNotifier>(context, listen: false).refreshAppUser();
        setState(() {
          _matched = (topMatches ?? [])
              .map((m) => _MatchResult.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList();
          _showResults = true;
          _loading = false;
          _currentQuestion = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendAnswer() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _loading) return;
    _messageController.clear();
    setState(() {
      _conversation.add(MapEntry(true, text));
      if (_currentQuestion != null) {
        _conversation.add(MapEntry(false, _currentQuestion!));
        _currentQuestion = null;
      }
      _loading = true;
    });
    await _fetchNextQuestion();
    if (mounted) {
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
  }

  void _startOver() {
    setState(() {
      _conversation = [];
      _currentQuestion = null;
      _matched = [];
      _showResults = false;
      _error = null;
      _loading = true;
    });
    _checkAuthAndStart();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _conversation.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kPagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => context.go('/login'), child: const Text('Sign in')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                child: const Icon(Icons.auto_awesome, color: figmaOrange, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Match Me',
                      style: TextStyle(
                        fontSize: kHeaderTitleSize,
                        fontWeight: FontWeight.bold,
                        color: figmaBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Answer a few questions to find your best fit',
                      style: TextStyle(
                        fontSize: kHeaderSubtitleSize,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showResults || _conversation.isNotEmpty)
                IconButton(
                  onPressed: _loading ? null : _startOver,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Start over',
                ),
            ],
          ),
        ),
        if (_showResults) ...[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kPagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  if (_matched.isEmpty && !_loading)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No matches right now. Try broadening your skills or causes, or check back later for new opportunities.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    )
                  else ...[
                    Text('Best matches for you', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ..._matched.take(10).map((match) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
                      child: InkWell(
                        onTap: () => context.go('/opportunities'),
                        borderRadius: BorderRadius.circular(kCardRadius),
                        child: ExpansionTile(
                          title: Text(match.title),
                          subtitle: Text('${match.organizationName ?? ""} · ${match.location ?? ""}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text('${match.matchScore}%'),
                                backgroundColor: match.matchScore >= 75
                                    ? Colors.green.withOpacity(0.2)
                                    : match.matchScore >= 50
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: match.matchScore >= 75
                                      ? Colors.green
                                      : match.matchScore >= 50
                                          ? Colors.orange
                                          : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.auto_awesome, size: 16, color: figmaOrange),
                                      const SizedBox(width: 8),
                                      const Text('Why this matches:', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    match.matchExplanation,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
              children: [
                if (_conversation.isEmpty && _currentQuestion != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    "I'll ask you a few short questions so we can find the best volunteer opportunities for you.",
                    style: TextStyle(color: Colors.grey[700], height: 1.4),
                  ),
                  const SizedBox(height: 20),
                ],
                ..._conversation.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: e.key ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: e.key
                              ? figmaOrange.withOpacity(0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: e.key ? Border.all(color: figmaOrange.withOpacity(0.3)) : null,
                        ),
                        child: Text(e.value, style: const TextStyle(height: 1.4)),
                      ),
                    ),
                  ),
                )),
                if (_currentQuestion != null && !_loading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(_currentQuestion!, style: const TextStyle(height: 1.4)),
                        ),
                      ),
                    ),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (_error != null && _conversation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kCardRadius)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 2,
                    minLines: 1,
                    onSubmitted: (_) => _sendAnswer(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _sendAnswer,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: figmaOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
