import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/volunteer_listing.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class CreateOpportunityScreen extends StatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  State<CreateOpportunityScreen> createState() => _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _slotsController = TextEditingController();
  final _firestore = FirestoreService();
  bool _saving = false;
  DateTime? _startTime;
  DateTime? _endTime;
  final List<String> _selectedSkills = [];

  static const _availableSkills = [
    'Teaching',
    'Cooking',
    'Cleaning',
    'Construction',
    'Medical',
    'Counseling',
    'Translation',
    'IT Support',
    'Event Planning',
    'Fundraising',
    'Administration',
    'Transportation',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime?.add(const Duration(hours: 4)) ?? DateTime.now().add(const Duration(hours: 4)),
      firstDate: _startTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now().add(const Duration(hours: 4))),
      );
      if (time != null) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title')),
      );
      return;
    }
    final slots = int.tryParse(_slotsController.text.trim());
    if (slots == null || slots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of slots')),
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create an opportunity')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance.collection('volunteer_listings').doc();
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      final listing = VolunteerListing(
        id: ref.id,
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        organizationId: uid,
        organizationName: FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email,
        skillsRequired: _selectedSkills,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        lat: lat,
        lng: lng,
        startTime: _startTime,
        endTime: _endTime,
        slotsTotal: slots,
        slotsFilled: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.addVolunteerListing(listing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opportunity created')),
        );
        context.go('/opportunities');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final canCreate = auth.appUser?.role == UserRole.ngo || auth.appUser?.role == UserRole.admin;
    if (!canCreate) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Only organizers can create opportunities.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up as an Organizer to create opportunities.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/opportunities'),
                icon: const Icon(Icons.work),
                label: const Text('Browse opportunities'),
                style: FilledButton.styleFrom(backgroundColor: figmaOrange),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Opportunities',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: figmaBlack,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartTime,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _startTime != null
                        ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year} ${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}'
                        : 'Start Time',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndTime,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _endTime != null
                        ? '${_endTime!.day}/${_endTime!.month}/${_endTime!.year} ${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}'
                        : 'End Time',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _slotsController,
            decoration: const InputDecoration(
              labelText: 'Total Slots',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text(
            'Required Skills',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: figmaBlack),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSkills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                selectedColor: figmaOrange.withOpacity(0.2),
                checkmarkColor: figmaOrange,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: figmaPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Create Opportunity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
