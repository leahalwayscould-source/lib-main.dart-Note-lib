import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/onboarding_progress_service.dart';
import '../../widgets/brand_mark.dart';
import 'immediate_interaction_screen.dart';

// Default hourly rates by career level (seeded from IdentitySetupScreen).
const _defaultRateByLevel = {
  'beginner': 25.0,
  'growing': 45.0,
  'selling': 75.0,
};

class FirstWinScreen extends StatefulWidget {
  const FirstWinScreen({
    super.key,
    required this.userId,
    required this.careerLevel,
    this.primaryMedium,
  });

  final String userId;

  /// Career level id from IdentitySetupScreen: 'beginner' | 'growing' | 'selling'
  final String careerLevel;

  /// Optional first medium from IdentitySetupScreen for an extra-personalised label.
  final String? primaryMedium;

  @override
  State<FirstWinScreen> createState() => _FirstWinScreenState();
}

class _FirstWinScreenState extends State<FirstWinScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingProgressService _progressService =
      OnboardingProgressService();
  // ── State ─────────────────────────────────────────────────────────────────

  double _hours = 8;
  double _materials = 20;
  late double _hourlyRate;

  bool _revealed = false;
  bool _animating = false;

  late final AnimationController _revealController;
  late final Animation<double> _scalePop;
  late final Animation<double> _fadeUp;

  final _materialsController = TextEditingController();
  final _rateController = TextEditingController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _hourlyRate = _defaultRateByLevel[widget.careerLevel] ?? 40.0;

    _materialsController.text = _materials.toStringAsFixed(0);
    _rateController.text = _hourlyRate.toStringAsFixed(0);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scalePop = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );

    _fadeUp = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    _materialsController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  // ── Price logic ───────────────────────────────────────────────────────────

  double get _suggestedPrice => (_hours * _hourlyRate) + _materials;

  String get _priceLabel => '\$${_suggestedPrice.toStringAsFixed(2)}';

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onReveal() {
    if (_animating) return;
    setState(() {
      _revealed = true;
      _animating = true;
    });
    HapticFeedback.mediumImpact();
    _revealController.forward().then((_) {
      if (mounted) setState(() => _animating = false);
    });
  }

  Future<void> _goNext() async {
    await _progressService.setStage(
      widget.userId,
      OnboardingStage.immediateInteraction,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, __, ___) => ImmediateInteractionScreen(
          userId: widget.userId,
          primaryMedium: widget.primaryMedium,
          careerLevel: widget.careerLevel,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1016), Color(0xFF0E1D14), Color(0xFF12111E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header ─────────────────────────────────────────────
                const BrandMark(size: 28, showWordmark: false),
                const SizedBox(height: 24),
                _StepDots(currentStep: 2),
                const SizedBox(height: 28),

                Text(
                  'Let\'s find your\nprice right now.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.22,
                        letterSpacing: -0.4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your last piece and we\'ll show you what to charge.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF718296),
                        height: 1.4,
                      ),
                ),

                const SizedBox(height: 36),

                // ── Inputs ─────────────────────────────────────────────
                _InputCard(
                  label: 'How many hours did you spend?',
                  sublabel: '${_hours.toInt()} hrs',
                  accentColor: const Color(0xFF32C7B8),
                  child: Slider(
                    value: _hours,
                    min: 1,
                    max: 120,
                    divisions: 119,
                    activeColor: const Color(0xFF32C7B8),
                    inactiveColor: const Color(0xFF243242),
                    onChanged: (v) => setState(() {
                      _hours = v.roundToDouble();
                      _revealed = false;
                      _revealController.reset();
                    }),
                  ),
                ),

                const SizedBox(height: 14),

                _InputCard(
                  label: 'Materials cost (\$)',
                  sublabel: 'paint, canvas, supplies, etc.',
                  accentColor: const Color(0xFFE8B86D),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: TextFormField(
                      controller: _materialsController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        prefixText: '\$  ',
                        prefixStyle: const TextStyle(
                          color: Color(0xFFE8B86D),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '0',
                        fillColor: const Color(0xFF0D161F),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      onChanged: (v) {
                        final parsed = double.tryParse(v) ?? 0;
                        setState(() {
                          _materials = parsed;
                          _revealed = false;
                          _revealController.reset();
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                _InputCard(
                  label: 'Your hourly rate (\$)',
                  sublabel: _rateHint(widget.careerLevel),
                  accentColor: const Color(0xFF7E9CF7),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        prefixText: '\$/hr  ',
                        prefixStyle: const TextStyle(
                          color: Color(0xFF7E9CF7),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: _hourlyRate.toStringAsFixed(0),
                        fillColor: const Color(0xFF0D161F),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null && parsed > 0) {
                          setState(() {
                            _hourlyRate = parsed;
                            _revealed = false;
                            _revealController.reset();
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Reveal button / price card ─────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _revealed
                      ? _PriceRevealCard(
                          key: const ValueKey('reveal'),
                          price: _priceLabel,
                          hours: _hours.toInt(),
                          hourlyRate: _hourlyRate,
                          materials: _materials,
                          scalePop: _scalePop,
                          fadeUp: _fadeUp,
                        )
                      : SizedBox(
                          key: const ValueKey('btn'),
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton.icon(
                            onPressed: _onReveal,
                            icon: const Icon(Icons.auto_awesome_rounded,
                                size: 20),
                            label: const Text(
                              'Show what I should charge →',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                ),

                if (_revealed) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _goNext,
                      child:
                          const Text('Continue to your first interactions →'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _goNext,
                    child: Text(
                      'I\'ll tune pricing later',
                      style: TextStyle(
                        color: const Color(0xFF718296),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _goNext,
                    child: Text(
                      'Skip this step for now',
                      style: TextStyle(
                        color: const Color(0xFF718296),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _rateHint(String level) {
    switch (level) {
      case 'beginner':
        return 'We\'ve started you at \$25/hr — adjust freely.';
      case 'growing':
        return 'We\'ve started you at \$45/hr — adjust freely.';
      case 'selling':
        return 'We\'ve started you at \$75/hr — adjust freely.';
      default:
        return 'Adjust to match your market.';
    }
  }
}

// ─── Step Dots (3-step version) ───────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
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

// ─── Input card ───────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.label,
    required this.sublabel,
    required this.accentColor,
    required this.child,
  });

  final String label;
  final String sublabel;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141D27),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2E3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              sublabel,
              style: const TextStyle(
                color: Color(0xFF6B7D8E),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ─── Price reveal card ────────────────────────────────────────────────────

class _PriceRevealCard extends StatelessWidget {
  const _PriceRevealCard({
    super.key,
    required this.price,
    required this.hours,
    required this.hourlyRate,
    required this.materials,
    required this.scalePop,
    required this.fadeUp,
  });

  final String price;
  final int hours;
  final double hourlyRate;
  final double materials;
  final Animation<double> scalePop;
  final Animation<double> fadeUp;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF32C7B8);

    return FadeTransition(
      opacity: fadeUp,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1C17),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent.withValues(alpha: 0.45),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'You should be charging',
              style: TextStyle(
                color: const Color(0xFF8EA0B3),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            ScaleTransition(
              scale: scalePop,
              child: Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF32C7B8),
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Breakdown line
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111E19),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$hours hrs × \$${hourlyRate.toStringAsFixed(0)}/hr'
                '${materials > 0 ? '  +  \$${materials.toStringAsFixed(0)} materials' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5E8A7D),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Confidence prompt
            _InsightRow(
              icon: Icons.trending_up_rounded,
              text:
                  'Many artists underprice by 40–60%. This number is your floor, not your ceiling.',
              accent: accent,
            ),
            const SizedBox(height: 10),
            _InsightRow(
              icon: Icons.auto_awesome_rounded,
              text:
                  'The full pricing calculator inside the app lets you refine this further.',
              accent: const Color(0xFFE8B86D),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFF8EA0B3),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

// Expose a helper so external code can calculate the same way without
// depending on the widget internals.
double calculateFirstWinPrice({
  required double hours,
  required double hourlyRate,
  required double materials,
}) =>
    (hours * hourlyRate) + materials;
