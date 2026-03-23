import 'package:flutter/material.dart';
import '../../models/art_post.dart';
import '../../widgets/brand_mark.dart';
import 'merch_catalog_screen.dart';
import 'mockup_tab.dart';
import 'pricing_tab.dart';
import 'subscription_plans_screen.dart';

const _demoBg = Color(0xFF0B1016);
const _demoCard = Color(0xFF141D27);
const _demoAccent = Color(0xFF32C7B8);
const _demoWarm = Color(0xFFE8B86D);

enum _DemoEntryPath { artist, collector, explore }

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

class _DemoArtist {
  final String id;
  final String name;
  final String specialty;
  final String avatarUrl;
  final String bio;
  final int followers;
  final int posts;

  const _DemoArtist({
    required this.id,
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.bio,
    required this.followers,
    required this.posts,
  });
}

class _DemoPost {
  final _DemoArtist artist;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> tags;
  final String medium;
  final double price;
  final int likes;
  final int comments;
  bool liked;

  _DemoPost({
    required this.artist,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tags,
    required this.medium,
    required this.price,
    required this.likes,
    required this.comments,
  }) : liked = false;
}

class _DemoComment {
  final String author;
  final String message;

  const _DemoComment({required this.author, required this.message});
}

class _DemoMessage {
  final String text;
  final String time;
  final bool fromYou;

  const _DemoMessage({
    required this.text,
    required this.time,
    required this.fromYou,
  });
}

class _DemoConversation {
  final _DemoArtist artist;
  final List<_DemoMessage> messages;
  int unreadCount;

  _DemoConversation({
    required this.artist,
    required this.messages,
    required this.unreadCount,
  });
}

class _DemoNotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  bool isRead;

  _DemoNotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  }) : isRead = false;
}

final _demoArtists = [
  const _DemoArtist(
    id: 'sofia-reyes',
    name: 'Sofia Reyes',
    specialty: 'Digital Illustration',
    avatarUrl: 'https://i.pravatar.cc/150?img=47',
    bio:
        'Digital artist blending surrealism with pop culture. 10 years creating worlds one pixel at a time.',
    followers: 4821,
    posts: 38,
  ),
  const _DemoArtist(
    id: 'marcus-webb',
    name: 'Marcus Webb',
    specialty: 'Oil Painting',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    bio:
        'Traditional oil painter focused on landscapes and portraiture. Based in Portland, Oregon.',
    followers: 2340,
    posts: 21,
  ),
  const _DemoArtist(
    id: 'aiko-tanaka',
    name: 'Aiko Tanaka',
    specialty: 'Watercolor',
    avatarUrl: 'https://i.pravatar.cc/150?img=32',
    bio: 'Japanese-inspired watercolor botanicals. All work ships worldwide.',
    followers: 7102,
    posts: 55,
  ),
  const _DemoArtist(
    id: 'dev-patel',
    name: 'Dev Patel',
    specialty: 'Photography',
    avatarUrl: 'https://i.pravatar.cc/150?img=61',
    bio: 'Street & documentary photography. Every frame tells a story.',
    followers: 3310,
    posts: 44,
  ),
];

List<_DemoPost> _buildDemoPosts() => [
      _DemoPost(
        artist: _demoArtists[0],
        title: 'Neon Dreams',
        description:
            'A surrealist cityscape at twilight where neon signs bleed into the fog.',
        imageUrl: 'https://picsum.photos/seed/art1/600/500',
        tags: ['digital', 'neon', 'cityscape', 'surrealism'],
        medium: 'Digital',
        price: 280,
        likes: 142,
        comments: 18,
      ),
      _DemoPost(
        artist: _demoArtists[2],
        title: 'Sakura Morning',
        description:
            'Cherry blossoms catching soft morning light. Painted with a single brush in one sitting.',
        imageUrl: 'https://picsum.photos/seed/art2/600/500',
        tags: ['watercolor', 'floral', 'japanese', 'botanical'],
        medium: 'Watercolor',
        price: 420,
        likes: 389,
        comments: 47,
      ),
      _DemoPost(
        artist: _demoArtists[1],
        title: 'Storm Over the Valley',
        description:
            'Dramatic storm clouds building over rolling hills. Oil on linen, 24x36 inches.',
        imageUrl: 'https://picsum.photos/seed/art3/600/500',
        tags: ['oil', 'landscape', 'dramatic', 'sky'],
        medium: 'Oil',
        price: 1200,
        likes: 207,
        comments: 31,
      ),
      _DemoPost(
        artist: _demoArtists[3],
        title: 'Rush Hour',
        description:
            'Motion blur captures the relentless energy of a city that never slows down.',
        imageUrl: 'https://picsum.photos/seed/art4/600/500',
        tags: ['photography', 'street', 'motion', 'urban'],
        medium: 'Photography',
        price: 350,
        likes: 91,
        comments: 12,
      ),
      _DemoPost(
        artist: _demoArtists[0],
        title: 'Void Walker',
        description:
            'A lone figure stepping into a fractured dimensional rift. Commission available.',
        imageUrl: 'https://picsum.photos/seed/art5/600/500',
        tags: ['digital', 'scifi', 'fantasy', 'character'],
        medium: 'Digital',
        price: 195,
        likes: 264,
        comments: 35,
      ),
      _DemoPost(
        artist: _demoArtists[2],
        title: 'Wild Poppies',
        description:
            'Field of red poppies in full bloom. Limited edition prints available.',
        imageUrl: 'https://picsum.photos/seed/art6/600/500',
        tags: ['watercolor', 'floral', 'landscape', 'red'],
        medium: 'Watercolor',
        price: 180,
        likes: 512,
        comments: 63,
      ),
    ];

List<_DemoConversation> _buildDemoConversations() => [
      _DemoConversation(
        artist: _demoArtists[2],
        unreadCount: 2,
        messages: const [
          _DemoMessage(
            text:
                'Your watercolor textures are beautiful. Would you be open to a print swap?',
            time: '9:12 AM',
            fromYou: false,
          ),
          _DemoMessage(
            text: 'Absolutely. I would love to see what size you had in mind.',
            time: '9:14 AM',
            fromYou: true,
          ),
          _DemoMessage(
            text:
                'Maybe an 11x14. I also wanted to ask about your palette choices.',
            time: '9:18 AM',
            fromYou: false,
          ),
        ],
      ),
      _DemoConversation(
        artist: _demoArtists[1],
        unreadCount: 1,
        messages: const [
          _DemoMessage(
            text:
                'That storm painting would look great in a collector newsletter.',
            time: 'Yesterday',
            fromYou: false,
          ),
          _DemoMessage(
            text: 'Thanks. I am putting together a limited release next week.',
            time: 'Yesterday',
            fromYou: true,
          ),
        ],
      ),
      _DemoConversation(
        artist: _demoArtists[3],
        unreadCount: 0,
        messages: const [
          _DemoMessage(
            text:
                'I know a cafe owner looking for a small urban photography series.',
            time: 'Mon',
            fromYou: false,
          ),
          _DemoMessage(
            text: 'Send them my way. I have three framed pieces ready.',
            time: 'Mon',
            fromYou: true,
          ),
        ],
      ),
    ];

List<_DemoNotificationItem> _buildDemoNotifications() => [
      _DemoNotificationItem(
        icon: Icons.favorite,
        title: 'Neon Dreams got 12 new likes',
        subtitle: 'Artists in your network are engaging with your work.',
        time: '5m',
      ),
      _DemoNotificationItem(
        icon: Icons.comment,
        title: 'Marcus Webb left a critique',
        subtitle: '"The color contrast gives this real momentum."',
        time: '22m',
      ),
      _DemoNotificationItem(
        icon: Icons.person_add,
        title: 'Aiko Tanaka followed you',
        subtitle: 'You now have a new collector-friendly connection.',
        time: '1h',
      ),
      _DemoNotificationItem(
        icon: Icons.local_offer,
        title: 'New commission inquiry',
        subtitle: 'Someone is interested in a variation of Void Walker.',
        time: '3h',
      ),
    ];

ArtPost _demoPostToArtPost(_DemoPost post) {
  final now = DateTime.now();
  final demoPostId =
      '${post.artist.id}-${post.title.toLowerCase().replaceAll(' ', '-')}';
  return ArtPost(
    postId: demoPostId,
    artistUid: post.artist.id,
    artistName: post.artist.name,
    artistProfileImage: post.artist.avatarUrl,
    title: post.title,
    description: post.description,
    imageUrl: post.imageUrl,
    tags: post.tags,
    medium: post.medium,
    style: 'Demo',
    askingPrice: post.price,
    viewCount: 0,
    likeCount: post.likes,
    critiqueCount: post.comments,
    likedBy: const [],
    createdAt: now,
    updatedAt: now,
    imageUrls: [post.imageUrl],
  );
}

// ---------------------------------------------------------------------------
// Main demo screen
// ---------------------------------------------------------------------------

class DemoExploreScreen extends StatefulWidget {
  const DemoExploreScreen({super.key});

  @override
  State<DemoExploreScreen> createState() => _DemoExploreScreenState();
}

class _DemoExploreScreenState extends State<DemoExploreScreen> {
  int _selectedIndex = 0;
  _DemoEntryPath? _entryPath;
  bool _showPathGuide = false;
  bool _focusOnTabs = true;
  late final List<_DemoPost> _posts;
  late final Set<String> _followedArtistIds;
  late final Map<int, List<_DemoComment>> _extraComments;
  late final Set<int> _savedPostIndexes;
  late final List<_DemoConversation> _conversations;
  late final List<_DemoNotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _posts = _buildDemoPosts();
    _followedArtistIds = <String>{_demoArtists[2].id};
    _extraComments = <int, List<_DemoComment>>{};
    _savedPostIndexes = <int>{1, 4};
    _conversations = _buildDemoConversations();
    _notifications = _buildDemoNotifications();
  }

  void _toggleFollow(_DemoArtist artist) {
    setState(() {
      if (_followedArtistIds.contains(artist.id)) {
        _followedArtistIds.remove(artist.id);
      } else {
        _followedArtistIds.add(artist.id);
      }
    });
  }

  void _addComment(int postIndex, String message) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }

    setState(() {
      _extraComments.putIfAbsent(postIndex, () => <_DemoComment>[]).add(
            _DemoComment(author: 'You', message: trimmedMessage),
          );
    });
  }

  int _commentCountFor(int postIndex) {
    return _posts[postIndex].comments +
        (_extraComments[postIndex]?.length ?? 0);
  }

  void _toggleSaved(int postIndex) {
    setState(() {
      if (_savedPostIndexes.contains(postIndex)) {
        _savedPostIndexes.remove(postIndex);
      } else {
        _savedPostIndexes.add(postIndex);
      }
    });
  }

  int get _unreadInboxCount =>
      _conversations.fold(0, (sum, thread) => sum + thread.unreadCount);

  int get _unreadNotificationCount =>
      _notifications.where((item) => !item.isRead).length;

  void _choosePath(_DemoEntryPath path) {
    setState(() {
      _entryPath = path;
      _showPathGuide = true;
      _focusOnTabs = true;
      switch (path) {
        case _DemoEntryPath.artist:
          _selectedIndex = 0;
          break;
        case _DemoEntryPath.collector:
          _selectedIndex = 1;
          break;
        case _DemoEntryPath.explore:
          _selectedIndex = 0;
          break;
      }
    });
  }

  void _resetPath() {
    setState(() {
      _entryPath = null;
      _showPathGuide = false;
      _focusOnTabs = true;
    });
  }

  void _dismissGuide() {
    setState(() {
      _showPathGuide = false;
    });
  }

  void _openInbox() {
    setState(() {
      for (final thread in _conversations) {
        thread.unreadCount = 0;
      }
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DemoInboxScreen(conversations: _conversations),
      ),
    );
  }

  void _openNotifications() {
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DemoNotificationsScreen(
          notifications: _notifications,
          posts: _posts,
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DemoSearchScreen(
          posts: _posts,
          followedArtistIds: _followedArtistIds,
          savedPostIndexes: _savedPostIndexes,
          onToggleFollow: _toggleFollow,
          onToggleSaved: _toggleSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_entryPath == null) {
      return _DemoEntryScreen(onChoosePath: _choosePath);
    }

    final tabs = <Widget>[
      _DemoGalleryTab(
        posts: _posts,
        followedArtistIds: _followedArtistIds,
        commentCountFor: _commentCountFor,
        extraComments: _extraComments,
        onLikeToggle: (i) => setState(() => _posts[i].liked = !_posts[i].liked),
        onToggleFollow: _toggleFollow,
        onAddComment: _addComment,
      ),
      _DemoCollectorTab(
        posts: _posts,
        savedPostIndexes: _savedPostIndexes,
        followedArtistIds: _followedArtistIds,
        onToggleSaved: _toggleSaved,
        onToggleFollow: _toggleFollow,
      ),
      const PricingTab(),
      const MockupTab(),
      _DemoProfileTab(
          artist: _demoArtists[0],
          posts: _posts.where((p) => p.artist == _demoArtists[0]).toList()),
      const SubscriptionPlansScreen(),
    ];

    final heroTitle = switch (_entryPath!) {
      _DemoEntryPath.artist =>
        'Artist mode keeps your creation, community, and profile tools front and center.',
      _DemoEntryPath.collector =>
        'Collector mode highlights discovery, saved works, and commission-ready artists.',
      _DemoEntryPath.explore =>
        'Explore mode lets you move through the full marketplace without signing in.',
    };

    final heroSubtitle = switch (_entryPath!) {
      _DemoEntryPath.artist =>
        'Check the gallery feed, answer critiques, manage your profile, and jump into conversations with collectors.',
      _DemoEntryPath.collector =>
        'Save work, follow artists, start inquiries, and browse the buyer-facing surfaces of the app.',
      _DemoEntryPath.explore =>
        'Browse the feed, explore collector tools, message artists, and test the interaction flows without signing in.',
    };

    final guideTitle = switch (_entryPath!) {
      _DemoEntryPath.artist => 'Artist setup walkthrough',
      _DemoEntryPath.collector => 'Collector setup walkthrough',
      _DemoEntryPath.explore => 'Marketplace walkthrough',
    };

    final guidePrimaryLabel = switch (_entryPath!) {
      _DemoEntryPath.artist => 'Start In Gallery',
      _DemoEntryPath.collector => 'Open Collector Picks',
      _DemoEntryPath.explore => 'Start Full Tour',
    };

    final guideSteps = switch (_entryPath!) {
      _DemoEntryPath.artist => const [
          'Review the gallery feed and see how artists appear publicly.',
          'Open your profile to preview stats, saved work, and creator positioning.',
          'Check Inbox and Activity to see critique and inquiry flows.',
        ],
      _DemoEntryPath.collector => const [
          'Open the Collector tab to browse curated picks and featured artists.',
          'Save pieces you like and start a mock inquiry from the buyer side.',
          'Follow artists to build a collection-ready feed and activity stream.',
        ],
      _DemoEntryPath.explore => const [
          'Move through Gallery, Collector, Pricing, Mockup, and Profile tabs.',
          'Test comments, follows, inbox threads, and notifications.',
          'Use Switch Path any time if you want a more focused demo route.',
        ],
    };

    final guideAccent = switch (_entryPath!) {
      _DemoEntryPath.artist => _demoAccent,
      _DemoEntryPath.collector => _demoWarm,
      _DemoEntryPath.explore => Colors.white,
    };

    if (_focusOnTabs) {
      return Scaffold(
        backgroundColor: _demoBg,
        appBar: AppBar(
          title: Text(
            switch (_entryPath!) {
              _DemoEntryPath.artist => 'Artist Demo',
              _DemoEntryPath.collector => 'Collector Demo',
              _DemoEntryPath.explore => 'Explore Demo',
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Subscription packages',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Inbox',
                  onPressed: _openInbox,
                  icon: const Icon(Icons.mail_outline),
                ),
                if (_unreadInboxCount > 0)
                  Positioned(
                    right: 8,
                    top: 10,
                    child: _MiniBadge(count: _unreadInboxCount),
                  ),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Activity',
                  onPressed: _openNotifications,
                  icon: const Icon(Icons.notifications_none),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 10,
                    child: _MiniBadge(count: _unreadNotificationCount),
                  ),
              ],
            ),
            IconButton(
              tooltip: 'Switch path',
              onPressed: _resetPath,
              icon: const Icon(Icons.swap_horiz),
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: tabs,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.collections), label: 'Gallery'),
                NavigationDestination(
                    icon: Icon(Icons.storefront), label: 'Collector'),
                NavigationDestination(
                    icon: Icon(Icons.attach_money), label: 'Pricing'),
                NavigationDestination(
                    icon: Icon(Icons.preview), label: 'Mockup'),
                NavigationDestination(
                    icon: Icon(Icons.person), label: 'Profile'),
                NavigationDestination(
                    icon: Icon(Icons.shopping_cart_checkout),
                    label: 'Packages'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _demoBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF13343A),
                  const Color(0xFF0F1821),
                  const Color(0xFF231A13),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _demoWarm.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _demoWarm.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: _demoWarm, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Curated Demo',
                            style: TextStyle(
                              color: _demoWarm,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ArtConnect Atelier',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 12,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionPlansScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('View Packages'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _resetPath,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Switch Path'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  heroTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  heroSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _HeroStat(label: 'Artists Live', value: '48'),
                    _HeroStat(label: 'Works Saved', value: '126'),
                    _HeroStat(label: 'New Critiques', value: '19'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width > 700
                      ? (MediaQuery.of(context).size.width - 56) / 3
                      : (MediaQuery.of(context).size.width - 44) / 2,
                  child: _QuickAccessCard(
                    icon: Icons.search,
                    label: 'Search',
                    count: 0,
                    onTap: _openSearch,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 700
                      ? (MediaQuery.of(context).size.width - 56) / 3
                      : (MediaQuery.of(context).size.width - 44) / 2,
                  child: _QuickAccessCard(
                    icon: Icons.mail_outline,
                    label: 'Inbox',
                    count: _unreadInboxCount,
                    onTap: _openInbox,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width > 700
                      ? (MediaQuery.of(context).size.width - 56) / 3
                      : (MediaQuery.of(context).size.width - 44) / 2,
                  child: _QuickAccessCard(
                    icon: Icons.notifications_none,
                    label: 'Activity',
                    count: _unreadNotificationCount,
                    onTap: _openNotifications,
                  ),
                ),
              ],
            ),
          ),
          if (_showPathGuide)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _PathGuideCard(
                title: guideTitle,
                accent: guideAccent,
                steps: guideSteps,
                primaryLabel: guidePrimaryLabel,
                onPrimaryTap: _dismissGuide,
                onDismiss: _dismissGuide,
              ),
            ),
          Expanded(child: tabs[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.collections), label: 'Gallery'),
              NavigationDestination(
                  icon: Icon(Icons.storefront), label: 'Collector'),
              NavigationDestination(
                  icon: Icon(Icons.attach_money), label: 'Pricing'),
              NavigationDestination(icon: Icon(Icons.preview), label: 'Mockup'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
              NavigationDestination(
                  icon: Icon(Icons.shopping_cart_checkout), label: 'Packages'),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _demoWarm,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DemoEntryScreen extends StatelessWidget {
  const _DemoEntryScreen({required this.onChoosePath});

  final void Function(_DemoEntryPath path) onChoosePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _demoBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B1016),
              Color(0xFF112730),
              Color(0xFF241A12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _demoWarm.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: _demoWarm.withValues(alpha: 0.25)),
                  ),
                  child: const Text(
                    'Choose Your Demo Path',
                    style: TextStyle(
                      color: _demoWarm,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const BrandMark(
                  size: 82,
                  showWordmark: true,
                  align: CrossAxisAlignment.start,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Start as the kind of user you want to explore first.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This demo can open in an artist-focused flow, a collector-focused flow, or the full browse-everything mode.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionPlansScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('View Subscription Packages'),
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView(
                    children: [
                      _EntryChoiceCard(
                        icon: Icons.palette_outlined,
                        title: 'Artist',
                        subtitle:
                            'Focus on the gallery feed, critiques, profile building, and creator conversations.',
                        accent: _demoAccent,
                        buttonLabel: 'Enter Artist Mode',
                        onTap: () => onChoosePath(_DemoEntryPath.artist),
                      ),
                      const SizedBox(height: 14),
                      _EntryChoiceCard(
                        icon: Icons.storefront,
                        title: 'Collector',
                        subtitle:
                            'Jump straight into discovery, saved works, featured artists, and commission intent.',
                        accent: _demoWarm,
                        buttonLabel: 'Enter Collector Mode',
                        onTap: () => onChoosePath(_DemoEntryPath.collector),
                      ),
                      const SizedBox(height: 14),
                      _EntryChoiceCard(
                        icon: Icons.travel_explore,
                        title: 'Browse Everything',
                        subtitle:
                            'Keep all demo surfaces available and move around the whole marketplace freely.',
                        accent: Colors.white,
                        buttonLabel: 'Open Full Demo',
                        onTap: () => onChoosePath(_DemoEntryPath.explore),
                      ),
                    ],
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

class _EntryChoiceCard extends StatelessWidget {
  const _EntryChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _demoCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72), height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: accent.computeLuminance() > 0.5
                    ? const Color(0xFF081012)
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathGuideCard extends StatelessWidget {
  const _PathGuideCard({
    required this.title,
    required this.accent,
    required this.steps,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.onDismiss,
  });

  final String title;
  final Color accent;
  final List<String> steps;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _demoCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.route, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close,
                    color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimaryTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: accent.computeLuminance() > 0.5
                        ? const Color(0xFF081012)
                        : Colors.white,
                  ),
                  child: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  child: const Text('Skip Guide'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo gallery feed
// ---------------------------------------------------------------------------

class _DemoGalleryTab extends StatelessWidget {
  const _DemoGalleryTab({
    required this.posts,
    required this.followedArtistIds,
    required this.commentCountFor,
    required this.extraComments,
    required this.onLikeToggle,
    required this.onToggleFollow,
    required this.onAddComment,
  });
  final List<_DemoPost> posts;
  final Set<String> followedArtistIds;
  final int Function(int index) commentCountFor;
  final Map<int, List<_DemoComment>> extraComments;
  final void Function(int index) onLikeToggle;
  final void Function(_DemoArtist artist) onToggleFollow;
  final void Function(int postIndex, String message) onAddComment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Art Gallery'),
      ),
      backgroundColor: Colors.grey[900],
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _DemoPostDetailScreen(
                  post: post,
                  postIndex: index,
                  commentCount: commentCountFor(index),
                  extraComments: extraComments[index] ?? const <_DemoComment>[],
                  isFollowing: followedArtistIds.contains(post.artist.id),
                  onLikeToggle: onLikeToggle,
                  onToggleFollow: onToggleFollow,
                  onAddComment: onAddComment,
                ),
              ),
            ),
            child: Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artist header
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _DemoArtistProfileScreen(
                                artist: post.artist,
                                isFollowing:
                                    followedArtistIds.contains(post.artist.id),
                                onToggleFollow: onToggleFollow,
                              ),
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage:
                                NetworkImage(post.artist.avatarUrl),
                            radius: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _DemoArtistProfileScreen(
                                      artist: post.artist,
                                      isFollowing: followedArtistIds
                                          .contains(post.artist.id),
                                      onToggleFollow: onToggleFollow,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  post.artist.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              Text(post.artist.specialty,
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text('\$${post.price.toStringAsFixed(0)}'),
                          backgroundColor: Colors.deepPurple,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Image
                  ClipRRect(
                    child: Image.network(
                      post.imageUrl,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 260,
                        color: Colors.grey[800],
                        child: const Center(
                            child: Icon(Icons.image,
                                size: 60, color: Colors.grey)),
                      ),
                    ),
                  ),
                  // Title + description
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Text(post.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15)),
                  ),
                  if (post.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(post.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Colors.grey[300], fontSize: 13)),
                    ),
                  if (post.description.toLowerCase().contains('prints'))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MerchCatalogScreen(
                                  post: _demoPostToArtPost(post),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_mall_outlined),
                          label: const Text('Shop Prints'),
                        ),
                      ),
                    ),
                  // Tags
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Wrap(
                      spacing: 4,
                      children: post.tags
                          .map((t) => Chip(
                                label: Text('#$t',
                                    style: const TextStyle(fontSize: 10)),
                                backgroundColor:
                                    Colors.deepPurple.withValues(alpha: 0.3),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ),
                  // Interactions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        _LikeButton(
                          liked: post.liked,
                          count: post.liked ? post.likes + 1 : post.likes,
                          onTap: () => onLikeToggle(index),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _DemoPostDetailScreen(
                                post: post,
                                postIndex: index,
                                commentCount: commentCountFor(index),
                                extraComments: extraComments[index] ??
                                    const <_DemoComment>[],
                                isFollowing:
                                    followedArtistIds.contains(post.artist.id),
                                onLikeToggle: onLikeToggle,
                                onToggleFollow: onToggleFollow,
                                onAddComment: onAddComment,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.comment,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${commentCountFor(index)}',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(post.medium,
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton(
      {required this.liked, required this.count, required this.onTap});
  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(liked ? Icons.favorite : Icons.favorite_border,
              size: 20, color: liked ? Colors.red : Colors.grey),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(color: liked ? Colors.red : Colors.grey)),
        ],
      ),
    );
  }
}

class _DemoCollectorTab extends StatelessWidget {
  const _DemoCollectorTab({
    required this.posts,
    required this.savedPostIndexes,
    required this.followedArtistIds,
    required this.onToggleSaved,
    required this.onToggleFollow,
  });

  final List<_DemoPost> posts;
  final Set<int> savedPostIndexes;
  final Set<String> followedArtistIds;
  final void Function(int postIndex) onToggleSaved;
  final void Function(_DemoArtist artist) onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final featuredIndexes = <int>[0, 2, 5];
    final savedPosts = savedPostIndexes.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Collector View'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.blueGrey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover artists worth collecting',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Save work, follow artists, and start commission conversations from one place.',
                  style: TextStyle(color: Colors.grey[200], height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _CollectorMetric(label: 'Saved Works', value: '12'),
                    _CollectorMetric(label: 'Open Inquiries', value: '3'),
                    _CollectorMetric(label: 'Followed Artists', value: '9'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Featured artists',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _demoArtists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final artist = _demoArtists[index];
                final isFollowing = followedArtistIds.contains(artist.id);

                return SizedBox(
                  width: 220,
                  child: Container(
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
                            CircleAvatar(
                              backgroundImage: NetworkImage(artist.avatarUrl),
                              radius: 24,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => onToggleFollow(artist),
                              icon: Icon(
                                isFollowing
                                    ? Icons.check_circle
                                    : Icons.person_add,
                                color: isFollowing
                                    ? Colors.tealAccent[200]
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          artist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist.specialty,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const Spacer(),
                        Text(
                          '${artist.followers} followers',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Curated picks',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...featuredIndexes.map((index) {
            final post = posts[index];
            final isSaved = savedPostIndexes.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      post.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '\$${post.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'By ${post.artist.name} • ${post.medium}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          post.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                        if (post.description
                            .toLowerCase()
                            .contains('prints')) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MerchCatalogScreen(
                                      post: _demoPostToArtPost(post),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.local_mall_outlined),
                              label: const Text('Shop Prints'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => onToggleSaved(index),
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                                label: Text(isSaved ? 'Saved' : 'Save'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          _DemoCheckoutScreen(post: post),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.mail_outline),
                                label: const Text('Inquire'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'Saved collection',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: savedPosts.length,
            itemBuilder: (context, index) {
              final postIndex = savedPosts[index];
              final post = posts[postIndex];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          post.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.artist.name,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CollectorMetric extends StatelessWidget {
  const _CollectorMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _demoCard,
              const Color(0xFF182433),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF253646)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _demoAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _demoAccent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    count > 0 ? 'New updates waiting' : 'All caught up',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _demoAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF041114),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo post detail screen (shows comments)
// ---------------------------------------------------------------------------

class _DemoPostDetailScreen extends StatefulWidget {
  const _DemoPostDetailScreen(
      {required this.post,
      required this.postIndex,
      required this.commentCount,
      required this.extraComments,
      required this.isFollowing,
      required this.onLikeToggle,
      required this.onToggleFollow,
      required this.onAddComment});
  final _DemoPost post;
  final int postIndex;
  final int commentCount;
  final List<_DemoComment> extraComments;
  final bool isFollowing;
  final void Function(int) onLikeToggle;
  final void Function(_DemoArtist artist) onToggleFollow;
  final void Function(int postIndex, String message) onAddComment;

  static const _sampleComments = [
    ('Sofia Reyes', 'The lighting in this is absolutely stunning!'),
    ('Marcus Webb', 'How many hours did this take you?'),
    ('Aiko Tanaka', 'The colour palette speaks to me on another level 💜'),
    ('Dev Patel', 'Would love a print of this for my studio wall.'),
    ('Sofia Reyes', 'The layering technique here is masterful.'),
  ];

  @override
  State<_DemoPostDetailScreen> createState() => _DemoPostDetailScreenState();
}

class _DemoPostDetailScreenState extends State<_DemoPostDetailScreen> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final sampleComments = _DemoPostDetailScreen._sampleComments
        .take(post.comments > 5 ? 5 : post.comments)
        .map((comment) => _DemoComment(author: comment.$1, message: comment.$2))
        .toList();
    final comments = [...sampleComments, ...widget.extraComments];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(post.title),
      ),
      body: ListView(
        children: [
          Image.network(post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey[800],
                  child: const Icon(Icons.image, size: 60))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        backgroundImage: NetworkImage(post.artist.avatarUrl),
                        radius: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.artist.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(post.artist.specialty,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => widget.onToggleFollow(post.artist),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.isFollowing
                            ? Colors.white
                            : Colors.deepPurpleAccent,
                        side: BorderSide(
                          color: widget.isFollowing
                              ? Colors.grey[600]!
                              : Colors.deepPurpleAccent,
                        ),
                      ),
                      child: Text(widget.isFollowing ? 'Following' : 'Follow'),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('\$${post.price.toStringAsFixed(0)}'),
                      backgroundColor: Colors.deepPurple,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.description,
                    style: TextStyle(color: Colors.grey[300], height: 1.5)),
                if (post.description.toLowerCase().contains('prints')) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MerchCatalogScreen(
                              post: _demoPostToArtPost(post),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_mall_outlined),
                      label: const Text('Shop Prints'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LikeButton(
                      liked: post.liked,
                      count: post.liked ? post.likes + 1 : post.likes,
                      onTap: () => widget.onLikeToggle(widget.postIndex),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.comment, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${widget.commentCount}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Comments',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 10),
                ...comments.map(
                  (c) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.author,
                            style: const TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(c.message,
                            style: TextStyle(
                                color: Colors.grey[300], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.rate_review,
                              size: 16, color: Colors.deepPurpleAccent),
                          SizedBox(width: 8),
                          Text('Leave a demo critique',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Say something encouraging or constructive',
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () {
                            widget.onAddComment(
                              widget.postIndex,
                              _commentController.text,
                            );
                            if (_commentController.text.trim().isEmpty) {
                              return;
                            }
                            _commentController.clear();
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Post Comment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo artist profile screen (tap an avatar to open)
// ---------------------------------------------------------------------------

class _DemoArtistProfileScreen extends StatelessWidget {
  const _DemoArtistProfileScreen({
    required this.artist,
    required this.isFollowing,
    required this.onToggleFollow,
  });
  final _DemoArtist artist;
  final bool isFollowing;
  final void Function(_DemoArtist artist) onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(artist.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
                backgroundImage: NetworkImage(artist.avatarUrl), radius: 52),
            const SizedBox(height: 14),
            Text(artist.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            const SizedBox(height: 4),
            Text(artist.specialty,
                style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 14)),
            const SizedBox(height: 14),
            Text(artist.bio,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300], height: 1.5)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatPill(label: 'Posts', value: artist.posts.toString()),
                _StatPill(
                    label: 'Followers', value: artist.followers.toString()),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onToggleFollow(artist),
                icon: Icon(isFollowing ? Icons.check : Icons.person_add),
                label: Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}

class _DemoInboxScreen extends StatelessWidget {
  const _DemoInboxScreen({required this.conversations});

  final List<_DemoConversation> conversations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Inbox'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final thread = conversations[index];
          final latest = thread.messages.last;

          return Material(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _DemoChatScreen(conversation: thread),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundImage: NetworkImage(thread.artist.avatarUrl),
              ),
              title: Text(
                thread.artist.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                latest.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    latest.time,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  if (thread.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${thread.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DemoChatScreen extends StatefulWidget {
  const _DemoChatScreen({required this.conversation});

  final _DemoConversation conversation;

  @override
  State<_DemoChatScreen> createState() => _DemoChatScreenState();
}

class _DemoChatScreenState extends State<_DemoChatScreen> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      widget.conversation.messages.add(
        _DemoMessage(text: text, time: 'Now', fromYou: true),
      );
      widget.conversation.messages.add(
        _DemoMessage(
          text:
              'Love that idea. Let me pull together a few references and send them over.',
          time: 'Now',
          fromYou: false,
        ),
      );
    });

    _messageController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final artist = widget.conversation.artist;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(artist.avatarUrl)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist.name),
                Text(
                  artist.specialty,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.conversation.messages.length,
              itemBuilder: (context, index) {
                final message = widget.conversation.messages[index];
                final bubbleColor =
                    message.fromYou ? Colors.deepPurple : Colors.grey[800]!;
                final align = message.fromYou
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start;

                return Column(
                  crossAxisAlignment: align,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: align,
                        children: [
                          Text(
                            message.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message.time,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Write a message',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNotificationsScreen extends StatelessWidget {
  const _DemoNotificationsScreen({
    required this.notifications,
    required this.posts,
  });

  final List<_DemoNotificationItem> notifications;
  final List<_DemoPost> posts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Activity'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return InkWell(
            onTap: () {
              final relatedPost = posts[index % posts.length];
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _DemoNotificationDetailScreen(
                    item: item,
                    relatedPost: relatedPost,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.isRead ? Colors.grey[800]! : Colors.deepPurple,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple.withValues(alpha: 0.2),
                    child: Icon(item.icon, color: Colors.deepPurpleAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            color: Colors.grey[400],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.time,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DemoNotificationDetailScreen extends StatelessWidget {
  const _DemoNotificationDetailScreen({
    required this.item,
    required this.relatedPost,
  });

  final _DemoNotificationItem item;
  final _DemoPost relatedPost;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _demoBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notification Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _demoCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF253646)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _demoAccent.withValues(alpha: 0.14),
                      child: Icon(item.icon, color: _demoAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.subtitle,
                  style: TextStyle(color: Colors.grey[300], height: 1.45),
                ),
                const SizedBox(height: 10),
                Text(
                  'Received ${item.time} ago',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Image.network(
                    relatedPost.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relatedPost.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'By ${relatedPost.artist.name}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Back To Activity'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MerchCatalogScreen(
                                      post: _demoPostToArtPost(relatedPost),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Shop Prints And Merch'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoSearchScreen extends StatefulWidget {
  const _DemoSearchScreen({
    required this.posts,
    required this.followedArtistIds,
    required this.savedPostIndexes,
    required this.onToggleFollow,
    required this.onToggleSaved,
  });

  final List<_DemoPost> posts;
  final Set<String> followedArtistIds;
  final Set<int> savedPostIndexes;
  final void Function(_DemoArtist artist) onToggleFollow;
  final void Function(int postIndex) onToggleSaved;

  @override
  State<_DemoSearchScreen> createState() => _DemoSearchScreenState();
}

class _DemoSearchScreenState extends State<_DemoSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  static const _filters = [
    'All',
    'Digital',
    'Watercolor',
    'Oil',
    'Photography'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredEntries = widget.posts.asMap().entries.where((entry) {
      final post = entry.value;
      final matchesFilter =
          _selectedFilter == 'All' || post.medium == _selectedFilter;
      final matchesQuery = query.isEmpty ||
          post.title.toLowerCase().contains(query) ||
          post.artist.name.toLowerCase().contains(query) ||
          post.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: _demoBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Search & Discover'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search artists, titles, or tags',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filters
                .map(
                  (filter) => ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Results',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          ...filteredEntries.map((entry) {
            final index = entry.key;
            final post = entry.value;
            final isSaved = widget.savedPostIndexes.contains(index);
            final isFollowing =
                widget.followedArtistIds.contains(post.artist.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      post.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '\$${post.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: _demoWarm,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${post.artist.name} • ${post.medium}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => widget.onToggleSaved(index),
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                                label: Text(isSaved ? 'Saved' : 'Save'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    widget.onToggleFollow(post.artist),
                                icon: Icon(
                                  isFollowing
                                      ? Icons.check
                                      : Icons.person_add_alt_1,
                                ),
                                label:
                                    Text(isFollowing ? 'Following' : 'Follow'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MerchCatalogScreen(
                                    post: _demoPostToArtPost(post),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Shop Prints And Merch'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (filteredEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No matching artists or artworks yet. Try a different keyword or medium.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

class _DemoCheckoutScreen extends StatefulWidget {
  const _DemoCheckoutScreen({
    required this.post,
  });

  final _DemoPost post;

  @override
  State<_DemoCheckoutScreen> createState() => _DemoCheckoutScreenState();
}

class _DemoCheckoutScreenState extends State<_DemoCheckoutScreen> {
  final _emailController = TextEditingController(text: 'collector@example.com');
  final _noteController = TextEditingController();
  String _selectedIntent = 'Purchase';
  bool _isPrintMode = false;
  String _selectedPrintType = 'poster';
  String _selectedSize = 'medium';
  int _quantity = 1;
  String _selectedColor = 'black';
  bool _isSubmitting = false;

  static const Map<String, String> _printTypeLabels = {
    'poster': 'Art Poster',
    'canvas': 'Canvas Print',
    'framed': 'Framed Print',
    'tote_bag': 'Tote Bag',
    'phone_case': 'Phone Case',
    'adult_hoodie_pullover': 'Adult Hoodie Pullover',
  };

  static const Map<String, String> _sizeLabels = {
    'small': 'Small',
    'medium': 'Medium',
    'large': 'Large',
    'xlarge': 'XL',
  };

  static const Map<String, Map<String, double>> _printPricing = {
    'poster': {
      'small': 12.99,
      'medium': 19.99,
      'large': 29.99,
      'xlarge': 44.99,
    },
    'canvas': {
      'small': 29.99,
      'medium': 49.99,
      'large': 79.99,
      'xlarge': 119.99,
    },
    'framed': {
      'small': 39.99,
      'medium': 64.99,
      'large': 99.99,
      'xlarge': 149.99,
    },
    'tote_bag': {
      'small': 18.99,
      'medium': 22.99,
      'large': 22.99,
      'xlarge': 22.99,
    },
    'phone_case': {
      'small': 16.99,
      'medium': 16.99,
      'large': 16.99,
      'xlarge': 16.99,
    },
    'adult_hoodie_pullover': {
      'small': 39.99,
      'medium': 42.99,
      'large': 44.99,
      'xlarge': 47.99,
    },
  };

  bool get _isHoodie => _selectedPrintType == 'adult_hoodie_pullover';
  double get _unitPrice =>
      _printPricing[_selectedPrintType]?[_selectedSize] ?? 19.99;
  double get _totalPrice => _unitPrice * _quantity;

  @override
  void initState() {
    super.initState();
    _isPrintMode = false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPrintMode
              ? 'Demo print order submitted for ${widget.post.artist.name}. '
                  'Selected: ${_printTypeLabels[_selectedPrintType]} (${_sizeLabels[_selectedSize]}), qty $_quantity.'
              : 'Demo $_selectedIntent request sent to ${widget.post.artist.name}.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _demoBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isPrintMode ? 'Shop Prints' : 'Checkout / Inquiry'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.post.imageUrl,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 92,
                      height: 92,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.post.artist.name,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${widget.post.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: _demoWarm,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Flow',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.mail_outline),
                label: Text('Request Artist'),
              ),
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.local_mall_outlined),
                label: Text('Shop Prints'),
              ),
            ],
            selected: {_isPrintMode},
            onSelectionChanged: (value) {
              setState(() {
                _isPrintMode = value.first;
              });
            },
          ),
          const SizedBox(height: 18),
          if (_isPrintMode) ...[
            Text(
              'Print / Merch Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedPrintType,
              decoration: const InputDecoration(labelText: 'Product'),
              items: _printTypeLabels.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedPrintType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSize,
              decoration: const InputDecoration(labelText: 'Size'),
              items: _sizeLabels.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedSize = value;
                });
              },
            ),
            if (_isHoodie) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedColor,
                decoration: const InputDecoration(labelText: 'Color'),
                items: const [
                  'black',
                  'white',
                  'navy',
                  'charcoal',
                  'heather_gray',
                  'maroon',
                  'forest_green',
                ]
                    .map(
                      (color) => DropdownMenuItem<String>(
                        value: color,
                        child: Text(color),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedColor = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Quantity', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _quantity <= 1
                      ? null
                      : () => setState(() => _quantity -= 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity', style: const TextStyle(color: Colors.white)),
                IconButton(
                  onPressed: () => setState(() => _quantity += 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(
                  '\$${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _demoWarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          Text(
            _isPrintMode ? 'Order Note' : 'Intent',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          if (!_isPrintMode) ...[
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Purchase', label: Text('Purchase')),
                ButtonSegment(value: 'Commission', label: Text('Commission')),
              ],
              selected: {_selectedIntent},
              onSelectionChanged: (value) {
                setState(() {
                  _selectedIntent = value.first;
                });
              },
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Contact Email',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: _isPrintMode
                  ? 'Any print/merch preferences'
                  : _selectedIntent == 'Purchase'
                      ? 'Message to artist'
                      : 'Describe your commission idea',
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _demoCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF253646)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Demo checkout summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _CheckoutRow(label: 'Artwork', value: widget.post.title),
                _CheckoutRow(label: 'Artist', value: widget.post.artist.name),
                _CheckoutRow(
                  label: 'Mode',
                  value: _isPrintMode ? 'Shop Prints' : _selectedIntent,
                ),
                if (_isPrintMode) ...[
                  _CheckoutRow(
                    label: 'Product',
                    value: _printTypeLabels[_selectedPrintType] ?? 'Print',
                  ),
                  _CheckoutRow(
                    label: 'Size',
                    value: _sizeLabels[_selectedSize] ?? _selectedSize,
                  ),
                  if (_isHoodie)
                    _CheckoutRow(label: 'Color', value: _selectedColor),
                  _CheckoutRow(label: 'Quantity', value: '$_quantity'),
                ],
                _CheckoutRow(
                  label: _isPrintMode ? 'Total' : 'Starting amount',
                  value: _isPrintMode
                      ? '\$${_totalPrice.toStringAsFixed(2)}'
                      : '\$${widget.post.price.toStringAsFixed(0)}',
                  valueColor: _demoWarm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isPrintMode
                      ? Icons.shopping_cart_checkout
                      : Icons.lock_outline),
              label: Text(
                _isSubmitting
                    ? 'Submitting...'
                    : _isPrintMode
                        ? 'Place Demo Print Order'
                        : 'Send Demo Request',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo profile tab (your own artist profile preview)
// ---------------------------------------------------------------------------

class _DemoProfileTab extends StatelessWidget {
  const _DemoProfileTab({required this.artist, required this.posts});
  final _DemoArtist artist;
  final List<_DemoPost> posts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
                backgroundImage: NetworkImage(artist.avatarUrl), radius: 52),
            const SizedBox(height: 14),
            Text(artist.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            const SizedBox(height: 4),
            Text(artist.specialty,
                style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 14)),
            const SizedBox(height: 14),
            Text(artist.bio,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300], height: 1.5)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatPill(label: 'Posts', value: artist.posts.toString()),
                _StatPill(
                    label: 'Followers', value: artist.followers.toString()),
              ],
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('My Artwork',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: posts.length,
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(posts[i].imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.grey))),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sign in to edit your real profile, upload artwork, and connect with other artists.',
                      style: TextStyle(color: Colors.amber, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
