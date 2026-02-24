import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  LANDING PAGE — REDESIGNED (see landing_page_improvements.md & card_ui_recommendations.md)
//  - Hero: gradient bg, icon mosaic (no grey placeholder), strong typography, dual CTA
//  - Stats bar: social proof numbers
//  - Services: icon cards, mainAxisSize.min (no empty space), Track button in header (navy)
//  - CTA banner above footer; footer with links
// ═══════════════════════════════════════════════════════════════════════════

// ─── Tokens ──────────────────────────────────────────────────────────────────
class _T {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  static const double rSm = 8;
  static const double rMd = 12;
  static const double rLg = 16;
  static const double rXl = 24;

  static const Color bg = Color(0xFFFAF8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFE8600A);
  static const Color primaryDark = Color(0xFFB84A00);
  static const Color accent = Color(0xFF1A1A2E);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color text1 = Color(0xFF1A1A1A);
  static const Color text2 = Color(0xFF555555);
  static const Color text3 = Color(0xFF999999);
  static const Color heroBg1 = Color(0xFFFFF4EE);
  static const Color heroBg2 = Color(0xFFFFECDF);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3)),
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 3, offset: const Offset(0, 1)),
      ];
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _T.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: _T.s4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _T.text2,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(color: _T.borderLight),
          boxShadow: _T.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_T.rLg),
          child: Padding(
            padding: const EdgeInsets.all(_T.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(_T.rMd),
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(height: _T.s16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _T.text1,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: _T.s8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _T.text2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: _T.s16),
                Row(
                  children: [
                    Text(
                      'Check out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _T.primary,
                      ),
                    ),
                    const SizedBox(width: _T.s4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: _T.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(),
            _ServicesSection(),
            _CtaBanner(),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_T.heroBg1, _T.heroBg2, Color(0xFFFFF9F6)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(_T.s32, _T.s48, _T.s32, _T.s48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Turn every act\ninto a quest.',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: _T.text1,
                    height: 1.15,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: _T.s20),
                const Text(
                  'Be the hero your community needs.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _T.primary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: _T.s16),
                const Text(
                  'OnlyVolunteer bridges resource abundance and immediate\nneed. Find opportunities, donate, or get support.',
                  style: TextStyle(fontSize: 15, color: _T.text2, height: 1.6),
                ),
                const SizedBox(height: _T.s32),
                Row(
                  children: [
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => context.go('/opportunities'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _T.primary,
                          padding: const EdgeInsets.symmetric(horizontal: _T.s24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_T.rMd),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text('Get Started', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(width: _T.s8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: _T.s12),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.go('/opportunities'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _T.text1,
                          side: const BorderSide(color: _T.borderLight, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: _T.s24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_T.rMd),
                          ),
                        ),
                        child: const Text('Learn More', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: _T.s48),
          const Expanded(
            flex: 4,
            child: _HeroVisual(),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  static const _items = [
    (Icons.volunteer_activism, 'Aid Finder', Color(0xFFE8600A), Color(0xFFFFF0E8)),
    (Icons.favorite_rounded, 'Donation Drive', Color(0xFF1565C0), Color(0xFFE3F2FD)),
    (Icons.handshake_outlined, 'Opportunities', Color(0xFF2E7D32), Color(0xFFE8F5E9)),
    (Icons.people_alt_outlined, 'Match Me', Color(0xFF6A1B9A), Color(0xFFF3E5F5)),
  ];

  const _HeroVisual();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(_T.s24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: _T.primary.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _HeroTile(_items[0])),
                const SizedBox(width: _T.s12),
                Expanded(child: _HeroTile(_items[1])),
              ],
            ),
            const SizedBox(height: _T.s12),
            Row(
              children: [
                Expanded(child: _HeroTile(_items[2])),
                const SizedBox(width: _T.s12),
                Expanded(child: _HeroTile(_items[3])),
              ],
            ),
          ],
        ),
      );
}

class _HeroTile extends StatelessWidget {
  final (IconData, String, Color, Color) data;

  const _HeroTile(this.data);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(_T.s16),
        decoration: BoxDecoration(
          color: data.$4,
          borderRadius: BorderRadius.circular(_T.rLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.$1, size: 28, color: data.$3),
            const SizedBox(height: _T.s8),
            Text(
              data.$2,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: data.$3),
            ),
          ],
        ),
      );
}

class _ServicesSection extends StatelessWidget {
  static final _services = [
    (
      Icons.search_rounded,
      'Aid Finder',
      'Locate nearby aid resources or drop off donations for those in need.',
      Color(0xFFFFF0E8),
      Color(0xFFE8600A),
      '/finder',
    ),
    (
      Icons.volunteer_activism,
      'Donation Drive',
      'Targeted aid for urgent causes. Find a drive and make your impact count.',
      Color(0xFFE3F2FD),
      Color(0xFF1565C0),
      '/drives',
    ),
    (
      Icons.work_outline_rounded,
      'Opportunities',
      'Turn your skills into impact. Find volunteer opportunities that match you.',
      Color(0xFFE8F5E9),
      Color(0xFF2E7D32),
      '/opportunities',
    ),
    (
      Icons.people_alt_outlined,
      'Match Me',
      'AI matches your skills with nearby needs. Discover where you fit best.',
      Color(0xFFF3E5F5),
      Color(0xFF6A1B9A),
      '/match',
    ),
    (
      Icons.smart_toy_outlined,
      'AI Chatbot',
      'Get instant answers about aid resources, eligibility, and next steps.',
      Color(0xFFFFF8E1),
      Color(0xFFF57F17),
      '/chatbot',
    ),
    (
      Icons.notifications_outlined,
      'Alerts',
      'Stay notified of urgent needs and new opportunities near your area.',
      Color(0xFFFFEBEE),
      Color(0xFFC62828),
      '/alerts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_T.s32, _T.s48, _T.s32, _T.s48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: _T.s12, vertical: _T.s4),
                    decoration: BoxDecoration(
                      color: _T.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_T.rXl),
                    ),
                    child: Text(
                      'Our Services',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _T.primary),
                    ),
                  ),
                  const SizedBox(height: _T.s12),
                  const Text(
                    'Four pillars of community support',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _T.text1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: _T.s8),
                  const Text(
                    'Aid, donate, volunteer, match — all in one place.',
                    style: TextStyle(fontSize: 15, color: _T.text2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: _T.s32),
          _ServicesGrid(services: _services),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final List<(IconData, String, String, Color, Color, String)> services;

  const _ServicesGrid({required this.services});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < services.length; i += 3)
          Padding(
            padding: const EdgeInsets.only(bottom: _T.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int j = i; j < (i + 3).clamp(0, services.length); j++) ...[
                  if (j > i) const SizedBox(width: _T.s16),
                  Expanded(
                    child: _ServiceCard(
                      icon: services[j].$1,
                      title: services[j].$2,
                      description: services[j].$3,
                      iconBg: services[j].$4,
                      iconColor: services[j].$5,
                      onTap: () => context.go(services[j].$6),
                    ),
                  ),
                ],
                for (int k = services.length; k < i + 3; k++) ...[
                  const SizedBox(width: _T.s16),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CtaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(_T.s32, 0, _T.s32, _T.s48),
        padding: const EdgeInsets.all(_T.s48),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_T.primary, _T.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_T.rXl),
          boxShadow: [
            BoxShadow(color: _T.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ready to make a difference?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: _T.s12),
                  Text(
                    'Join thousands of volunteers already creating impact in their communities.',
                    style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _T.s48),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => context.go('/opportunities'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _T.primary,
                  padding: const EdgeInsets.symmetric(horizontal: _T.s32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.rMd)),
                ),
                child: const Text(
                  'Join Now — It\'s Free',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Footer extends StatelessWidget {
  static const _links = [
    ('Home', '/home'),
    ('Aid Finder', '/finder'),
    ('Donation Drives', '/drives'),
    ('Opportunities', '/opportunities'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: _T.accent,
        padding: const EdgeInsets.symmetric(horizontal: _T.s32, vertical: _T.s24),
        child: Row(
          children: [
            const Text(
              'OnlyVolunteer',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
            ),
            const Spacer(),
            const Text(
              '© 2026 OnlyVolunteer',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(width: _T.s24),
            for (final e in _links)
              Padding(
                padding: const EdgeInsets.only(left: _T.s16),
                child: InkWell(
                  onTap: () => context.go(e.$2),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Text(
                      e.$1,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}