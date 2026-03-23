import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/artwork_inquiry.dart';
import '../../models/collector_conversation.dart';
import '../../services/artwork_inquiry_service.dart';

class CollectorConversationScreen extends StatefulWidget {
  const CollectorConversationScreen({
    super.key,
    required this.conversation,
  });

  final CollectorConversation conversation;

  @override
  State<CollectorConversationScreen> createState() =>
      _CollectorConversationScreenState();
}

class _CollectorConversationScreenState
    extends State<CollectorConversationScreen> {
  final ArtworkInquiryService _inquiryService = ArtworkInquiryService();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _markThreadRead();
  }

  Future<void> _markThreadRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _inquiryService.markConversationRead(
        conversationId: widget.conversation.conversationId,
        userUid: user.uid,
      );
    } catch (_) {
      // Read state sync failure should not block the conversation UI.
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();
    if (user == null || text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _inquiryService.sendConversationMessage(
        conversation: widget.conversation,
        senderUid: user.uid,
        senderName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email?.split('@').first ?? 'User',
        senderEmail: user.email ?? '',
        text: text,
      );

      _messageController.clear();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message could not be sent right now. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isUpdatingStatus) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _inquiryService.updateInquiryStatus(
        conversation: widget.conversation,
        nextStatus: status,
        actorUid: user.uid,
        actorName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email?.split('@').first ?? 'User',
        actorEmail: user.email ?? '',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status update failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isArtistView =
        currentUid != null && currentUid == conversation.artistUid;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(conversation.artistName),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: conversation.postImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: conversation.postImageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, _) => Container(
                              color: Colors.grey[800],
                            ),
                            errorWidget: (context, _, __) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.image_outlined),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.postTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        conversation.intent,
                        style: TextStyle(
                          color: Colors.deepPurple[200],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        conversation.status == 'open'
                            ? 'Waiting for artist reply'
                            : conversation.status,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<ArtworkInquiry?>(
            stream: _inquiryService.getInquiry(conversation.inquiryId),
            builder: (context, inquirySnapshot) {
              final inquiry = inquirySnapshot.data;
              if (inquiry == null) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Inquiry Timeline',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        _StatusBadge(status: inquiry.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: inquiry.statusHistory.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final event = inquiry.statusHistory[index];
                          return _StatusHistoryCard(event: event);
                        },
                      ),
                    ),
                    if (isArtistView) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusActionChip(
                            label: 'Reviewing',
                            onTap: _isUpdatingStatus
                                ? null
                                : () => _updateStatus('reviewing'),
                          ),
                          _StatusActionChip(
                            label: 'Quoted',
                            onTap: _isUpdatingStatus
                                ? null
                                : () => _updateStatus('quoted'),
                          ),
                          _StatusActionChip(
                            label: 'Accepted',
                            onTap: _isUpdatingStatus
                                ? null
                                : () => _updateStatus('accepted'),
                          ),
                          _StatusActionChip(
                            label: 'Closed',
                            onTap: _isUpdatingStatus
                                ? null
                                : () => _updateStatus('closed'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<CollectorConversationMessage>>(
              stream: _inquiryService.getConversationMessages(
                conversation.conversationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: messages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isBuyer = message.senderUid == conversation.buyerUid;

                    return Align(
                      alignment: isBuyer
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                isBuyer ? Colors.deepPurple : Colors.grey[850],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.senderName,
                                style: TextStyle(
                                  color: isBuyer
                                      ? Colors.white70
                                      : Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(message.text),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Send a message...',
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: Colors.deepPurple[100],
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusHistoryCard extends StatelessWidget {
  const _StatusHistoryCard({required this.event});

  final ArtworkInquiryStatusEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.status.replaceAll('_', ' '),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[300], height: 1.3),
          ),
          const Spacer(),
          Text(
            '${event.actorName} • ${event.createdAt.month}/${event.createdAt.day}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusActionChip extends StatelessWidget {
  const _StatusActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.grey[800],
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      side: BorderSide(color: Colors.grey[700]!),
    );
  }
}
