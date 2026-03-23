import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OnboardingEventsDebugScreen extends StatelessWidget {
  const OnboardingEventsDebugScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final eventsStream = userRef
        .collection('onboardingEvents')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      appBar: AppBar(
        title: const Text('Onboarding Debug'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userRef.snapshots(),
            builder: (context, snapshot) {
              final userData = snapshot.data?.data() ?? <String, dynamic>{};
              final actions =
                  (userData['onboardingActions'] as Map<String, dynamic>?) ??
                      <String, dynamic>{};

              return _Panel(
                title: 'onboardingActions',
                child: actions.isEmpty
                    ? const Text(
                        'No onboardingActions saved yet.',
                        style: TextStyle(color: Color(0xFF8EA0B3)),
                      )
                    : Text(
                        actions.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 12),
          _Panel(
            title: 'onboardingEvents',
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Text(
                    'No onboardingEvents logged yet.',
                    style: TextStyle(color: Color(0xFF8EA0B3)),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final payload =
                        (data['payload'] as Map<String, dynamic>?) ??
                            <String, dynamic>{};
                    final timestamp = data['createdAt'];

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121C27),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF243242)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['eventType']?.toString() ?? '(unknown)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timestamp is Timestamp
                                ? timestamp.toDate().toIso8601String()
                                : '(no timestamp)',
                            style: const TextStyle(
                              color: Color(0xFF8EA0B3),
                              fontSize: 12,
                            ),
                          ),
                          if (payload.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              payload.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(' | '),
                              style: const TextStyle(
                                color: Color(0xFFBDD1E4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141D27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF243242)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
