import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/onboarding_progress_service.dart';
import '../../widgets/brand_mark.dart';
import 'identity_setup_screen.dart';

// The user's stated primary need — persisted and usable for feed personalisation.
enum ArtistNeed {
  findMyStyle,
  getFeedback,
  priceMyWork,
  findMentorship,
}

extension ArtistNeedLabel on ArtistNeed {
  String get label {
    switch (this) {
      case ArtistNeed.findMyStyle:
        return 'Find my style';
      case ArtistNeed.getFeedback:
        return 'Get Feedback';
      case ArtistNeed.priceMyWork:
        return 'Price my work';
      case ArtistNeed.findMentorship:
        return 'Find Mentorship';
    }
  }

  String get firestoreValue {
    switch (this) {
      case ArtistNeed.findMyStyle:
        return 'find_my_style';
      case ArtistNeed.getFeedback:
        return 'get_feedback';
      case ArtistNeed.priceMyWork:
        return 'price_my_work';
      case ArtistNeed.findMentorship:
        return 'find_mentorship';
    }
  }

  String get tagline {
    switch (this) {
      case ArtistNeed.findMyStyle:
        return 'Discover what makes your art distinctly yours.';
      case ArtistNeed.getFeedback:
        return 'Hear from artists who genuinely understand.';
      case ArtistNeed.priceMyWork:
        return 'Know your worth and charge it confidently.';
      case ArtistNeed.findMentorship:
        return 'Learn from artists who are a few steps ahead.';
    }
  }

  IconData get icon {
    switch (this) {
      case ArtistNeed.findMyStyle:
        return Icons.auto_awesome_outlined;
      case ArtistNeed.getFeedback:
        return Icons.forum_outlined;
      case ArtistNeed.priceMyWork:
        return Icons.monetization_on_outlined;
      case ArtistNeed.findMentorship:
        return Icons.people_outline;
    }
  }

  Color get accentColor {
    switch (this) {
      case ArtistNeed.findMyStyle:
        return const Color(0xFF32C7B8);
      case ArtistNeed.getFeedback:
        return const Color(0xFFE8B86D);
      case ArtistNeed.priceMyWork:
        return const Color(0xFF7E9CF7);
      case ArtistNeed.findMentorship:
        return const Color(0xFFD46FCF);
    }
  }
}

class NeedHookScreen extends StatefulWidget {
  const NeedHookScreen({super.key, required this.userId});

  final String userId;

  @override
  State<NeedHookScreen> createState() => _NeedHookScreenState();
}

class _NeedHookScreenState extends State<NeedHookScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingProgressService _progressService =
      OnboardingProgressService();
  ArtistNeed? _selected;
  bool _saving = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _onChoose(ArtistNeed need) async {
    if (_saving) return;
    setState(() {
      _selected = need;
      _saving = true;
    });

    // Small pause so the selected state is visible before transitioning.
    await Future<void>.delayed(const Duration(milliseconds: 320));

    try {
      // Best-effort: save the primary need to Firestore for personalisation.
      // hook_complete is NOT marked here — it is marked by IdentitySetupScreen
      // at the end of the full onboarding sequence.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hook_need_${widget.userId}', need.firestoreValue);
      await _progressService.setStage(widget.userId, OnboardingStage.identity);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'primaryNeed': need.firestoreValue,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Never block the user on a network failure.
    }

    if (!mounted) return;
    _goNext();
  }

  Future<void> _onSkip() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _progressService.setStage(widget.userId, OnboardingStage.identity);
    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (_, __, ___) => IdentitySetupScreen(userId: widget.userId),
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
            colors: [
              Color(0xFF0B1016),
              Color(0xFF0F1E26),
              Color(0xFF161012),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const BrandMark(size: 36, showWordmark: false),
                    const SizedBox(height: 32),
                    Text(
                      'What do you need\nmost right now?',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We\'ll personalise your experience around your answer.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF718296),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 36),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: ArtistNeed.values.map((need) {
                          final isSelected = _selected == need;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _NeedCard(
                              need: need,
                              selected: isSelected,
                              saving: _saving,
                              onTap: () => _onChoose(need),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : _onSkip,
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: const Color(0xFF718296),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({
    required this.need,
    required this.selected,
    required this.saving,
    required this.onTap,
  });

  final ArtistNeed need;
  final bool selected;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = need.accentColor;
    final isDisabled = saving && !selected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color:
            selected ? accent.withValues(alpha: 0.13) : const Color(0xFF141D27),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? accent : const Color(0xFF243242),
          width: selected ? 1.8 : 1.0,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isDisabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.22)
                        : const Color(0xFF1B2632),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    need.icon,
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
                          fontSize: 16,
                          height: 1.3,
                        ),
                        child: Text(need.label),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        need.tagline,
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
