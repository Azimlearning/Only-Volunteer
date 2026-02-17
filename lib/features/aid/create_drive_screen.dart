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
  final _qrCodeUrlController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _firestore = FirestoreService();
  bool _saving = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category;
  CampaignCategory? _campaignCategory;
  final _beneficiaryController = TextEditingController();
  String? _currency;
  String? _bank;

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
    _beneficiaryController.dispose();
    _qrCodeUrlController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
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
        campaignCategory: _campaignCategory,
        beneficiaryGroup: _beneficiaryController.text.trim().isEmpty ? null : _beneficiaryController.text.trim(),
        bannerUrl: _bannerUrlController.text.trim().isEmpty ? null : _bannerUrlController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        createdAt: DateTime.now(),
        contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        qrCodeUrl: _qrCodeUrlController.text.trim().isEmpty ? null : _qrCodeUrlController.text.trim(),
        bank: _bank,
        accountName: _accountNameController.text.trim().isEmpty ? null : _accountNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim(),
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
    return Scaffold(
      body: SingleChildScrollView(
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
                  Row(
                    children: [
                      const Text(
                        'Create ',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                      Text(
                        'DonationDrive',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: figmaPurple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Launch a community mission. Your drive will be featured across the OnlyVolunteer network to maximize impact and transparency.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Drive Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Drive Title',
                            hintText: 'Enter Support Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'e.g.; Quantity of Support, Use of Support',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<CampaignCategory>(
                          value: _campaignCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category of Support',
                            hintText: 'Choose One (1)',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: CampaignCategory.disasterRelief, child: Text('Disaster Relief')),
                            DropdownMenuItem(value: CampaignCategory.medicalHealth, child: Text('Medical & Health')),
                            DropdownMenuItem(value: CampaignCategory.communityInfrastructure, child: Text('Community Infrastructure')),
                            DropdownMenuItem(value: CampaignCategory.sustainedSupport, child: Text('Sustained Support')),
                          ],
                          onChanged: (v) => setState(() => _campaignCategory = v),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address of Support Needed',
                            hintText: 'e.g.; Johor Bahru',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your address and contact info will only be shared with the NGO that accepts your request.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Target Amount',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _currency,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                                  DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                                ],
                                onChanged: (v) => setState(() => _currency = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _goalController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column - Payment Method
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _qrCodeUrlController,
                          decoration: const InputDecoration(
                            labelText: 'QR Code',
                            hintText: 'Upload Image',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_upward),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _bank,
                          decoration: const InputDecoration(
                            labelText: 'Bank',
                            hintText: 'Select Bank',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'maybank', child: Text('Maybank')),
                            DropdownMenuItem(value: 'cimb', child: Text('CIMB Bank')),
                            DropdownMenuItem(value: 'public', child: Text('Public Bank')),
                            DropdownMenuItem(value: 'hongleong', child: Text('Hong Leong Bank')),
                            DropdownMenuItem(value: 'rhb', child: Text('RHB Bank')),
                            DropdownMenuItem(value: 'ambank', child: Text('AmBank')),
                            DropdownMenuItem(value: 'uob', child: Text('UOB')),
                            DropdownMenuItem(value: 'ocbc', child: Text('OCBC')),
                          ],
                          onChanged: (v) => setState(() => _bank = v),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _accountNameController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Name of Account',
                            hintText: 'Enter Name of Account',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _accountNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Account Number',
                            hintText: 'Enter Account Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: figmaPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text(
                                  'SUBMIT REQUEST',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
