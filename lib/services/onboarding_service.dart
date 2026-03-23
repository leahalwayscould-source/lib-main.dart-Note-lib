import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingService {
  OnboardingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> logEvent({
    required String userId,
    required String eventType,
    Map<String, dynamic>? payload,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('onboardingEvents')
        .add({
      'eventType': eventType,
      'payload': payload ?? <String, dynamic>{},
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> recordFirstFeedback({
    required String userId,
    required String postArtist,
    required String challenge,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final snapshot = await userRef.get();
    final data = snapshot.data();
    final onboardingActions =
        (data?['onboardingActions'] as Map<String, dynamic>?) ??
            <String, dynamic>{};

    if (onboardingActions['firstFeedbackAt'] != null) {
      return;
    }

    await userRef.set({
      'onboardingActions': {
        'firstFeedbackAt': Timestamp.now(),
        'firstFeedbackArtist': postArtist,
        'firstFeedbackChallenge': challenge,
      },
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await logEvent(
      userId: userId,
      eventType: 'first_feedback_left',
      payload: {
        'postArtist': postArtist,
        'challenge': challenge,
      },
    );
  }

  Future<void> recordFollow({
    required String userId,
    required String artistName,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'onboardingActions': {
        'followedArtists': FieldValue.arrayUnion([artistName]),
        'firstFollowAt': Timestamp.now(),
      },
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await logEvent(
      userId: userId,
      eventType: 'artist_followed_during_onboarding',
      payload: {
        'artistName': artistName,
      },
    );
  }

  Future<void> recordMentorSelection({
    required String userId,
    required String mentorName,
    required String careerLevel,
    required String? primaryMedium,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'onboardingActions': {
        'selectedMentor': mentorName,
        'mentorSelectedAt': Timestamp.now(),
        'careerLevelAtSelection': careerLevel,
        'primaryMediumAtSelection': primaryMedium,
      },
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await logEvent(
      userId: userId,
      eventType: 'mentor_selected',
      payload: {
        'mentorName': mentorName,
        'careerLevel': careerLevel,
        'primaryMedium': primaryMedium,
      },
    );
  }

  Future<void> recordCircleJoin({
    required String userId,
    required String circleTitle,
    required String careerLevel,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'onboardingActions': {
        'joinedMentorshipCircle': circleTitle,
        'circleJoinedAt': Timestamp.now(),
        'circleCareerLevel': careerLevel,
      },
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await logEvent(
      userId: userId,
      eventType: 'mentorship_circle_joined',
      payload: {
        'circleTitle': circleTitle,
        'careerLevel': careerLevel,
      },
    );
  }
}
