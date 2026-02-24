import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../core/theme.dart';
import '../volunteer/my_activities_screen.dart';
import '../opportunities/my_requests_screen.dart';
import '../analytics/analytics_screen.dart';

enum _ProfileSection { home, personalInfo, myActivity, myRequest, analytics }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileSection _section = _ProfileSection.home;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.appUser;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (user == null || uid == null) {
      return const Center(child: Text('Please sign in to view your profile'));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileSidebar(
          user: user,
          selected: _section,
          onSelect: (s) => setState(() => _section = s),
        ),
        Expanded(
          child: _section == _ProfileSection.myRequest
              ? const Padding(
                  padding: const EdgeInsets.all(24),
                  child: MyRequestsScreen(),
                )
              : _section == _ProfileSection.analytics
                  ? const Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnalyticsScreen(),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _section == _ProfileSection.home
                          ? _ProfileHomeContent(user: user)
                          : _section == _ProfileSection.personalInfo
                              ? _PersonalInfoContent(user: user, uid: uid)
                              : _MyActivityContent(uid: uid),
                    ),
        ),
      ],
    );
  }
}

class _ProfileSidebar extends StatelessWidget {
  const _ProfileSidebar({
    required this.user,
    required this.selected,
    required this.onSelect,
  });

  final AppUser user;
  final _ProfileSection selected;
  final void Function(_ProfileSection) onSelect;

  @override
  Widget build(BuildContext context) {
    const sidebarWidth = 220.0;
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: figmaOrange,
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName?.substring(0, 1).toUpperCase() ?? user.email.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hi, ${user.displayName ?? user.email.split('@').first}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _SidebarTile(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: selected == _ProfileSection.home,
            onTap: () => onSelect(_ProfileSection.home),
          ),
          _SidebarTile(
            icon: Icons.person_outline,
            label: 'Personal Info',
            selected: selected == _ProfileSection.personalInfo,
            onTap: () => onSelect(_ProfileSection.personalInfo),
          ),
          _SidebarTile(
            icon: Icons.event_note,
            label: 'My Activity',
            selected: selected == _ProfileSection.myActivity,
            onTap: () => onSelect(_ProfileSection.myActivity),
          ),
          _SidebarTile(
            icon: Icons.assignment_outlined,
            label: 'My Request',
            selected: selected == _ProfileSection.myRequest,
            onTap: () => onSelect(_ProfileSection.myRequest),
          ),
          _SidebarTile(
            icon: Icons.bar_chart,
            label: 'Analytics',
            selected: selected == _ProfileSection.analytics,
            onTap: () => onSelect(_ProfileSection.analytics),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? figmaOrange.withOpacity(0.15) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: selected ? figmaOrange : Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? figmaOrange : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHomeContent extends StatelessWidget {
  const _ProfileHomeContent({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: figmaOrange,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        user.displayName?.substring(0, 1).toUpperCase() ?? user.email.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? user.email,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: figmaBlack),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: figmaOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppUser.roleDisplayName(user.role),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: figmaOrange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (user.skills.isNotEmpty) ...[
          const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: figmaBlack)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.skills.map((skill) => Chip(
              label: Text(skill),
              backgroundColor: figmaOrange.withOpacity(0.1),
              side: BorderSide(color: figmaOrange.withOpacity(0.3)),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (user.interests.isNotEmpty) ...[
          const Text('Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: figmaBlack)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests.map((interest) => Chip(
              label: Text(interest),
              backgroundColor: figmaPurple.withOpacity(0.1),
              side: BorderSide(color: figmaPurple.withOpacity(0.3)),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: figmaBlack)),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (user.role == UserRole.ngo || user.role == UserRole.admin)
              FilledButton.icon(
                onPressed: () => context.go('/create-drive'),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Create Drive'),
                style: FilledButton.styleFrom(backgroundColor: figmaPurple, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            FilledButton.icon(
              onPressed: () => context.go('/create-opportunity'),
              icon: const Icon(Icons.work_outline, size: 20),
              label: const Text('Create Opportunity'),
              style: FilledButton.styleFrom(backgroundColor: figmaOrange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            ),
            if (user.role == UserRole.admin)
              OutlinedButton.icon(
                onPressed: () => context.go('/developer'),
                icon: const Icon(Icons.science, size: 20),
                label: const Text('Developer'),
                style: OutlinedButton.styleFrom(foregroundColor: figmaPurple, side: BorderSide(color: figmaPurple.withOpacity(0.8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
          ],
        ),
      ],
    );
  }
}

class _PersonalInfoContent extends StatelessWidget {
  const _PersonalInfoContent({required this.user, required this.uid});

  final AppUser user;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack)),
        ),
        const SizedBox(height: 20),
        _ProfileInfoRow(label: 'Name', value: user.displayName ?? '—'),
        _ProfileInfoRow(label: 'Email', value: user.email),
        _ProfileInfoRow(label: 'Role', value: AppUser.roleDisplayName(user.role)),
        _ProfileInfoRow(label: 'Location', value: (user.location != null && user.location!.isNotEmpty) ? user.location! : 'Not set'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _SetLocationButton(uid: uid),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profile coming soon')));
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profile'),
              style: OutlinedButton.styleFrom(foregroundColor: figmaOrange, side: BorderSide(color: figmaOrange.withOpacity(0.8))),
            ),
          ],
        ),
      ],
    );
  }
}

class _SetLocationButton extends StatefulWidget {
  const _SetLocationButton({required this.uid});

  final String uid;

  @override
  State<_SetLocationButton> createState() => _SetLocationButtonState();
}

class _SetLocationButtonState extends State<_SetLocationButton> {
  bool _loading = false;

  Future<void> _showSetLocationOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Use my device location'),
              onTap: () => Navigator.pop(ctx, 'device'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_location_alt),
              title: const Text('Set location manually'),
              onTap: () => Navigator.pop(ctx, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'device') {
      setState(() => _loading = true);
      try {
        final loc = await LocationService.getCurrentLocation();
        if (!mounted) return;
        if (loc != null) {
          await FirestoreService().updateUserFields(widget.uid, {'location': loc.resolvedLocation});
          if (context.mounted) {
            await context.read<AuthNotifier>().refreshAppUser();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location set to ${loc.resolvedLocation}')));
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get device location. Try setting manually.')));
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }
    if (choice == 'manual' && mounted) {
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => _SelectStateDialog(states: malaysianStates),
      );
      if (selected != null && mounted) {
        setState(() => _loading = true);
        try {
          await FirestoreService().updateUserFields(widget.uid, {'location': selected});
          if (context.mounted) {
            await context.read<AuthNotifier>().refreshAppUser();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location set to $selected')));
          }
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _showSetLocationOptions,
      icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.location_on_outlined, size: 18),
      label: Text(_loading ? 'Updating…' : 'Set location'),
      style: OutlinedButton.styleFrom(foregroundColor: figmaOrange, side: BorderSide(color: figmaOrange.withOpacity(0.8))),
    );
  }
}

class _SelectStateDialog extends StatefulWidget {
  const _SelectStateDialog({required this.states});

  final List<String> states;

  @override
  State<_SelectStateDialog> createState() => _SelectStateDialogState();
}

class _SelectStateDialogState extends State<_SelectStateDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select state'),
      content: DropdownButtonFormField<String>(
        value: _selected,
        decoration: const InputDecoration(labelText: 'State'),
        items: widget.states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _selected = v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: figmaBlack))),
        ],
      ),
    );
  }
}

class _MyActivityContent extends StatelessWidget {
  const _MyActivityContent({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [figmaOrange.withOpacity(0.1), figmaPurple.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: figmaBlack)),
                const SizedBox(height: 4),
                Text('Event participation and ongoing events', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const TabBar(
            tabs: [
              Tab(text: 'Event participation'),
              Tab(text: 'Event ongoing'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                EventParticipationTab(uid: uid),
                const Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No ongoing events at the moment. Your active donation drives, volunteering and donation opportunities will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
