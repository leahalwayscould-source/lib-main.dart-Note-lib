import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../models/collector_conversation.dart';
import '../../services/artwork_inquiry_service.dart';
import 'collector_tab.dart';
import 'gallery_tab.dart';
import 'pricing_tab.dart';
import 'mockup_tab.dart';
import 'print_on_demand_screen.dart';
import 'profile_tab.dart';
import 'subscription_plans_screen.dart';
import 'subscription_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  final ArtworkInquiryService _inquiryService = ArtworkInquiryService();

  int _collectorUnreadCount = 0;
  StreamSubscription<List<CollectorConversation>>? _buyerSub;
  StreamSubscription<List<CollectorConversation>>? _artistSub;
  List<CollectorConversation> _buyerConversations = [];
  List<CollectorConversation> _artistConversations = [];

  int _conversationUnreadCount(
    CollectorConversation conversation,
    String currentUid,
  ) {
    final unreadCount = conversation.unreadCountBy[currentUid];
    if (unreadCount != null) {
      return unreadCount;
    }

    if (conversation.latestSenderUid == currentUid) {
      return 0;
    }

    final lastReadAt = conversation.lastReadAtBy[currentUid];
    if (lastReadAt == null) {
      return 1;
    }

    return conversation.lastMessageAt.isAfter(lastReadAt) ? 1 : 0;
  }

  int _totalUnread(
    List<CollectorConversation> buyerConversations,
    List<CollectorConversation> artistConversations,
    String currentUid,
  ) {
    var total = 0;
    for (final conversation in buyerConversations) {
      total += _conversationUnreadCount(conversation, currentUid);
    }
    for (final conversation in artistConversations) {
      total += _conversationUnreadCount(conversation, currentUid);
    }
    return total;
  }

  final List<Widget> _tabs = [
    const GalleryTab(),
    const CollectorTab(),
    const PricingTab(),
    const MockupTab(),
    const PrintOnDemandScreen(),
    const ProfileTab(),
    const SubscriptionPlansScreen(),
    const SubscriptionManagementScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
    _subscribeToUnread();
  }

  void _subscribeToUnread() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _buyerSub =
        _inquiryService.getBuyerConversations(user.uid).listen((conversations) {
      _buyerConversations = conversations;
      _refreshUnreadCount(user.uid);
    });
    _artistSub = _inquiryService
        .getArtistConversations(user.uid)
        .listen((conversations) {
      _artistConversations = conversations;
      _refreshUnreadCount(user.uid);
    });
  }

  void _refreshUnreadCount(String uid) {
    final count = _totalUnread(_buyerConversations, _artistConversations, uid);
    if (count != _collectorUnreadCount) {
      setState(() => _collectorUnreadCount = count);
    }
  }

  @override
  void dispose() {
    _buyerSub?.cancel();
    _artistSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      floatingActionButton: _selectedIndex == 6
          ? FloatingActionButton.small(
              heroTag: 'plans_fab',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.shopping_cart_checkout),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'plans_fab',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPlansScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.shopping_cart_checkout),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'premium_fab',
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 6;
                    });
                  },
                  backgroundColor: Colors.deepPurple,
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Premium'),
                ),
              ],
            ),
      bottomNavigationBar: _buildNavigationBar(
        collectorUnreadCount: _collectorUnreadCount,
      ),
    );
  }

  Widget _buildNavigationBar({required int collectorUnreadCount}) {
    final collectorBadgeLabel =
        collectorUnreadCount > 99 ? '99+' : '$collectorUnreadCount';

    return Container(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
        child: GNav(
          backgroundColor: Colors.grey[850]!,
          color: Colors.grey,
          activeColor: Colors.deepPurple,
          tabBackgroundColor: Colors.grey[800]!,
          padding: const EdgeInsets.all(16),
          gap: 8,
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: [
            const GButton(
              icon: Icons.collections,
              text: 'Gallery',
            ),
            GButton(
              icon: Icons.inbox_outlined,
              leading: _CollectorBadgeIcon(
                unreadCount: collectorUnreadCount,
                badgeLabel: collectorBadgeLabel,
              ),
              text: 'Collector',
            ),
            const GButton(
              icon: Icons.attach_money,
              text: 'Pricing',
            ),
            const GButton(
              icon: Icons.preview,
              text: 'Mockup',
            ),
            const GButton(
              icon: Icons.local_print_shop,
              text: 'Print',
            ),
            const GButton(
              icon: Icons.person,
              text: 'Profile',
            ),
            const GButton(
              icon: Icons.shopping_cart_checkout,
              text: 'Packages',
            ),
            const GButton(
              icon: Icons.card_membership,
              text: 'Premium',
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectorBadgeIcon extends StatefulWidget {
  const _CollectorBadgeIcon({
    required this.unreadCount,
    required this.badgeLabel,
  });

  final int unreadCount;
  final String badgeLabel;

  @override
  State<_CollectorBadgeIcon> createState() => _CollectorBadgeIconState();
}

class _CollectorBadgeIconState extends State<_CollectorBadgeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 55,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant _CollectorBadgeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > oldWidget.unreadCount) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          widget.unreadCount == 0
              ? Icons.inbox_outlined
              : Icons.mark_email_unread_outlined,
          color: widget.unreadCount == 0 ? Colors.grey : Colors.orange[200],
        ),
        if (widget.unreadCount > 0)
          Positioned(
            right: -12,
            top: -7,
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.badgeLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
