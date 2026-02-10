import 'package:flutter/material.dart';
import '../../models/aid_resource.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../core/config.dart';

class AidFinderScreen extends StatefulWidget {
  const AidFinderScreen({super.key});

  @override
  State<AidFinderScreen> createState() => _AidFinderScreenState();
}

class _AidFinderScreenState extends State<AidFinderScreen> {
  final FirestoreService _firestore = FirestoreService();
  final GeminiService _gemini = GeminiService();
  final _searchController = TextEditingController();
  List<AidResource> _list = [];
  List<AidResource> _filtered = [];
  String? _category;
  bool _loading = true;
  String? _contextualHint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _firestore.getAidResources(category: _category);
    setState(() { _list = list; _filtered = list; _loading = false; });
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _list
          : _list.where((r) =>
              (r.title.toLowerCase().contains(q)) ||
              (r.description?.toLowerCase().contains(q) ?? false) ||
              (r.category?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  Future<void> _contextualSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _contextualHint = null);
    final hint = await _gemini.contextualSearch(query, 'volunteer');
    if (mounted) setState(() => _contextualHint = hint);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Search resources...'),
                  onChanged: _filter,
                  onSubmitted: (_) => _contextualSearch(),
                ),
              ),
              if (Config.geminiApiKey.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: _contextualSearch,
                  tooltip: 'AI search tips',
                ),
            ],
          ),
        ),
        if (_contextualHint != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_contextualHint!, style: TextStyle(color: Colors.grey[700]))),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: ['Food', 'Clothing', 'Shelter', 'Medical', 'All'].map((c) {
            final isSelected = _category == (c == 'All' ? null : c);
            return FilterChip(
              label: Text(c),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _category = c == 'All' ? null : c);
                _load();
              },
            );
          }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No resources found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final r = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(r.title),
                            subtitle: Text([r.description, r.category, r.location].whereType<String>().join(' · ')),
                            trailing: r.quantity != null ? Text('${r.quantity} ${r.unit ?? ''}') : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
