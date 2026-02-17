import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final canManage = auth.appUser?.role == UserRole.ngo || auth.appUser?.role == UserRole.admin;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Section - Split layout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            color: Colors.white,
            child: Row(
              children: [
                // Left side - Text content
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Turn every act into a quest.',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: figmaBlack,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Be the hero your community needs.',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: figmaBlack,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'OnlyVolunteer is a unified ecosystem designed to bridge resource abundance and immediate need. Whether you\'re a student seeking opportunities, a family in need of support, or a volunteer ready to make a difference, we connect you with the right resources at the right time.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () => context.go('/about-us'),
                        style: FilledButton.styleFrom(
                          backgroundColor: figmaOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text(
                          'ABOUT US',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                // Right side - Image placeholder
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(Icons.people, size: 120, color: Colors.grey[400]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Feature Cards Section - 2x2 Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Feature Cards (2x2 grid)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.1,
                        children: [
                          _FeatureCard(
                            title: 'AidFinder',
                            description: 'Find or provide essential resources. Locate nearby Aid to receive support or drop off your donations.',
                            onTap: () => context.go('/finder'),
                          ),
                          _FeatureCard(
                            title: 'DonationDrive',
                            description: 'Targeted aid for urgent causes. Find a drive, check the wishlist, and make your impact count.',
                            onTap: () => context.go('/drives'),
                          ),
                          _FeatureCard(
                            title: 'Opportunities',
                            description: 'Turn your skills into impact. Find volunteer opportunities that match your skills.',
                            onTap: () => context.go('/opportunities'),
                          ),
                          _FeatureCard(
                            title: 'MatchMe',
                            description: 'Match your skills with nearby needs. Discover opportunities that align with your passion and purpose.',
                            onTap: () => context.go('/match'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                // Right side - Our Services
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Our Services',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: figmaBlack,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'OnlyVolunteer is built on four distinct pillars of community support. Whether you need immediate aid, want to donate, or are looking to volunteer, we\'re here to help.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () => context.go('/my-activities'),
                        style: FilledButton.styleFrom(
                          backgroundColor: figmaPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text(
                          'TRACK YOUR EXPERIENCE',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer - Only visible when scrolled to bottom
          _LandingPageFooter(),
        ],
      ),
    );
  }
}

class _LandingPageFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Home', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/finder'),
                  child: const Text('Aid Finder', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/drives'),
                  child: const Text('Donation Drives', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/opportunities'),
                  child: const Text('Opportunities', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 OnlyVolunteer. All rights reserved.',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy coming soon')),
                    );
                  },
                  child: Text('Privacy Policy', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of Service coming soon')),
                    );
                  },
                  child: Text('Terms of Service', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact feature coming soon')),
                    );
                  },
                  child: Text('Contact Us', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: figmaBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: figmaBlack,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: figmaOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'CHECK OUT',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
