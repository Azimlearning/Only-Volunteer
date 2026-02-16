import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/donation_drive.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class CreateDriveScreen extends StatefulWidget {
  const CreateDriveScreen({super.key});

  @override
  State<CreateDriveScreen> createState() => _CreateDriveScreenState();
}

class _CreateDriveScreenState extends State<CreateDriveScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _goalController = TextEditingController();
  final _locationController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _firestore = FirestoreService();
  bool _saving = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _goalController.dispose();
    _locationController.dispose();
    _bannerUrlController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate?.add(const Duration(days: 30)) ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title')));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to create a drive')));
      return;
    }
    setState(() => _saving = true);
    try {
      final goal = double.tryParse(_goalController.text.trim());
      final ref = FirebaseFirestore.instance.collection('donation_drives').doc();
      final drive = DonationDrive(
        id: ref.id,
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        ngoId: uid,
        ngoName: FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email,
        goalAmount: goal,
        raisedAmount: 0,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        category: _category,
        bannerUrl: _bannerUrlController.text.trim().isEmpty ? null : _bannerUrlController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        createdAt: DateTime.now(),
        contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );
      await _firestore.addDonationDrive(drive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drive created')));
        context.go('/drives');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              Text('Only organizers can create donation drives.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Sign up as an Organizer to create drives, or browse and join existing drives.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: () => context.go('/drives'), icon: const Icon(Icons.volunteer_activism), label: const Text('Browse drives')),
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
              'Create Donation Drive',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: figmaBlack),
            ),
            const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Drive Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_startDate != null ? _formatDate(_startDate!) : 'Start Date'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_endDate != null ? _formatDate(_endDate!) : 'End Date'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactEmailController,
            decoration: const InputDecoration(
              labelText: 'Contact Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactPhoneController,
            decoration: const InputDecoration(
              labelText: 'Contact Person',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bannerUrlController,
            decoration: const InputDecoration(
              labelText: 'Image Upload (URL)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'disaster_relief', child: Text('Disaster relief')),
              DropdownMenuItem(value: 'community_support', child: Text('Community support')),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _bannerUrlController, decoration: const InputDecoration(labelText: 'Banner image URL (optional)')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_startDate != null ? _formatDate(_startDate!) : 'Start date'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_endDate != null ? _formatDate(_endDate!) : 'End date'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: figmaPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text(
                    'Create Drive',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
