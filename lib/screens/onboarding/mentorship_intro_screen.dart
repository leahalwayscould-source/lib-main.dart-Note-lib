import 'package:flutter/material.dart';
import '../../models/artist_user.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_progress_service.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/brand_mark.dart';
import '../home/home_screen.dart';

class MentorshipIntroScreen extends StatefulWidget {
  const MentorshipIntroScreen({
    super.key,
    required this.userId,
    this.primaryMedium,
    required this.careerLevel,
  });

  final String userId;
  final String? primaryMedium;
  final String careerLevel;

  @override
  State<MentorshipIntroScreen> createState() => _MentorshipIntroScreenState();
}

class _MentorshipIntroScreenState extends State<MentorshipIntroScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  final AuthService _authService = AuthService();
  final OnboardingProgressService _progressService =
      OnboardingProgressService();
  late final Future<List<_Mentor>> _mentorsFuture;

  @override
  void initState() {
    super.initState();
    _mentorsFuture = _loadMentors();
  }

  Future<List<_Mentor>> _loadMentors() async {
    try {
      final artists = await _authService.getPotentialMentors(
        excludeUserId: widget.userId,
        limit: 3,
      );
      final mentors = _buildLiveMentors(
        artists: artists,
        level: widget.careerLevel,
        medium: widget.primaryMedium,
      );

      if (mentors.isNotEmpty) {
        return mentors;
      }
    } catch (_) {
      // Fall through to curated fallback below.
    }

    return _mentorsForLevel(widget.careerLevel, widget.primaryMedium);
  }

  Future<void> _connectMentor(_Mentor mentor) async {
    try {
      await _onboardingService.recordMentorSelection(
        userId: widget.userId,
        mentorName: mentor.name,
        careerLevel: widget.careerLevel,
        primaryMedium: widget.primaryMedium,
      );
    } catch (_) {
      // Never block onboarding when persistence fails.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${mentor.name} to your mentor list.')),
    );
  }

  Future<void> _joinCircle(String title) async {
    try {
      await _onboardingService.recordCircleJoin(
        userId: widget.userId,
        circleTitle: title,
        careerLevel: widget.careerLevel,
      );
    } catch (_) {
      // Never block onboarding when persistence fails.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Circle invite sent.')),
    );
  }

  Future<void> _goHome() async {
    try {
      await _progressService.setStage(widget.userId, OnboardingStage.completed);
      await _onboardingService.logEvent(
        userId: widget.userId,
        eventType: 'onboarding_finished',
      );
    } catch (_) {
      // Never block onboarding when persistence fails.
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1016), Color(0xFF1A1322), Color(0xFF101C27)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<_Mentor>>(
            future: _mentorsFuture,
            builder: (context, snapshot) {
              final mentors = snapshot.data ??
                  _mentorsForLevel(widget.careerLevel, widget.primaryMedium);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                        child: BrandMark(size: 28, showWordmark: false)),
                    const SizedBox(height: 16),
                    const Center(child: _StepDots(currentStep: 4)),
                    const SizedBox(height: 24),
                    Text(
                      'Minutes 7-10',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFD46FCF),
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Want guidance from artists\nwho\'ve been where you are?',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick one path now. You can always switch later.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8EA0B3),
                            height: 1.45,
                          ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    const SizedBox(height: 18),
                    ...mentors.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MentorCard(
                            mentor: m,
                            onConnect: _connectMentor,
                          ),
                        )),
                    const SizedBox(height: 10),
                    _CircleCard(
                      title: _circleTitle(widget.careerLevel),
                      subtitle:
                          'Weekly accountability, critique prompts, and live check-ins with peers at your stage.',
                      onJoin: _joinCircle,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _goHome,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Finish onboarding and enter app'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _goHome,
                        child: const Text('I\'ll choose mentorship later'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({
    required this.mentor,
    required this.onConnect,
  });

  final _Mentor mentor;
  final Future<void> Function(_Mentor mentor) onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151D28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF273647)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: mentor.accent.withValues(alpha: 0.2),
            backgroundImage: mentor.avatarUrl.isNotEmpty
                ? NetworkImage(mentor.avatarUrl)
                : null,
            child: mentor.avatarUrl.isEmpty
                ? Text(
                    mentor.name.substring(0, 1),
                    style: TextStyle(
                      color: mentor.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentor.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mentor.specialty,
                  style: const TextStyle(
                    color: Color(0xFF9EB2C7),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mentor.proof,
                  style: const TextStyle(
                    color: Color(0xFF7F93A8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => onConnect(mentor),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    required this.title,
    required this.subtitle,
    required this.onJoin,
  });

  final String title;
  final String subtitle;
  final Future<void> Function(String title) onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1624),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF43395A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.groups_2_outlined, color: Color(0xFFD46FCF), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Or join a mentorship circle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE4D8F0),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF9C8FB4),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onJoin(title),
            icon: const Icon(Icons.group_add_outlined, size: 18),
            label: const Text('Join this circle'),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final active = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF32C7B8) : const Color(0xFF2B3948),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _Mentor {
  const _Mentor({
    required this.name,
    required this.specialty,
    required this.proof,
    required this.accent,
    this.avatarUrl = '',
  });

  final String name;
  final String specialty;
  final String proof;
  final Color accent;
  final String avatarUrl;
}

List<_Mentor> _mentorsForLevel(String level, String? medium) {
  final niche = _mediumLabel(medium);

  if (level == 'beginner') {
    return [
      _Mentor(
        name: 'Mina Park',
        specialty: '$niche fundamentals and confidence building',
        proof: 'Helped 120+ new artists finish their first portfolio.',
        accent: const Color(0xFF32C7B8),
      ),
      _Mentor(
        name: 'Leo Gray',
        specialty: 'Simple critique routines without overwhelm',
        proof: 'Runs weekly beginner office hours.',
        accent: const Color(0xFFE8B86D),
      ),
      _Mentor(
        name: 'Sana Malik',
        specialty: 'From practice to first paid commission',
        proof: 'Guided early creators through pricing and offers.',
        accent: const Color(0xFF7E9CF7),
      ),
    ];
  }

  if (level == 'growing') {
    return [
      _Mentor(
        name: 'Eli Navarro',
        specialty: '$niche consistency and audience growth',
        proof: 'Built a 40k creator community from scratch.',
        accent: const Color(0xFF32C7B8),
      ),
      _Mentor(
        name: 'Rhea Stone',
        specialty: 'Converting engagement into repeat commissions',
        proof: 'Mentors artists on monthly offer systems.',
        accent: const Color(0xFFE8B86D),
      ),
      _Mentor(
        name: 'Kai Benson',
        specialty: 'Scaling your process without burnout',
        proof: 'Former studio lead and critique coach.',
        accent: const Color(0xFF7E9CF7),
      ),
    ];
  }

  return [
    _Mentor(
      name: 'Iris Cole',
      specialty: 'Premium positioning for $niche artists',
      proof: 'Advised creators on 6-figure art businesses.',
      accent: const Color(0xFF32C7B8),
    ),
    _Mentor(
      name: 'Theo Quill',
      specialty: 'Collector relationships and retention systems',
      proof: 'Built high-ticket collector programs.',
      accent: const Color(0xFFE8B86D),
    ),
    _Mentor(
      name: 'Nora Vale',
      specialty: 'Team building and studio operations',
      proof: 'Scaled from solo creator to multi-artist studio.',
      accent: const Color(0xFF7E9CF7),
    ),
  ];
}

String _circleTitle(String level) {
  switch (level) {
    case 'beginner':
      return 'Join a Beginner Mentorship Circle';
    case 'growing':
      return 'Join a Growth Mentorship Circle';
    case 'selling':
      return 'Join a Pro Mentorship Circle';
    default:
      return 'Join a Mentorship Circle';
  }
}

String _mediumLabel(String? medium) {
  switch (medium) {
    case 'digital':
      return 'digital';
    case 'painting':
      return 'painting';
    case 'drawing':
      return 'drawing';
    case 'photography':
      return 'photography';
    case 'sculpture':
      return 'sculpture';
    case 'printmaking':
      return 'printmaking';
    case 'textile':
      return 'textile';
    case 'mixed_media':
      return 'mixed media';
    default:
      return 'art';
  }
}

List<_Mentor> _buildLiveMentors({
  required List<ArtistUser> artists,
  required String level,
  required String? medium,
}) {
  return artists.take(3).toList().asMap().entries.map((entry) {
    final index = entry.key;
    final artist = entry.value;
    final accent = _mentorPalette[index % _mentorPalette.length];

    return _Mentor(
      name: artist.displayName,
      specialty: _mentorSpecialty(artist, level, medium),
      proof: _mentorProof(artist),
      accent: accent,
      avatarUrl: artist.profileImageUrl,
    );
  }).toList();
}

String _mentorSpecialty(ArtistUser artist, String level, String? medium) {
  if (artist.specialties.isNotEmpty) {
    return artist.specialties.take(2).join(' • ');
  }

  final bio = artist.bio.trim();
  if (bio.isNotEmpty) {
    return bio;
  }

  switch (level) {
    case 'beginner':
      return '${_mediumLabel(medium)} fundamentals and confidence building';
    case 'growing':
      return '${_mediumLabel(medium)} consistency and audience growth';
    case 'selling':
      return 'Premium positioning for ${_mediumLabel(medium)} artists';
    default:
      return '${_mediumLabel(medium)} mentorship';
  }
}

String _mentorProof(ArtistUser artist) {
  if (artist.totalCritiques > 0) {
    final rating = artist.averageRating > 0
        ? ' • ${artist.averageRating.toStringAsFixed(1)} avg rating'
        : '';
    return '${artist.totalCritiques} critiques completed$rating';
  }

  if (artist.bio.trim().isNotEmpty) {
    return artist.bio.trim();
  }

  return 'Active community mentor in ArtConnect.';
}

const List<Color> _mentorPalette = [
  Color(0xFF32C7B8),
  Color(0xFFE8B86D),
  Color(0xFF7E9CF7),
];
