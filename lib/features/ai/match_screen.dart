import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/volunteer_listing.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../core/theme.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final FirestoreService _firestore = FirestoreService();
  final GeminiService _gemini = GeminiService();
  List<VolunteerListing> _matched = [];
  bool _loading = true;
  String? _error;
  List<String> _skills = [];
  List<String> _interests = [];
  final _skillInput = TextEditingController();
  final _interestInput = TextEditingController();
  final _availabilityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAndMatch();
  }

  @override
  void dispose() {
    _skillInput.dispose();
    _interestInput.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndMatch() async {
    setState(() { _loading = true; _error = null; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _error = 'Sign in to get matched'; _loading = false; });
      return;
    }
    try {
      final user = await _firestore.getUser(uid);
      if (user != null) {
        _skills = List.from(user.skills);
        _interests = List.from(user.interests);
        if (_availabilityController.text.isEmpty) _availabilityController.text = '';
      }
      await _runMatch(uid);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _runMatch(String uid) async {
    try {
      var user = await _firestore.getUser(uid);
      user = user ?? AppUser(uid: uid, email: FirebaseAuth.instance.currentUser?.email ?? '');
      final updatedUser = AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        role: user.role,
        skills: _skills,
        interests: _interests,
        points: user.points,
        badges: user.badges,
        createdAt: user.createdAt,
      );
      await _firestore.setUser(updatedUser);
      final listings = await _firestore.getVolunteerListings();
      final ids = await _gemini.matchListingsForUser(updatedUser, listings);
      final idSet = ids.toSet();
      final ordered = <VolunteerListing>[];
      for (final id in ids) {
        final found = listings.cast<VolunteerListing?>().firstWhere((e) => e?.id == id, orElse: () => null);
        if (found != null) ordered.add(found);
      }
      for (final l in listings) {
        if (!idSet.contains(l.id)) ordered.add(l);
      }
      if (mounted) {
        Provider.of<AuthNotifier>(context, listen: false).refreshAppUser();
        setState(() { _matched = ordered; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _saveProfileAndMatch() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    await _runMatch(uid);
  }

  void _addSkill() {
    final s = _skillInput.text.trim();
    if (s.isNotEmpty && !_skills.contains(s)) setState(() { _skills.add(s); _skillInput.clear(); });
  }

  void _addInterest() {
    final s = _interestInput.text.trim();
    if (s.isNotEmpty && !_interests.contains(s)) setState(() { _interests.add(s); _interestInput.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Match Me',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find opportunities that match your skills and interests',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Your profile for matching', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Skills', style: TextStyle(fontWeight: FontWeight.w500)),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ..._skills.map((s) => Chip(label: Text(s), onDeleted: () => setState(() => _skills.remove(s)))),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _skillInput,
                      decoration: const InputDecoration(isDense: true, hintText: 'Add skill'),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  IconButton(onPressed: _addSkill, icon: const Icon(Icons.add)),
                ]),
                const SizedBox(height: 12),
                const Text('Interests', style: TextStyle(fontWeight: FontWeight.w500)),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ..._interests.map((s) => Chip(label: Text(s), onDeleted: () => setState(() => _interests.remove(s)))),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _interestInput,
                      decoration: const InputDecoration(isDense: true, hintText: 'Add interest'),
                      onSubmitted: (_) => _addInterest(),
                    ),
                  ),
                  IconButton(onPressed: _addInterest, icon: const Icon(Icons.add)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _availabilityController,
                  decoration: const InputDecoration(labelText: 'Availability (e.g. Weekends, Mon-Fri)'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _saveProfileAndMatch,
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save & find matches'),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                if (_matched.isNotEmpty) ...[
                  Text('Best matches for you', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._matched.take(10).map((l) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(l.title),
                      subtitle: Text('${l.organizationName ?? ""} · ${l.location ?? ""}'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => context.go('/opportunities'),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
