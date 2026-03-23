import 'package:cloud_firestore/cloud_firestore.dart';




class ArtworkInquiry {
  ArtworkInquiry({
    required this.inquiryId,
    required this.conversationId,
    required this.postId,
    required this.postTitle,
    required this.postImageUrl,
    required this.artistUid,
    required this.artistName,
    required this.buyerUid,
    required this.buyerName,
    required this.buyerEmail,
    required this.intent,
    required this.message,
    required this.status,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  final String inquiryId;
  final String conversationId;
  final String postId;
  final String postTitle;
  final String postImageUrl;
  final String artistUid;
  final String artistName;
  final String buyerUid;
  final String buyerName;
  final String buyerEmail;
  final String intent;
  final String message;
  final String status;
  final List<ArtworkInquiryStatusEvent> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ArtworkInquiry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtworkInquiry(
      inquiryId: doc.id,
      conversationId: data['conversationId'] ?? '',
      postId: data['postId'] ?? '',
      postTitle: data['postTitle'] ?? 'Untitled artwork',
      postImageUrl: data['postImageUrl'] ?? '',
      artistUid: data['artistUid'] ?? '',
      artistName: data['artistName'] ?? 'Artist',
      buyerUid: data['buyerUid'] ?? '',
      buyerName: data['buyerName'] ?? 'Collector',
      buyerEmail: data['buyerEmail'] ?? '',
      intent: data['intent'] ?? 'Ask a question first',
      message: data['message'] ?? '',
      status: data['status'] ?? 'open',
      statusHistory: _statusHistoryFromRaw(
        data['statusHistory'],
        fallbackStatus: data['status'] ?? 'open',
        fallbackCreatedAt: data['createdAt'],
      ),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'postId': postId,
      'postTitle': postTitle,
      'postImageUrl': postImageUrl,
      'artistUid': artistUid,
      'artistName': artistName,
      'buyerUid': buyerUid,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'intent': intent,
      'message': message,
      'status': status,
      'statusHistory': statusHistory.map((entry) => entry.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static List<ArtworkInquiryStatusEvent> _statusHistoryFromRaw(
    dynamic raw, {
    required String fallbackStatus,
    required dynamic fallbackCreatedAt,
  }) {
    final events = <ArtworkInquiryStatusEvent>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          events.add(ArtworkInquiryStatusEvent.fromMap(entry));
          continue;
        }

        if (entry is Map) {
          events.add(
            ArtworkInquiryStatusEvent.fromMap(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    if (events.isNotEmpty) {
      events.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return events;
    }

    return [
      ArtworkInquiryStatusEvent(
        status: fallbackStatus,
        note: 'Inquiry created',
        actorUid: '',
        actorName: 'System',
        createdAt: _timestampToDateTime(fallbackCreatedAt),
      ),
    ];
  }

  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.now();
  }
}

class ArtworkInquiryStatusEvent {
  ArtworkInquiryStatusEvent({
    required this.status,
    required this.note,
    required this.actorUid,
    required this.actorName,
    required this.createdAt,
  });

  final String status;
  final String note;
  final String actorUid;
  final String actorName;
  final DateTime createdAt;

  factory ArtworkInquiryStatusEvent.fromMap(Map<String, dynamic> data) {
    return ArtworkInquiryStatusEvent(
      status: data['status'] ?? 'open',
      note: data['note'] ?? '',
      actorUid: data['actorUid'] ?? '',
      actorName: data['actorName'] ?? 'System',
      createdAt: ArtworkInquiry._timestampToDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'note': note,
      'actorUid': actorUid,
      'actorName': actorName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
