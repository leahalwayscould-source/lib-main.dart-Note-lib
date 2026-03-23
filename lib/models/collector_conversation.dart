import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorConversation {
  CollectorConversation({
    required this.conversationId,
    required this.inquiryId,
    required this.postId,
    required this.postTitle,
    required this.postImageUrl,
    required this.artistUid,
    required this.artistName,
    required this.buyerUid,
    required this.buyerName,
    required this.buyerEmail,
    required this.intent,
    required this.latestMessage,
    required this.latestSenderUid,
    required this.status,
    required this.createdAt,
    required this.lastMessageAt,
    required this.lastReadAtBy,
    required this.unreadCountBy,
  });

  final String conversationId;
  final String inquiryId;
  final String postId;
  final String postTitle;
  final String postImageUrl;
  final String artistUid;
  final String artistName;
  final String buyerUid;
  final String buyerName;
  final String buyerEmail;
  final String intent;
  final String latestMessage;
  final String latestSenderUid;
  final String status;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final Map<String, DateTime> lastReadAtBy;
  final Map<String, int> unreadCountBy;

  factory CollectorConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CollectorConversation(
      conversationId: doc.id,
      inquiryId: data['inquiryId'] ?? '',
      postId: data['postId'] ?? '',
      postTitle: data['postTitle'] ?? 'Untitled artwork',
      postImageUrl: data['postImageUrl'] ?? '',
      artistUid: data['artistUid'] ?? '',
      artistName: data['artistName'] ?? 'Artist',
      buyerUid: data['buyerUid'] ?? '',
      buyerName: data['buyerName'] ?? 'Collector',
      buyerEmail: data['buyerEmail'] ?? '',
      intent: data['intent'] ?? 'Ask a question first',
      latestMessage: data['latestMessage'] ?? '',
      latestSenderUid: data['latestSenderUid'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: _timestampToDateTime(data['createdAt']),
      lastMessageAt: _timestampToDateTime(data['lastMessageAt']),
      lastReadAtBy: _readMapFromRaw(data['lastReadAtBy']),
      unreadCountBy: _unreadMapFromRaw(data['unreadCountBy']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inquiryId': inquiryId,
      'postId': postId,
      'postTitle': postTitle,
      'postImageUrl': postImageUrl,
      'artistUid': artistUid,
      'artistName': artistName,
      'buyerUid': buyerUid,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'intent': intent,
      'latestMessage': latestMessage,
      'latestSenderUid': latestSenderUid,
      'participantUids': [buyerUid, artistUid],
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastReadAtBy': {
        for (final entry in lastReadAtBy.entries)
          entry.key: Timestamp.fromDate(entry.value),
      },
      'unreadCountBy': unreadCountBy,
    };
  }

  static Map<String, int> _unreadMapFromRaw(dynamic value) {
    if (value is! Map) {
      return {};
    }

    final result = <String, int>{};
    value.forEach((key, rawCount) {
      if (key is! String) {
        return;
      }

      if (rawCount is int) {
        result[key] = rawCount;
        return;
      }

      if (rawCount is num) {
        result[key] = rawCount.toInt();
      }
    });
    return result;
  }

  static Map<String, DateTime> _readMapFromRaw(dynamic value) {
    if (value is! Map) {
      return {};
    }

    final result = <String, DateTime>{};
    value.forEach((key, rawTimestamp) {
      if (key is String) {
        result[key] = _timestampToDateTime(rawTimestamp);
      }
    });
    return result;
  }

  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.now();
  }
}

class CollectorConversationMessage {
  CollectorConversationMessage({
    required this.messageId,
    required this.senderUid,
    required this.senderName,
    required this.senderEmail,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  final String messageId;
  final String senderUid;
  final String senderName;
  final String senderEmail;
  final String text;
  final String type;
  final DateTime createdAt;

  factory CollectorConversationMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CollectorConversationMessage(
      messageId: doc.id,
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? 'Collector',
      senderEmail: data['senderEmail'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'message',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'text': text,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
