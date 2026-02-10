import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_user.dart';
import '../../models/volunteer_listing.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';

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

  @override
  void initState() {
    super.initState();
    _runMatch();
  }

  Future<void> _runMatch() async {
    setState(() { _loading = true; _error = null; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _error = 'Sign in to get matched'; _loading = false; });
      return;
    }
    try {
      final user = await _firestore.getUser(uid);
      final appUser = user ?? AppUser(uid: uid, email: FirebaseAuth.instance.currentUser?.email ?? '');
      final listings = await _firestore.getVolunteerListings();
      final ids = await _gemini.matchListingsForUser(appUser, listings);
      final idSet = ids.toSet();
      final ordered = <VolunteerListing>[];
      for (final id in ids) {
        VolunteerListing? found;
        for (final e in listings) if (e.id == id) { found = e; break; }
        if (found != null) ordered.add(found);
      }
      for (final l in listings) {
        if (!idSet.contains(l.id)) ordered.add(l);
      }
      if (mounted) setState(() { _matched = ordered; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _runMatch, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_matched.isEmpty) {
      return const Center(child: Text('No opportunities available. Check back later.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Best matches for you',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _matched.length,
            itemBuilder: (_, i) {
              final l = _matched[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(l.title),
                  subtitle: Text('${l.organizationName ?? ""} · ${l.location ?? ""}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => context.go('/opportunities'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
