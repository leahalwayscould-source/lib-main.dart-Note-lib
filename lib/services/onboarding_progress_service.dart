import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStage {
  static const needHook = 'need_hook';
  static const identity = 'identity';
  static const firstWin = 'first_win';
  static const immediateInteraction = 'immediate_interaction';
  static const mentorship = 'mentorship';
  static const completed = 'completed';
}

class OnboardingProgressSnapshot {
  const OnboardingProgressSnapshot({
    required this.stage,
    this.careerLevel,
    this.primaryMedium,
  });

  final String stage;
  final String? careerLevel;
  final String? primaryMedium;
}

class OnboardingProgressService {
  Future<OnboardingProgressSnapshot> getProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedStage = prefs.getString(_stageKey(userId));
    final savedCareerLevel = prefs.getString(_careerLevelKey(userId));
    final savedPrimaryMedium = prefs.getString(_primaryMediumKey(userId));
    final legacyComplete = prefs.getBool('hook_complete_$userId') ?? false;
    final stage = savedStage ??
        (legacyComplete && savedCareerLevel != null
            ? OnboardingStage.firstWin
            : legacyComplete
                ? OnboardingStage.completed
                : OnboardingStage.needHook);

    return OnboardingProgressSnapshot(
      stage: stage,
      careerLevel: savedCareerLevel,
      primaryMedium: savedPrimaryMedium,
    );
  }

  Future<void> setStage(String userId, String stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stageKey(userId), stage);
    await prefs.setBool(
        'hook_complete_$userId', stage == OnboardingStage.completed);
  }

  Future<void> saveIdentity(
    String userId, {
    required String careerLevel,
    String? primaryMedium,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_careerLevelKey(userId), careerLevel);
    if (primaryMedium == null || primaryMedium.isEmpty) {
      await prefs.remove(_primaryMediumKey(userId));
    } else {
      await prefs.setString(_primaryMediumKey(userId), primaryMedium);
    }
  }

  String _stageKey(String userId) => 'onboarding_stage_$userId';

  String _careerLevelKey(String userId) => 'identity_level_$userId';

  String _primaryMediumKey(String userId) => 'identity_primary_medium_$userId';
}
