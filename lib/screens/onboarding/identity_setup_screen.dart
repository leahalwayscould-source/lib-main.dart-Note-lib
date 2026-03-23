import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/onboarding_progress_service.dart';
import '../../widgets/brand_mark.dart';
import 'first_win_screen.dart';

// ─── Art medium data ──────────────────────────────────────────────────────

class _ArtMedium {
  const _ArtMedium({
    required this.id,
    required this.label,
    required this.emoji,
  });
  final String id;
  final String label;
  final String emoji;
}

const _artMediums = [
  _ArtMedium(id: 'digital', label: 'Digital Art', emoji: '🖥️'),
  _ArtMedium(id: 'painting', label: 'Painting', emoji: '🎨'),
  _ArtMedium(id: 'drawing', label: 'Drawing / Illustration', emoji: '✏️'),
  _ArtMedium(id: 'photography', label: 'Photography', emoji: '📷'),
  _ArtMedium(id: 'sculpture', label: 'Sculpture / 3D', emoji: '🗿'),
  _ArtMedium(id: 'printmaking', label: 'Printmaking', emoji: '🖨️'),
  _ArtMedium(id: 'textile', label: 'Textile / Fibre', emoji: '🧵'),
  _ArtMedium(id: 'mixed_media', label: 'Mixed Media', emoji: '🌀'),
  _ArtMedium(id: 'other', label: 'Something else', emoji: '✨'),
];

// ─── Career level data ────────────────────────────────────────────────────

class _CareerLevel {
  const _CareerLevel({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.accent,
  });
  final String id;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color accent;
}

const _levels = [
  _CareerLevel(
    id: 'beginner',
    label: 'Beginner',
    sublabel: 'Still finding my voice and exploring.',
    icon: Icons.eco_outlined,
    accent: Color(0xFF32C7B8),
  ),
  _CareerLevel(
    id: 'growing',
    label: 'Growing',
    sublabel: 'Building an audience, getting commissions.',
    icon: Icons.trending_up_rounded,
    accent: Color(0xFFE8B86D),
  ),
  _CareerLevel(
    id: 'selling',
    label: 'Selling',
    sublabel: 'Earning from my art, scaling my practice.',
    icon: Icons.storefront_outlined,
    accent: Color(0xFF7E9CF7),
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key, required this.userId});

  final String userId;

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingProgressService _progressService =
      OnboardingProgressService();
  // Step 0 = art mediums, Step 1 = career level
  int _step = 0;

  final Set<String> _selectedMediums = {};
  String? _selectedLevel;
  bool _saving = false;

  late final AnimationController _stepController;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _stepFade = CurvedAnimation(parent: _stepController, curve: Curves.easeOut);
    _stepController.forward();
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  void _advanceStep() {
    _stepController.reverse().then((_) {
      setState(() => _step = 1);
      _stepController.forward();
    });
  }

  void _goBack() {
    _stepController.reverse().then((_) {
      setState(() => _step = 0);
      _stepController.forward();
    });
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedLevel != null) {
        await prefs.setString(
            'identity_level_${widget.userId}', _selectedLevel!);
      }
      final primaryMedium =
          _selectedMediums.isEmpty ? null : _selectedMediums.first;
      await _progressService.saveIdentity(
        widget.userId,
        careerLevel: _selectedLevel ?? 'beginner',
        primaryMedium: primaryMedium,
      );
      await _progressService.setStage(widget.userId, OnboardingStage.firstWin);

      // Best-effort Firestore write.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'artMediums': _selectedMediums.toList(),
        'careerLevel': _selectedLevel ?? 'beginner',
        'onboardingComplete': true,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Never block the user on a network failure.
    }

    if (!mounted) return;
    _goFirstWin();
  }

  void _goFirstWin() {
    final primaryMedium =
        _selectedMediums.isEmpty ? null : _selectedMediums.first;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (_, __, ___) => FirstWinScreen(
          userId: widget.userId,
          careerLevel: _selectedLevel ?? 'beginner',
          primaryMedium: primaryMedium,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1016), Color(0xFF111B24), Color(0xFF160E14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(step: _step, onBack: _step == 1 ? _goBack : null),
              Expanded(
                child: FadeTransition(
                  opacity: _stepFade,
                  child: _step == 0 ? _buildMediumStep() : _buildLevelStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 0: Medium picker ─────────────────────────────────────────────

  Widget _buildMediumStep() {
    final canContinue = _selectedMediums.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'What kind of art\ndo you create?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick as many as you like — we\'ll tailor your feed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF718296),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _artMediums.map((m) {
                  final selected = _selectedMediums.contains(m.id);
                  return _MediumChip(
                    medium: m,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedMediums.remove(m.id);
                        } else {
                          _selectedMediums.add(m.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canContinue ? _advanceStep : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _advanceStep,
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: const Color(0xFF718296),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Career level picker ───────────────────────────────────────

  Widget _buildLevelStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Where are you\nin your journey?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No wrong answer — this helps us show you the right content.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF718296),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: _levels.map((level) {
                final selected = _selectedLevel == level.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _LevelCard(
                    level: level,
                    selected: selected,
                    onTap: () => setState(() => _selectedLevel = level.id),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _finish,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF081012)),
                      ),
                    )
                  : Text(
                      _selectedLevel == null
                          ? 'Skip and explore'
                          : 'Take me in →',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.step, this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Column(
              children: [
                const BrandMark(size: 28, showWordmark: false),
                const SizedBox(height: 10),
                // Step dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(2, (index) {
                    final active = index == step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF32C7B8)
                            : const Color(0xFF2B3948),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // balance the back button
        ],
      ),
    );
  }
}

class _MediumChip extends StatelessWidget {
  const _MediumChip({
    required this.medium,
    required this.selected,
    required this.onTap,
  });

  final _ArtMedium medium;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF32C7B8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:
            selected ? accent.withValues(alpha: 0.15) : const Color(0xFF141D27),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? accent : const Color(0xFF243242),
          width: selected ? 1.6 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(medium.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  medium.label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFCDD9E5),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final _CareerLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = level.accent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color:
            selected ? accent.withValues(alpha: 0.12) : const Color(0xFF141D27),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? accent : const Color(0xFF243242),
          width: selected ? 1.8 : 1.0,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.2)
                        : const Color(0xFF1B2632),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    level.icon,
                    color: selected ? accent : const Color(0xFF8EA0B3),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color:
                              selected ? Colors.white : const Color(0xFFCDD9E5),
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          height: 1.3,
                        ),
                        child: Text(level.label),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.sublabel,
                        style: TextStyle(
                          color: selected
                              ? accent.withValues(alpha: 0.9)
                              : const Color(0xFF6B7D8E),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1.0 : 0.0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
