import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/art_post.dart';
import '../models/artwork_inquiry.dart';
import '../models/collector_conversation.dart';

class ArtworkInquirySubmission {
  ArtworkInquirySubmission({
    required this.inquiry,
    required this.conversation,
  });

  final ArtworkInquiry inquiry;
  final CollectorConversation conversation;
}

class ArtworkInquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Set<String> _allowedStatuses = {
    'open',
    'reviewing',
    'quoted',
    'accepted',
    'closed',
  };

  Future<ArtworkInquirySubmission> submitInquiry({
    required ArtPost post,
    required String buyerUid,
    required String buyerName,
    required String buyerEmail,
    required String intent,
    required String message,
  }) async {
    final now = DateTime.now();
    final inquiryRef = _firestore.collection('artworkInquiries').doc();
    final conversationRef =
        _firestore.collection('collectorConversations').doc();
    final initialMessageRef = conversationRef.collection('messages').doc();

    final inquiry = ArtworkInquiry(
      inquiryId: inquiryRef.id,
      conversationId: conversationRef.id,
      postId: post.postId,
      postTitle: post.title,
      postImageUrl: post.imageUrl,
      artistUid: post.artistUid,
      artistName: post.artistName,
      buyerUid: buyerUid,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      intent: intent,
      message: message,
      status: 'open',
      statusHistory: [
        ArtworkInquiryStatusEvent(
          status: 'open',
          note: 'Inquiry created',
          actorUid: buyerUid,
          actorName: buyerName,
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final conversation = CollectorConversation(
      conversationId: conversationRef.id,
      inquiryId: inquiryRef.id,
      postId: post.postId,
      postTitle: post.title,
      postImageUrl: post.imageUrl,
      artistUid: post.artistUid,
      artistName: post.artistName,
      buyerUid: buyerUid,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      intent: intent,
      latestMessage: message,
      latestSenderUid: buyerUid,
      status: 'open',
      createdAt: now,
      lastMessageAt: now,
      lastReadAtBy: {
        buyerUid: now,
      },
      unreadCountBy: {
        buyerUid: 0,
        post.artistUid: 1,
      },
    );

    final batch = _firestore.batch();
    batch.set(inquiryRef, inquiry.toMap());
    batch.set(conversationRef, conversation.toMap());
    batch.set(
      initialMessageRef,
      CollectorConversationMessage(
        messageId: initialMessageRef.id,
        senderUid: buyerUid,
        senderName: buyerName,
        senderEmail: buyerEmail,
        text: message,
        type: 'inquiry',
        createdAt: now,
      ).toMap(),
    );
    await batch.commit();

    return ArtworkInquirySubmission(
      inquiry: inquiry,
      conversation: conversation,
    );
  }

  Stream<List<ArtworkInquiry>> getBuyerInquiries(String buyerUid) {
    return _firestore
        .collection('artworkInquiries')
        .where('buyerUid', isEqualTo: buyerUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ArtworkInquiry.fromFirestore).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        );
  }

  Stream<List<CollectorConversation>> getBuyerConversations(String buyerUid) {
    return _firestore
        .collection('collectorConversations')
        .where('buyerUid', isEqualTo: buyerUid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CollectorConversation.fromFirestore).toList()
                ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt)),
        );
  }

  Stream<List<CollectorConversation>> getArtistConversations(String artistUid) {
    return _firestore
        .collection('collectorConversations')
        .where('artistUid', isEqualTo: artistUid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CollectorConversation.fromFirestore).toList()
                ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt)),
        );
  }

  Stream<List<CollectorConversationMessage>> getConversationMessages(
    String conversationId,
  ) {
    return _firestore
        .collection('collectorConversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CollectorConversationMessage.fromFirestore)
              .toList(),
        );
  }

  Stream<ArtworkInquiry?> getInquiry(String inquiryId) {
    return _firestore
        .collection('artworkInquiries')
        .doc(inquiryId)
        .snapshots()
        .map(
      (doc) {
        if (!doc.exists) {
          return null;
        }

        return ArtworkInquiry.fromFirestore(doc);
      },
    );
  }

  Future<void> sendConversationMessage({
    required CollectorConversation conversation,
    required String senderUid,
    required String senderName,
    required String senderEmail,
    required String text,
    String type = 'message',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final conversationRef = _firestore.collection('collectorConversations').doc(
          conversation.conversationId,
        );
    final receiverUid = senderUid == conversation.buyerUid
        ? conversation.artistUid
        : conversation.buyerUid;
    final messageRef = conversationRef.collection('messages').doc();

    final batch = _firestore.batch();
    batch.set(
      messageRef,
      CollectorConversationMessage(
        messageId: messageRef.id,
        senderUid: senderUid,
        senderName: senderName,
        senderEmail: senderEmail,
        text: trimmed,
        type: type,
        createdAt: now,
      ).toMap(),
    );
    final conversationUpdates = <String, dynamic>{
      'latestMessage': trimmed,
      'latestSenderUid': senderUid,
      'lastMessageAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'lastReadAtBy.$senderUid': Timestamp.fromDate(now),
      'unreadCountBy.$senderUid': 0,
    };
    if (receiverUid.isNotEmpty) {
      conversationUpdates['unreadCountBy.$receiverUid'] =
          FieldValue.increment(1);
    }
    batch.update(conversationRef, conversationUpdates);
    batch.update(
        _firestore.collection('artworkInquiries').doc(conversation.inquiryId), {
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();
  }

  Future<void> updateInquiryStatus({
    required CollectorConversation conversation,
    required String nextStatus,
    required String actorUid,
    required String actorName,
    required String actorEmail,
    String note = '',
  }) async {
    if (!_allowedStatuses.contains(nextStatus)) {
      throw ArgumentError('Unsupported inquiry status: $nextStatus');
    }

    final now = DateTime.now();
    final statusLabel = _humanizeStatus(nextStatus);
    final statusMessage = note.trim().isEmpty
        ? '$actorName set status to $statusLabel.'
        : '$actorName set status to $statusLabel: ${note.trim()}';

    final inquiryRef =
        _firestore.collection('artworkInquiries').doc(conversation.inquiryId);
    final conversationRef = _firestore.collection('collectorConversations').doc(
          conversation.conversationId,
        );
    final receiverUid = actorUid == conversation.buyerUid
        ? conversation.artistUid
        : conversation.buyerUid;
    final statusEntry = ArtworkInquiryStatusEvent(
      status: nextStatus,
      note: note.trim().isEmpty ? statusLabel : note.trim(),
      actorUid: actorUid,
      actorName: actorName,
      createdAt: now,
    );

    final messageRef = conversationRef.collection('messages').doc();

    final batch = _firestore.batch();
    batch.set(
      messageRef,
      CollectorConversationMessage(
        messageId: messageRef.id,
        senderUid: actorUid,
        senderName: actorName,
        senderEmail: actorEmail,
        text: statusMessage,
        type: 'status',
        createdAt: now,
      ).toMap(),
    );
    final conversationUpdates = <String, dynamic>{
      'status': nextStatus,
      'latestMessage': statusMessage,
      'latestSenderUid': actorUid,
      'lastMessageAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'lastReadAtBy.$actorUid': Timestamp.fromDate(now),
      'unreadCountBy.$actorUid': 0,
    };
    if (receiverUid.isNotEmpty) {
      conversationUpdates['unreadCountBy.$receiverUid'] =
          FieldValue.increment(1);
    }
    batch.update(conversationRef, conversationUpdates);
    batch.update(inquiryRef, {
      'status': nextStatus,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': FieldValue.arrayUnion([statusEntry.toMap()]),
    });
    await batch.commit();
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userUid,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    await _firestore
        .collection('collectorConversations')
        .doc(conversationId)
        .update({
      'lastReadAtBy.$userUid': now,
      'unreadCountBy.$userUid': 0,
      'updatedAt': now,
    });
  }

  String _humanizeStatus(String status) {
    switch (status) {
      case 'reviewing':
        return 'Reviewing';
      case 'quoted':
        return 'Quoted';
      case 'accepted':
        return 'Accepted';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }
}
