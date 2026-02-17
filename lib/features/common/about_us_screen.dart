import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  figmaOrange.withOpacity(0.1),
                  figmaPurple.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/onlyvolunteer_logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: figmaOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.volunteer_activism, size: 60, color: figmaOrange),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'About OnlyVolunteer',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: figmaBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bridging resource abundance and immediate need',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Mission Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Our Mission',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: figmaBlack,
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
              ],
            ),
          ),
          // Core Pages Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Our Core Features',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: figmaBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore our main features and learn how to make the most of OnlyVolunteer',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                _CorePageCard(
                  icon: Icons.search,
                  title: 'Aid Finder',
                  description: 'Find or provide essential resources in your area. Use the search bar to filter by category (Food, Clothing, Medical, Shelter, Education, Hygiene, Transport). Browse aid resources on the left panel and view their locations on the interactive map. Click on any resource card to see details like operating hours, eligibility requirements, and contact options. Use the "Message" button to contact the provider or "Map" button to get directions.',
                  color: figmaOrange,
                  onTap: () => context.go('/finder'),
                ),
                const SizedBox(height: 24),
                _CorePageCard(
                  icon: Icons.volunteer_activism,
                  title: 'Donation Drives',
                  description: 'Browse active donation campaigns and contribute to causes that matter. Each drive card shows the campaign goal, amount raised, and progress bar. Filter drives by category (Disaster Relief, Medical & Health, Community Infrastructure, Sustained Support) or campaign type. Click on any drive to view detailed information including wishlist items, beneficiary groups, and organizer details. Use the "Donate Now" button to contribute or "Message" to contact the organizer.',
                  color: figmaPurple,
                  onTap: () => context.go('/drives'),
                ),
                const SizedBox(height: 24),
                _CorePageCard(
                  icon: Icons.work,
                  title: 'Opportunities',
                  description: 'Discover volunteer opportunities and micro-donation requests. Toggle between "All", "Volunteering", and "Donations" filters to find what interests you. Browse opportunities in a grid layout showing images, descriptions, locations, and available slots. Click "Apply" on volunteer opportunities to join, or "Fulfill" on donation requests to help someone in need. Use the + button to post your own opportunity or donation request.',
                  color: figmaOrange,
                  onTap: () => context.go('/opportunities'),
                ),
                const SizedBox(height: 24),
                _CorePageCard(
                  icon: Icons.auto_awesome,
                  title: 'Match Me',
                  description: 'Get personalized recommendations based on your skills, interests, and location. The AI-powered matching system analyzes your profile and suggests volunteer opportunities and donation drives that align with your capabilities. Review the matched opportunities and apply directly from the results. Update your skills and interests in your profile to get better matches.',
                  color: figmaPurple,
                  onTap: () => context.go('/match'),
                ),
                const SizedBox(height: 24),
                _CorePageCard(
                  icon: Icons.event,
                  title: 'My Activities',
                  description: 'Track your volunteering journey and impact. View your attendance records showing check-in/check-out times and verified volunteer hours. Browse your earned e-certificates that you can download and share. Review your donation history with amounts contributed and dates. Use the "Download report" button to generate a PDF summary of all your activities for records or applications.',
                  color: figmaOrange,
                  onTap: () => context.go('/my-activities'),
                ),
                const SizedBox(height: 24),
                _CorePageCard(
                  icon: Icons.list_alt,
                  title: 'My Requests',
                  description: 'Manage your micro-donation requests. View all requests you\'ve posted, including their status (open, fulfilled, closed). See which requests have been fulfilled by generous donors. Create new requests by specifying the item needed, category, location, and description. Edit or delete your requests as needed. This feature helps you get the specific help you need from the community.',
                  color: figmaPurple,
                  onTap: () => context.go('/my-requests'),
                ),
                const SizedBox(height: 24),
                _CorePageCard(
                  icon: Icons.chat,
                  title: 'AI Chatbot',
                  description: 'Get instant help and answers using our AI-powered chatbot. Ask questions about how to use features, find opportunities, create drives, or get general information about OnlyVolunteer. The chatbot can help you navigate the platform, explain features, and guide you through common tasks. Powered by Google Gemini AI for accurate and helpful responses.',
                  color: figmaOrange,
                  onTap: () => context.go('/chatbot'),
                ),
              ],
            ),
          ),
          // How It Works Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How It Works',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: figmaBlack,
                  ),
                ),
                const SizedBox(height: 32),
                _StepCard(
                  number: '1',
                  title: 'Sign Up',
                  description: 'Create your account and tell us about your interests, skills, and needs.',
                  color: figmaOrange,
                ),
                const SizedBox(height: 24),
                _StepCard(
                  number: '2',
                  title: 'Explore',
                  description: 'Browse opportunities, donation drives, and aid resources in your area.',
                  color: figmaPurple,
                ),
                const SizedBox(height: 24),
                _StepCard(
                  number: '3',
                  title: 'Connect',
                  description: 'Apply for opportunities, fulfill donation requests, or request aid when you need it.',
                  color: figmaOrange,
                ),
                const SizedBox(height: 24),
                _StepCard(
                  number: '4',
                  title: 'Track',
                  description: 'Monitor your volunteer hours, donations, and impact through our tracking system.',
                  color: figmaPurple,
                ),
              ],
            ),
          ),
          // Contact Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get In Touch',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: figmaBlack,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Have questions or need support? We\'re here to help.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact feature coming soon')),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Contact Us'),
                  style: FilledButton.styleFrom(
                    backgroundColor: figmaOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

class _CorePageCard extends StatelessWidget {
  const _CorePageCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
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
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: figmaBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: onTap,
                      icon: Icon(Icons.arrow_forward, size: 16, color: color),
                      label: Text(
                        'Try it now',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.color,
  });

  final String number;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: figmaBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
