import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/volunteer_listing.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class RequestSupportScreen extends StatefulWidget {
  const RequestSupportScreen({super.key});

  @override
  State<RequestSupportScreen> createState() => _RequestSupportScreenState();
}

class _RequestSupportScreenState extends State<RequestSupportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _firestore = FirestoreService();
  bool _saving = false;
  String? _category;
  String? _urgency;
  RequestVisibility _visibility = RequestVisibility.public;
  bool? _isRegisteredWithJKM;
  bool _isB40Household = false;
  bool _infoCorrect = false;
  bool _acceptsMonetaryDonation = false;
  final _monetaryGoalController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _qrCodeUrlController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  String? _bank;

  static const _bankOptions = [
    {'value': 'maybank', 'label': 'Maybank'},
    {'value': 'cimb', 'label': 'CIMB Bank'},
    {'value': 'public', 'label': 'Public Bank'},
    {'value': 'hongleong', 'label': 'Hong Leong Bank'},
    {'value': 'rhb', 'label': 'RHB Bank'},
    {'value': 'ambank', 'label': 'AmBank'},
    {'value': 'uob', 'label': 'UOB'},
    {'value': 'ocbc', 'label': 'OCBC'},
  ];

  static const _categories = [
    'Food',
    'Clothing',
    'Shelter',
    'Medical',
    'Education',
    'Hygiene',
    'Transport',
    'Other',
  ];

  static const _urgencyLevels = ['low', 'medium', 'high', 'critical'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _monetaryGoalController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _qrCodeUrlController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a support title')));
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }
    if (_urgency == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select urgency level')));
      return;
    }
    if (_isRegisteredWithJKM == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please indicate if you are registered with JKM or NGO')));
      return;
    }
    if (!_isB40Household) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please confirm B40 household declaration')));
      return;
    }
    if (!_infoCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please confirm information is correct')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to submit a request')));
      return;
    }

    setState(() => _saving = true);
    try {
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      final ref = FirebaseFirestore.instance.collection('volunteer_listings').doc();
      
      // Create a volunteer opportunity from the request
      final monetaryGoal = _acceptsMonetaryDonation && _monetaryGoalController.text.trim().isNotEmpty
          ? double.tryParse(_monetaryGoalController.text.trim())
          : null;
      final contactEmail = _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim();
      final contactPhone = _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim();
      final qrCodeUrl = _acceptsMonetaryDonation ? (_qrCodeUrlController.text.trim().isEmpty ? null : _qrCodeUrlController.text.trim()) : null;
      final bank = _acceptsMonetaryDonation ? _bank : null;
      final accountName = _acceptsMonetaryDonation ? (_accountNameController.text.trim().isEmpty ? null : _accountNameController.text.trim()) : null;
      final accountNumber = _acceptsMonetaryDonation ? (_accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim()) : null;

      final listing = VolunteerListing(
        id: ref.id,
        title: title,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        organizationId: null, // Request-based, not NGO-created
        organizationName: _visibility == RequestVisibility.private ? 'Anonymous Requester' : (FirebaseAuth.instance.currentUser?.displayName ?? 'Individual Requester'),
        skillsRequired: [_category!],
        location: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        lat: lat,
        lng: lng,
        slotsTotal: 1, // One request = one opportunity
        slotsFilled: 0,
        createdAt: DateTime.now(),
        visibility: _visibility,
        isRegisteredWithJKM: _isRegisteredWithJKM,
        isB40Household: _isB40Household,
        acceptsMonetaryDonation: _acceptsMonetaryDonation,
        monetaryGoal: monetaryGoal,
        monetaryRaised: 0,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        qrCodeUrl: qrCodeUrl,
        bank: bank,
        accountName: accountName,
        accountNumber: accountNumber,
      );
      
      await _firestore.addVolunteerListing(listing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_visibility == RequestVisibility.public 
            ? 'Request submitted! It will appear in the Opportunities page.'
            : 'Request submitted privately! Only verified NGOs can see it.'),
          backgroundColor: Colors.green,
        ));
        context.go('/opportunities');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      Text(
                        'Request',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: figmaPurple),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Support',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: figmaBlack),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Need a hand? We\'ve got you. Request essential resources privately and securely.',
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
                  // Left Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Support Title *',
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
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category of Support *',
                            hintText: 'Choose One (1)',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _category = v),
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
                          'Contact',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Contact email (optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Contact phone (optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _urgency,
                          decoration: const InputDecoration(
                            labelText: 'Urgency *',
                            hintText: 'Choose One (1)',
                            border: OutlineInputBorder(),
                          ),
                          items: _urgencyLevels.map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase()))).toList(),
                          onChanged: (v) => setState(() => _urgency = v),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Accept monetary donations (cash)'),
                          subtitle: const Text('Allow supporters to donate money instead of items'),
                          value: _acceptsMonetaryDonation,
                          onChanged: (v) => setState(() => _acceptsMonetaryDonation = v ?? false),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_acceptsMonetaryDonation) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _monetaryGoalController,
                            decoration: const InputDecoration(
                              labelText: 'Monetary Goal (RM)',
                              hintText: 'e.g.; 500',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _qrCodeUrlController,
                            decoration: const InputDecoration(
                              labelText: 'QR Code URL (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _bank,
                            decoration: const InputDecoration(
                              labelText: 'Bank',
                              hintText: 'Select Bank',
                              border: OutlineInputBorder(),
                            ),
                            items: _bankOptions
                                .map((b) => DropdownMenuItem(value: b['value'], child: Text(b['label']!)))
                                .toList(),
                            onChanged: (v) => setState(() => _bank = v),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _accountNameController,
                            decoration: const InputDecoration(
                              labelText: 'Account name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _accountNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Account number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Request Visibility',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<RequestVisibility>(
                          title: const Text('Public'),
                          subtitle: const Text('Request will be posted in the Opportunities page'),
                          value: RequestVisibility.public,
                          groupValue: _visibility,
                          onChanged: (v) => setState(() => _visibility = v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<RequestVisibility>(
                          title: const Text('Private'),
                          subtitle: const Text('Request will only be shown to verified NGOs and trusted community leaders'),
                          value: RequestVisibility.private,
                          groupValue: _visibility,
                          onChanged: (v) => setState(() => _visibility = v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Are you currently registered with JKM or any other NGO? *',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<bool>(
                          title: const Text('Yes'),
                          value: true,
                          groupValue: _isRegisteredWithJKM,
                          onChanged: (v) => setState(() => _isRegisteredWithJKM = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<bool>(
                          title: const Text('No'),
                          value: false,
                          groupValue: _isRegisteredWithJKM,
                          onChanged: (v) => setState(() => _isRegisteredWithJKM = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Declarations',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text('I declare that my household income is below RM4,850 (B40). *'),
                          value: _isB40Household,
                          onChanged: (v) => setState(() => _isB40Household = v ?? false),
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('I declare all the information is correct. *'),
                          value: _infoCorrect,
                          onChanged: (v) => setState(() => _infoCorrect = v ?? false),
                          contentPadding: EdgeInsets.zero,
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
}
