import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/demo_explore_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/first_win_screen.dart';
import 'screens/onboarding/identity_setup_screen.dart';
import 'screens/onboarding/immediate_interaction_screen.dart';
import 'screens/onboarding/mentorship_intro_screen.dart';
import 'screens/onboarding/need_hook_screen.dart';
import 'services/onboarding_progress_service.dart';
import 'widgets/brand_mark.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initializationError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    initializationError = error.toString();
  }

  runApp(ArtistCommunityApp(initializationError: initializationError));
}

class ArtistCommunityApp extends StatelessWidget {
  const ArtistCommunityApp({super.key, this.initializationError});

  final String? initializationError;

  static const _seed = Color(0xFF0F9D92);

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF131A22),
    ).copyWith(
      primary: const Color(0xFF32C7B8),
      secondary: const Color(0xFFE8B86D),
      surfaceContainerHighest: const Color(0xFF1A2430),
      outline: const Color(0xFF2B3948),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1016),
      canvasColor: const Color(0xFF0B1016),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141D27),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF243242)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1B2632),
        selectedColor: const Color(0xFF214B47),
        side: const BorderSide(color: Color(0xFF2E3A48)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF131C25),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x2632C7B8),
        height: 74,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF8EA0B3),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121A23),
        hintStyle: const TextStyle(color: Color(0xFF718296)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF32C7B8),
          foregroundColor: const Color(0xFF081012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF32C7B8),
          foregroundColor: const Color(0xFF081012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF34475A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = initializationError == null
        ? const AuthWrapper()
        : InitializationErrorScreen(error: initializationError!);

    return MaterialApp(
      title: 'ArtConnect',
      theme: _buildTheme(),
      home: SplashGate(destination: destination),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.destination});

  final Widget destination;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _showDestination = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _openDestination();
  }

  Future<void> _openDestination() async {
    await Future<void>.delayed(const Duration(milliseconds: 1350));
    if (!mounted) {
      return;
    }
    setState(() {
      _showDestination = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showDestination
          ? widget.destination
          : SplashScreen(
              fadeAnimation: _fadeAnimation,
              scaleAnimation: _scaleAnimation,
            ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    required this.fadeAnimation,
    required this.scaleAnimation,
  });

  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B1016),
              Color(0xFF123238),
              Color(0xFF231A13),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 112, showWordmark: true),
                  const SizedBox(height: 18),
                  Text(
                    'Studio-first social commerce for artists and collectors.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({super.key, required this.error});

  final String error;

  bool get _looksLikePlaceholderConfig =>
      error.contains('api-key-not-valid') ||
      error.contains('API key not valid') ||
      error.contains('auth/invalid-api-key') ||
      error.contains('DummyKey');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(
                  size: 74,
                  showWordmark: true,
                  align: CrossAxisAlignment.start,
                ),
                const SizedBox(height: 16),
                Text(
                  'App startup failed',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _looksLikePlaceholderConfig
                      ? 'Firebase is not configured with real project credentials for this platform yet. Replace the placeholder values in firebase_options.dart with real FlutterFire output.'
                      : 'The app hit an initialization error before the first screen could render.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141D27),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF253646)),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (kIsWeb)
                  Text(
                    'Web path: create a Firebase project, run FlutterFire configuration for web, then restart the app.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const DemoExploreScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Continue In Demo Mode'),
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final OnboardingProgressService _onboardingProgressService =
      OnboardingProgressService();
  String? _onboardingStage;
  String? _careerLevel;
  String? _primaryMedium;
  String? _lastCheckedUid;

  Future<void> _checkOnboardingStatus(String uid) async {
    if (uid == _lastCheckedUid) return;
    final progress = await _onboardingProgressService.getProgress(uid);
    if (mounted) {
      setState(() {
        _onboardingStage = progress.stage;
        _careerLevel = progress.careerLevel;
        _primaryMedium = progress.primaryMedium;
        _lastCheckedUid = uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          if (_lastCheckedUid != null) {
            _onboardingStage = null;
            _careerLevel = null;
            _primaryMedium = null;
            _lastCheckedUid = null;
          }
          return const AuthScreen();
        }

        if (user.uid != _lastCheckedUid) {
          _checkOnboardingStatus(user.uid);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        switch (_onboardingStage ?? OnboardingStage.needHook) {
          case OnboardingStage.needHook:
            return NeedHookScreen(userId: user.uid);
          case OnboardingStage.identity:
            return IdentitySetupScreen(userId: user.uid);
          case OnboardingStage.firstWin:
            return FirstWinScreen(
              userId: user.uid,
              careerLevel: _careerLevel ?? 'beginner',
              primaryMedium: _primaryMedium,
            );
          case OnboardingStage.immediateInteraction:
            return ImmediateInteractionScreen(
              userId: user.uid,
              primaryMedium: _primaryMedium,
              careerLevel: _careerLevel ?? 'beginner',
            );
          case OnboardingStage.mentorship:
            return MentorshipIntroScreen(
              userId: user.uid,
              primaryMedium: _primaryMedium,
              careerLevel: _careerLevel ?? 'beginner',
            );
          case OnboardingStage.completed:
            return const HomeScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
