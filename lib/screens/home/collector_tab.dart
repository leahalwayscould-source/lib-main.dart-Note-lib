import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';

import '../../models/artwork_inquiry.dart';
import '../../models/artwork_order.dart';
import '../../models/collector_conversation.dart';
import '../../services/artwork_inquiry_service.dart';
import '../../services/artwork_order_service.dart';
import 'artwork_order_status_screen.dart';
import 'collector_conversation_screen.dart';

enum _ThreadFilter {
  open,
  waitingOnMe,
  closed,
}

class CollectorTab extends StatefulWidget {
  const CollectorTab({super.key});

  @override
  State<CollectorTab> createState() => _CollectorTabState();
}

class _CollectorTabState extends State<CollectorTab>
    with AutomaticKeepAliveClientMixin<CollectorTab> {
  _ThreadFilter _selectedFilter = _ThreadFilter.open;
  final ArtworkInquiryService _inquiryService = ArtworkInquiryService();
  final ArtworkOrderService _orderService = ArtworkOrderService();

  @override
  bool get wantKeepAlive => true;

  Future<void> _toggleConversationClosed({
    required CollectorConversation conversation,
    required ArtworkInquiryService inquiryService,
    required User currentUser,
  }) async {
    final nextStatus = conversation.status == 'closed' ? 'open' : 'closed';
    final actorName = (currentUser.displayName ?? '').trim().isNotEmpty
        ? currentUser.displayName!.trim()
        : (currentUser.email ?? 'Collector');

    try {
      await inquiryService.updateInquiryStatus(
        conversation: conversation,
        nextStatus: nextStatus,
        actorUid: currentUser.uid,
        actorName: actorName,
        actorEmail: currentUser.email ?? '',
        note: nextStatus == 'closed'
            ? 'Conversation closed from collector workspace.'
            : 'Conversation reopened from collector workspace.',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'closed'
                ? 'Conversation marked closed.'
                : 'Conversation reopened.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update status: $error'),
        ),
      );
    }
  }

  int _unreadCount(CollectorConversation conversation, String currentUid) {
    final unreadCount = conversation.unreadCountBy[currentUid];
    if (unreadCount != null) {
      return unreadCount;
    }

    // Backward-compatible fallback for records created before unreadCountBy.
    if (conversation.latestSenderUid == currentUid) {
      return 0;
    }

    final lastReadAt = conversation.lastReadAtBy[currentUid];
    if (lastReadAt == null) {
      return 1;
    }

    return conversation.lastMessageAt.isAfter(lastReadAt) ? 1 : 0;
  }

  bool _hasUnread(CollectorConversation conversation, String currentUid) {
    return _unreadCount(conversation, currentUid) > 0;
  }

  List<CollectorConversation> _applyFilterAndSort(
    List<CollectorConversation> conversations,
    String currentUid,
  ) {
    final filtered = conversations.where((conversation) {
      final hasUnread = _hasUnread(conversation, currentUid);
      switch (_selectedFilter) {
        case _ThreadFilter.open:
          return conversation.status != 'closed';
        case _ThreadFilter.waitingOnMe:
          return conversation.status != 'closed' && hasUnread;
        case _ThreadFilter.closed:
          return conversation.status == 'closed';
      }
    }).toList();

    filtered.sort(
      (a, b) => _compareConversations(
        a,
        b,
        currentUid,
      ),
    );

    return filtered;
  }

  int _compareConversations(
    CollectorConversation a,
    CollectorConversation b,
    String currentUid,
  ) {
    final aHasUnread = _hasUnread(a, currentUid);
    final bHasUnread = _hasUnread(b, currentUid);
    if (aHasUnread != bHasUnread) {
      return aHasUnread ? -1 : 1;
    }

    final aUnreadCount = _unreadCount(a, currentUid);
    final bUnreadCount = _unreadCount(b, currentUid);
    if (aUnreadCount != bUnreadCount) {
      return bUnreadCount.compareTo(aUnreadCount);
    }

    return b.lastMessageAt.compareTo(a.lastMessageAt);
  }

  int _totalUnreadCount(
    List<CollectorConversation> conversations,
    String currentUid,
  ) {
    var total = 0;
    for (final conversation in conversations) {
      total += _unreadCount(conversation, currentUid);
    }
    return total;
  }

  List<ArtworkInquiry> _sortedInquiries(List<ArtworkInquiry> inquiries) {
    final sorted = [...inquiries];
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  List<ArtworkOrder> _sortedOrders(List<ArtworkOrder> orders) {
    final sorted = [...orders];
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  int _waitingOnMeCount(
    List<CollectorConversation> conversations,
    String currentUid,
  ) {
    return conversations.where(
      (conversation) {
        if (conversation.status == 'closed') {
          return false;
        }

        return _hasUnread(conversation, currentUid);
      },
    ).length;
  }

  String _filterLabel() {
    switch (_selectedFilter) {
      case _ThreadFilter.open:
        return 'Open';
      case _ThreadFilter.waitingOnMe:
        return 'Waiting on me';
      case _ThreadFilter.closed:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sign in to track artwork inquiries and artist replies.',
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Collector'),
      ),
      body: StreamBuilder<List<CollectorConversation>>(
        stream: _inquiryService.getBuyerConversations(currentUser.uid),
        builder: (context, buyerConversationSnapshot) {
          return StreamBuilder<List<CollectorConversation>>(
            stream: _inquiryService.getArtistConversations(currentUser.uid),
            builder: (context, artistConversationSnapshot) {
              return StreamBuilder<List<ArtworkInquiry>>(
                stream: _inquiryService.getBuyerInquiries(currentUser.uid),
                builder: (context, inquirySnapshot) {
                  return StreamBuilder<List<ArtworkOrder>>(
                    stream: _orderService.getBuyerOrders(currentUser.uid),
                    builder: (context, orderSnapshot) {
                      final hasAnyData =
                          (buyerConversationSnapshot.data?.isNotEmpty ??
                                  false) ||
                              (artistConversationSnapshot.data?.isNotEmpty ??
                                  false) ||
                              (inquirySnapshot.data?.isNotEmpty ?? false) ||
                              (orderSnapshot.data?.isNotEmpty ?? false);

                      final isAnyWaiting =
                          buyerConversationSnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              artistConversationSnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              inquirySnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              orderSnapshot.connectionState ==
                                  ConnectionState.waiting;

                      if (!hasAnyData && isAnyWaiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final buyerConversations =
                          buyerConversationSnapshot.data ?? [];
                      final artistConversations =
                          artistConversationSnapshot.data ?? [];
                      final filteredBuyerConversations = _applyFilterAndSort(
                        buyerConversations,
                        currentUser.uid,
                      );
                      final filteredArtistConversations = _applyFilterAndSort(
                        artistConversations,
                        currentUser.uid,
                      );
                      final buyerWaitingOnMe = _waitingOnMeCount(
                          buyerConversations, currentUser.uid);
                      final artistWaitingOnMe = _waitingOnMeCount(
                        artistConversations,
                        currentUser.uid,
                      );
                      final totalUnreadCount = _totalUnreadCount(
                            buyerConversations,
                            currentUser.uid,
                          ) +
                          _totalUnreadCount(
                            artistConversations,
                            currentUser.uid,
                          );
                      final inquiries = _sortedInquiries(
                        inquirySnapshot.data ?? [],
                      );
                      final orders = _sortedOrders(
                        orderSnapshot.data ?? [],
                      );

                      if (buyerConversations.isEmpty &&
                          artistConversations.isEmpty &&
                          inquiries.isEmpty &&
                          orders.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 56,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your collector workspace is empty.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Send a purchase inquiry, commission request, or start a direct artwork checkout to see threads and orders here.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _CollectorSummaryCard(
                            conversationCount: buyerConversations.length,
                            inquiryCount: inquiries.length,
                            orderCount: orders.length,
                            artistConversationCount: artistConversations.length,
                            waitingOnMeCount:
                                buyerWaitingOnMe + artistWaitingOnMe,
                            unreadMessageCount: totalUnreadCount,
                          ),
                          const SizedBox(height: 14),
                          _ThreadFilterBar(
                            selectedFilter: _selectedFilter,
                            waitingOnMeCount:
                                buyerWaitingOnMe + artistWaitingOnMe,
                            onFilterChanged: (nextFilter) {
                              setState(() {
                                _selectedFilter = nextFilter;
                              });
                            },
                          ),
                          if (filteredBuyerConversations.isEmpty &&
                              filteredArtistConversations.isEmpty) ...[
                            const SizedBox(height: 14),
                            _FilteredThreadsEmptyState(
                              filterLabel: _filterLabel(),
                            ),
                          ],
                          if (filteredArtistConversations.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Artist Inbox',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...filteredArtistConversations.map(
                              (conversation) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ConversationCard(
                                  conversation: conversation,
                                  roleLabel: 'Artist view',
                                  needsAttention:
                                      conversation.status != 'closed' &&
                                          _hasUnread(
                                            conversation,
                                            currentUser.uid,
                                          ),
                                  unreadCount: _unreadCount(
                                      conversation, currentUser.uid),
                                  onToggleClosed: () {
                                    _toggleConversationClosed(
                                      conversation: conversation,
                                      inquiryService: _inquiryService,
                                      currentUser: currentUser,
                                    );
                                  },
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CollectorConversationScreen(
                                          conversation: conversation,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (inquiries.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Recent Inquiries',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...inquiries.take(6).map(
                                  (inquiry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _InquiryCard(
                                      inquiry: inquiry,
                                    ),
                                  ),
                                ),
                          ],
                          if (orders.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Recent Orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...orders.map(
                              (order) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _OrderCard(
                                  order: order,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ArtworkOrderStatusScreen(
                                          order: order,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (filteredBuyerConversations.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Collector Threads',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...filteredBuyerConversations.map(
                              (conversation) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ConversationCard(
                                  conversation: conversation,
                                  roleLabel: 'Collector view',
                                  needsAttention:
                                      conversation.status != 'closed' &&
                                          _hasUnread(
                                            conversation,
                                            currentUser.uid,
                                          ),
                                  unreadCount: _unreadCount(
                                      conversation, currentUser.uid),
                                  onToggleClosed: () {
                                    _toggleConversationClosed(
                                      conversation: conversation,
                                      inquiryService: _inquiryService,
                                      currentUser: currentUser,
                                    );
                                  },
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CollectorConversationScreen(
                                          conversation: conversation,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CollectorSummaryCard extends StatelessWidget {
  const _CollectorSummaryCard({
    required this.conversationCount,
    required this.inquiryCount,
    required this.orderCount,
    required this.artistConversationCount,
    required this.waitingOnMeCount,
    required this.unreadMessageCount,
  });

  final int conversationCount;
  final int inquiryCount;
  final int orderCount;
  final int artistConversationCount;
  final int waitingOnMeCount;
  final int unreadMessageCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade500,
            Colors.indigo.shade600,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collector Workspace',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$inquiryCount live inquiries, $conversationCount collector threads, $artistConversationCount artist-side threads, and $orderCount artwork orders.',
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            waitingOnMeCount == 0
                ? 'No threads waiting on your reply right now.'
                : '$waitingOnMeCount threads are waiting on your reply.',
            style: TextStyle(color: Colors.indigo[100], height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            unreadMessageCount == 0
                ? 'Inbox is fully read.'
                : '$unreadMessageCount unread messages across your threads.',
            style: TextStyle(
              color: Colors.orange[100],
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadFilterBar extends StatelessWidget {
  const _ThreadFilterBar({
    required this.selectedFilter,
    required this.waitingOnMeCount,
    required this.onFilterChanged,
  });

  final _ThreadFilter selectedFilter;
  final int waitingOnMeCount;
  final ValueChanged<_ThreadFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Open'),
          selected: selectedFilter == _ThreadFilter.open,
          onSelected: (_) => onFilterChanged(_ThreadFilter.open),
        ),
        ChoiceChip(
          label: Text(
            waitingOnMeCount == 0
                ? 'Waiting on me'
                : 'Waiting on me ($waitingOnMeCount)',
          ),
          selected: selectedFilter == _ThreadFilter.waitingOnMe,
          onSelected: (_) => onFilterChanged(_ThreadFilter.waitingOnMe),
        ),
        ChoiceChip(
          label: const Text('Closed'),
          selected: selectedFilter == _ThreadFilter.closed,
          onSelected: (_) => onFilterChanged(_ThreadFilter.closed),
        ),
      ],
    );
  }
}

class _FilteredThreadsEmptyState extends StatelessWidget {
  const _FilteredThreadsEmptyState({required this.filterLabel});

  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'No $filterLabel threads right now.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final ArtworkOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[850],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.artworkTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.artistName,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.note.isNotEmpty ? order.note : order.status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[300], height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: Colors.orange[100],
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(Icons.chevron_right, color: Colors.grey[500]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.roleLabel,
    required this.needsAttention,
    required this.unreadCount,
    required this.onToggleClosed,
    required this.onTap,
  });

  final CollectorConversation conversation;
  final String roleLabel;
  final bool needsAttention;
  final int unreadCount;
  final VoidCallback onToggleClosed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[850],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: _ArtworkThumbnail(
                    imageUrl: conversation.postImageUrl,
                    borderRadius: BorderRadius.circular(12),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.artistName,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 6),
                    if (needsAttention)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              unreadCount <= 1
                                  ? 'Waiting on your reply'
                                  : '$unreadCount unread messages',
                              style: TextStyle(
                                color: Colors.orange[100],
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      conversation.latestMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[300], height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: Colors.deepPurple[100],
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      conversation.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: Colors.blueGrey[100],
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: TextStyle(
                          color: Colors.orange[100],
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  PopupMenuButton<String>(
                    tooltip: conversation.status == 'closed'
                        ? 'Reopen conversation'
                        : 'Mark conversation closed',
                    color: Colors.grey[850],
                    icon: Icon(
                      Icons.more_horiz,
                      color: Colors.grey[400],
                    ),
                    onSelected: (value) {
                      if (value == 'toggle_closed') {
                        onToggleClosed();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'toggle_closed',
                        child: Text(
                          conversation.status == 'closed'
                              ? 'Reopen thread'
                              : 'Mark thread closed',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Icon(Icons.chevron_right, color: Colors.grey[500]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.inquiry,
  });

  final ArtworkInquiry inquiry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: _ArtworkThumbnail(
                imageUrl: inquiry.postImageUrl,
                placeholderIcon: Icons.palette_outlined,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inquiry.postTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  inquiry.intent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              inquiry.status.replaceAll('_', ' '),
              style: TextStyle(
                color: Colors.teal[100],
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  const _ArtworkThumbnail({
    required this.imageUrl,
    this.placeholderIcon = Icons.image_outlined,
    this.borderRadius,
  });

  final String imageUrl;
  final IconData placeholderIcon;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: borderRadius,
        ),
        child: Icon(placeholderIcon),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheHeight: 256,
      memCacheWidth: 256,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => Container(
        color: Colors.grey[800],
        alignment: Alignment.center,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[500],
          ),
        ),
      ),
      errorWidget: (context, _, __) => Container(
        color: Colors.grey[800],
        alignment: Alignment.center,
        child: Icon(
          placeholderIcon,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}
