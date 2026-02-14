import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _locationFilterController = TextEditingController();
  List<AidResource> _list = [];
  List<AidResource> _filtered = [];
  String? _category;
  String? _urgencyFilter;
  bool _loading = true;
  String? _contextualHint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _firestore.getAidResources(category: _category, urgency: _urgencyFilter);
    setState(() { _list = list; _filtered = list; _loading = false; });
    _applyLocationFilter();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _list.where((r) {
        final matchText = q.isEmpty ||
            (r.title.toLowerCase().contains(q)) ||
            (r.description?.toLowerCase().contains(q) ?? false) ||
            (r.category?.toLowerCase().contains(q) ?? false);
        if (!matchText) return false;
        final loc = _locationFilterController.text.trim().toLowerCase();
        if (loc.isEmpty) return true;
        return r.location?.toLowerCase().contains(loc) ?? false;
      }).toList();
    });
  }

  void _applyLocationFilter() {
    _filter(_searchController.text);
  }

  Future<void> _contextualSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _contextualHint = null);
    final hint = await _gemini.contextualSearch(query, 'volunteer');
    if (mounted) setState(() => _contextualHint = hint);
  }

  void _openSubmitAidRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SubmitAidRequestSheet(
        onSubmitted: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openSubmitAidRequest,
        child: const Icon(Icons.add),
        tooltip: 'Submit aid request',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
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
                const SizedBox(height: 8),
                TextField(
                  controller: _locationFilterController,
                  decoration: const InputDecoration(hintText: 'Filter by location', prefixIcon: Icon(Icons.location_on, size: 20)),
                  onChanged: (_) => _applyLocationFilter(),
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
              runSpacing: 8,
              children: [
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500)),
                ...['Food', 'Clothing', 'Shelter', 'Medical', 'All'].map((c) {
                  final isSelected = _category == (c == 'All' ? null : c);
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FilterChip(
                      label: Text(c),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _category = c == 'All' ? null : c);
                        _load();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Urgency:', style: TextStyle(fontWeight: FontWeight.w500)),
                ...['low', 'medium', 'high', 'critical'].map((u) {
                  final isSelected = _urgencyFilter == u;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FilterChip(
                      label: Text(u),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _urgencyFilter = isSelected ? null : u);
                        _load();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
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
                              subtitle: Text([
                                r.description,
                                r.category,
                                r.location,
                                'Urgency: ${r.urgency.name}',
                              ].whereType<String>().join(' · ')),
                              trailing: r.quantity != null ? Text('${r.quantity} ${r.unit ?? ''}') : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SubmitAidRequestSheet extends StatefulWidget {
  const _SubmitAidRequestSheet({required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<_SubmitAidRequestSheet> createState() => _SubmitAidRequestSheetState();
}

class _SubmitAidRequestSheetState extends State<_SubmitAidRequestSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String? _category;
  AidUrgency _urgency = AidUrgency.medium;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title')));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance.collection('aid_resources').doc();
      final resource = AidResource(
        id: ref.id,
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        category: _category,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        urgency: _urgency,
        ownerId: uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await FirestoreService().addAidResource(resource);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aid request submitted')));
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Submit aid request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title *')),
            const SizedBox(height: 12),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Food', 'Clothing', 'Shelter', 'Medical'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 12),
            DropdownButtonFormField<AidUrgency>(
              value: _urgency,
              decoration: const InputDecoration(labelText: 'Urgency'),
              items: AidUrgency.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
              onChanged: (v) => setState(() => _urgency = v ?? AidUrgency.medium),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
