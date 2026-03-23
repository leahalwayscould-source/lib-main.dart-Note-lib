import 'package:flutter/material.dart';
import '../../models/art_post.dart';
import '../../models/artist_user.dart';
import '../../services/art_post_service.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_progress_service.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/brand_mark.dart';
import 'mentorship_intro_screen.dart';
import '../home/home_screen.dart';

class ImmediateInteractionScreen extends StatefulWidget {
  const ImmediateInteractionScreen({
    super.key,
    required this.userId,
    this.primaryMedium,
    required this.careerLevel,
  });

  final String userId;
  final String? primaryMedium;
  final String careerLevel;

  @override
  State<ImmediateInteractionScreen> createState() =>
      _ImmediateInteractionScreenState();
}

class _ImmediateInteractionScreenState
    extends State<ImmediateInteractionScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  final ArtPostService _artPostService = ArtPostService();
  final AuthService _authService = AuthService();
  final OnboardingProgressService _progressService =
      OnboardingProgressService();
  late final Future<_DiscoveryBundle> _discoveryFuture;

  @override
  void initState() {
    super.initState();
    _discoveryFuture = _loadDiscovery();
  }

  Future<_DiscoveryBundle> _loadDiscovery() async {
    try {
      final results = await Future.wait<Object>([
        _artPostService.getRecentPosts(limit: 12),
        _authService.getRecentArtists(excludeUserId: widget.userId, limit: 8),
      ]);

      final posts = _buildDiscoveryPosts(
        posts: results[0] as List<ArtPost>,
        medium: widget.primaryMedium,
        currentUserId: widget.userId,
      );
      final artists = _buildDiscoveryArtists(
        artists: results[1] as List<ArtistUser>,
        medium: widget.primaryMedium,
      );

      return _DiscoveryBundle(posts: posts, artists: artists);
    } catch (_) {
      return const _DiscoveryBundle(posts: [], artists: []);
    }
  }

  Future<void> _recordFeedback(_StylePost post) async {
    try {
      await _onboardingService.recordFirstFeedback(
        userId: widget.userId,
        postArtist: post.artist,
        challenge: post.challenge,
      );
    } catch (_) {
      // Never block onboarding when persistence fails.
    }
  }

  Future<void> _recordFollow(_SuggestedArtist artist) async {
    try {
      await _onboardingService.recordFollow(
        userId: widget.userId,
        artistName: artist.name,
      );
    } catch (_) {
      // Never block onboarding when persistence fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1016), Color(0xFF101D29), Color(0xFF151018)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<_DiscoveryBundle>(
            future: _discoveryFuture,
            builder: (context, snapshot) {
              final livePosts = snapshot.data?.posts ?? const <_StylePost>[];
              final liveArtists =
                  snapshot.data?.artists ?? const <_SuggestedArtist>[];
              final posts = livePosts.isNotEmpty
                  ? livePosts
                  : _postsForMedium(widget.primaryMedium);
              final artists = liveArtists.isNotEmpty
                  ? liveArtists
                  : _artistsForMedium(widget.primaryMedium);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                        child: BrandMark(size: 28, showWordmark: false)),
                    const SizedBox(height: 16),
                    const Center(child: _StepDots(currentStep: 3)),
                    const SizedBox(height: 22),
                    Text(
                      'Minute 5-7: Immediate interaction',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF7E9CF7),
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Leave your first feedback',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start with one quick comment on a piece that matches your style, then follow a few artists to shape your feed.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8EA0B3),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _ContextPills(
                      primaryMedium: widget.primaryMedium,
                      careerLevel: widget.careerLevel,
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Posts matched to your style',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...posts.map((post) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PostCard(
                            post: post,
                            onFeedbackLeft: _recordFeedback,
                          ),
                        )),
                    const SizedBox(height: 18),
                    Text(
                      'Suggested artists to follow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...artists.map((artist) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ArtistSuggestionRow(
                            artist: artist,
                            onFollow: _recordFollow,
                          ),
                        )),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _goMentorship,
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: const Text('Continue to mentorship options →'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _goHome,
                        child: const Text('Skip for now'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _goHome() async {
    final navigator = Navigator.of(context);
    await _progressService.setStage(widget.userId, OnboardingStage.completed);
    if (!mounted) return;
    navigator.pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _goMentorship() async {
    final navigator = Navigator.of(context);
    await _progressService.setStage(widget.userId, OnboardingStage.mentorship);
    if (!mounted) return;
    navigator.pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => MentorshipIntroScreen(
          userId: widget.userId,
          primaryMedium: widget.primaryMedium,
          careerLevel: widget.careerLevel,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _ContextPills extends StatelessWidget {
  const _ContextPills({required this.primaryMedium, required this.careerLevel});

  final String? primaryMedium;
  final String careerLevel;

  @override
  Widget build(BuildContext context) {
    final mediumLabel = _readableMedium(primaryMedium ?? 'mixed_media');
    final levelLabel = careerLevel[0].toUpperCase() + careerLevel.substring(1);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoPill(
          icon: Icons.palette_outlined,
          label: 'Style: $mediumLabel',
          color: const Color(0xFF32C7B8),
        ),
        _InfoPill(
          icon: Icons.trending_up_rounded,
          label: 'Level: $levelLabel',
          color: const Color(0xFFE8B86D),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121C27),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.onFeedbackLeft,
  });

  final _StylePost post;
  final Future<void> Function(_StylePost post) onFeedbackLeft;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _feedbackLeft = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141D27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF243242)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: widget.post.color.withValues(alpha: 0.25),
                backgroundImage: widget.post.avatarUrl.isNotEmpty
                    ? NetworkImage(widget.post.avatarUrl)
                    : null,
                child: widget.post.avatarUrl.isEmpty
                    ? Text(
                        widget.post.artist.substring(0, 1),
                        style: TextStyle(
                          color: widget.post.color,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.artist,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.post.styleLabel,
                      style: const TextStyle(
                        color: Color(0xFF8EA0B3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _Tag(text: widget.post.challenge, color: widget.post.color),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  widget.post.color.withValues(alpha: 0.22),
                  const Color(0xFF101923),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.post.preview,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFEAF2F8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.post.prompt,
            style: const TextStyle(
              color: Color(0xFF9BB1C6),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _feedbackLeft
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _feedbackLeft = true);
                      await widget.onFeedbackLeft(widget.post);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content:
                              Text('Great start. Your first feedback is live.'),
                        ),
                      );
                    },
              icon: Icon(
                _feedbackLeft
                    ? Icons.check_circle_outline_rounded
                    : Icons.forum_outlined,
                size: 18,
              ),
              label: Text(
                _feedbackLeft ? 'Feedback left' : 'Leave your first feedback',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistSuggestionRow extends StatefulWidget {
  const _ArtistSuggestionRow({
    required this.artist,
    required this.onFollow,
  });

  final _SuggestedArtist artist;
  final Future<void> Function(_SuggestedArtist artist) onFollow;

  @override
  State<_ArtistSuggestionRow> createState() => _ArtistSuggestionRowState();
}

class _ArtistSuggestionRowState extends State<_ArtistSuggestionRow> {
  bool _followed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131B25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF243242)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: widget.artist.accent.withValues(alpha: 0.25),
            backgroundImage: widget.artist.avatarUrl.isNotEmpty
                ? NetworkImage(widget.artist.avatarUrl)
                : null,
            child: widget.artist.avatarUrl.isEmpty
                ? Text(
                    widget.artist.name.substring(0, 1),
                    style: TextStyle(
                      color: widget.artist.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.artist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.artist.niche,
                  style: const TextStyle(
                    color: Color(0xFF8EA0B3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: _followed
                ? null
                : () async {
                    setState(() => _followed = true);
                    await widget.onFollow(widget.artist);
                  },
            child: Text(_followed ? 'Following' : 'Follow'),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final active = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF32C7B8) : const Color(0xFF2B3948),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _StylePost {
  const _StylePost({
    required this.artist,
    required this.styleLabel,
    required this.challenge,
    required this.prompt,
    required this.preview,
    required this.color,
    this.avatarUrl = '',
  });

  final String artist;
  final String styleLabel;
  final String challenge;
  final String prompt;
  final String preview;
  final Color color;
  final String avatarUrl;
}

class _SuggestedArtist {
  const _SuggestedArtist({
    required this.name,
    required this.niche,
    required this.accent,
    this.avatarUrl = '',
  });

  final String name;
  final String niche;
  final Color accent;
  final String avatarUrl;
}

class _DiscoveryBundle {
  const _DiscoveryBundle({required this.posts, required this.artists});

  final List<_StylePost> posts;
  final List<_SuggestedArtist> artists;
}

List<_StylePost> _postsForMedium(String? medium) {
  final readable = _readableMedium(medium ?? 'mixed_media');
  return [
    _StylePost(
      artist: 'Mila Rowan',
      styleLabel: '$readable studies',
      challenge: 'Color',
      prompt: 'What is one thing you would adjust in the color balance?',
      preview: 'Study series: dusk palette and warm highlights',
      color: const Color(0xFF32C7B8),
    ),
    _StylePost(
      artist: 'Ari West',
      styleLabel: '$readable composition',
      challenge: 'Composition',
      prompt: 'Where does your eye land first, and what should move?',
      preview: 'Work in progress: layered frame and focal point tests',
      color: const Color(0xFFE8B86D),
    ),
    _StylePost(
      artist: 'Juno Hart',
      styleLabel: '$readable lighting',
      challenge: 'Depth',
      prompt: 'How could this piece feel more dimensional?',
      preview: 'Final pass: contrast and edge control checks',
      color: const Color(0xFF7E9CF7),
    ),
  ];
}

List<_SuggestedArtist> _artistsForMedium(String? medium) {
  final readable = _readableMedium(medium ?? 'mixed_media');
  return [
    _SuggestedArtist(
      name: 'Lena Cortez',
      niche: '$readable process breakdowns',
      accent: const Color(0xFF32C7B8),
    ),
    _SuggestedArtist(
      name: 'Noah Kim',
      niche: '$readable critique circles',
      accent: const Color(0xFFE8B86D),
    ),
    _SuggestedArtist(
      name: 'Sera Vale',
      niche: '$readable business tips',
      accent: const Color(0xFF7E9CF7),
    ),
    _SuggestedArtist(
      name: 'Tariq Moss',
      niche: '$readable timed challenges',
      accent: const Color(0xFFD46FCF),
    ),
  ];
}

String _readableMedium(String medium) {
  switch (medium) {
    case 'digital':
      return 'Digital art';
    case 'painting':
      return 'Painting';
    case 'drawing':
      return 'Drawing';
    case 'photography':
      return 'Photography';
    case 'sculpture':
      return 'Sculpture';
    case 'printmaking':
      return 'Printmaking';
    case 'textile':
      return 'Textile';
    case 'mixed_media':
      return 'Mixed media';
    default:
      return 'Art';
  }
}

List<_StylePost> _buildDiscoveryPosts({
  required List<ArtPost> posts,
  required String? medium,
  required String currentUserId,
}) {
  final rankedPosts =
      posts.where((post) => post.artistUid != currentUserId).toList()
        ..sort(
          (left, right) => _postMatchScore(right, medium)
              .compareTo(_postMatchScore(left, medium)),
        );

  return rankedPosts.take(3).toList().asMap().entries.map((entry) {
    final index = entry.key;
    final post = entry.value;
    final challenge = _challengeForPost(post);
    final color = _discoveryPalette[index % _discoveryPalette.length];

    return _StylePost(
      artist: post.artistName,
      styleLabel: _styleLabelForPost(post),
      challenge: challenge,
      prompt: _promptForChallenge(challenge),
      preview: post.title.isNotEmpty ? post.title : post.description,
      color: color,
      avatarUrl: post.artistProfileImage,
    );
  }).toList();
}

List<_SuggestedArtist> _buildDiscoveryArtists({
  required List<ArtistUser> artists,
  required String? medium,
}) {
  final rankedArtists = artists.toList()
    ..sort(
      (left, right) => _artistMatchScore(right, medium)
          .compareTo(_artistMatchScore(left, medium)),
    );

  return rankedArtists.take(4).toList().asMap().entries.map((entry) {
    final index = entry.key;
    final artist = entry.value;
    final color = _discoveryPalette[index % _discoveryPalette.length];

    return _SuggestedArtist(
      name: artist.displayName,
      niche: _artistNiche(artist, medium),
      accent: color,
      avatarUrl: artist.profileImageUrl,
    );
  }).toList();
}

int _postMatchScore(ArtPost post, String? medium) {
  final query = _mediumKeywords(medium);
  final haystack = [post.medium, post.style, post.description, ...post.tags]
      .join(' ')
      .toLowerCase();

  var score = post.likeCount + post.critiqueCount + post.viewCount;
  for (final keyword in query) {
    if (haystack.contains(keyword)) {
      score += 50;
    }
  }

  return score;
}

int _artistMatchScore(ArtistUser artist, String? medium) {
  final query = _mediumKeywords(medium);
  final haystack = [artist.bio, ...artist.specialties].join(' ').toLowerCase();

  var score = artist.totalCritiques + artist.averageRating.round();
  for (final keyword in query) {
    if (haystack.contains(keyword)) {
      score += 50;
    }
  }

  return score;
}

String _styleLabelForPost(ArtPost post) {
  final style = post.style.trim();
  final medium = post.medium.trim();
  if (style.isEmpty) {
    return medium;
  }
  return '$medium $style';
}

String _challengeForPost(ArtPost post) {
  final text =
      [post.description, post.style, ...post.tags].join(' ').toLowerCase();
  if (text.contains('light') || text.contains('shadow')) {
    return 'Lighting';
  }
  if (text.contains('color') || text.contains('palette')) {
    return 'Color';
  }
  if (text.contains('compo') || text.contains('layout')) {
    return 'Composition';
  }
  return 'Depth';
}

String _promptForChallenge(String challenge) {
  switch (challenge) {
    case 'Lighting':
      return 'Where could the lighting push the focal point more clearly?';
    case 'Color':
      return 'What is one thing you would adjust in the color balance?';
    case 'Composition':
      return 'Where does your eye land first, and what should move?';
    default:
      return 'How could this piece feel more dimensional?';
  }
}

String _artistNiche(ArtistUser artist, String? medium) {
  if (artist.specialties.isNotEmpty) {
    return artist.specialties.take(2).join(' • ');
  }

  final bio = artist.bio.trim();
  if (bio.isNotEmpty) {
    return bio;
  }

  return '${_readableMedium(medium ?? 'mixed_media')} feedback and process notes';
}

List<String> _mediumKeywords(String? medium) {
  switch (medium) {
    case 'digital':
      return ['digital', 'illustration', 'concept'];
    case 'painting':
      return ['painting', 'oil', 'acrylic', 'canvas'];
    case 'drawing':
      return ['drawing', 'sketch', 'graphite', 'ink'];
    case 'photography':
      return ['photo', 'photography', 'portrait', 'editorial'];
    case 'sculpture':
      return ['sculpt', 'ceramic', 'clay', '3d'];
    case 'printmaking':
      return ['print', 'etch', 'linocut', 'screenprint'];
    case 'textile':
      return ['textile', 'fiber', 'fabric', 'weaving'];
    case 'mixed_media':
      return ['mixed', 'collage', 'assemblage'];
    default:
      return ['art'];
  }
}

const List<Color> _discoveryPalette = [
  Color(0xFF32C7B8),
  Color(0xFFE8B86D),
  Color(0xFF7E9CF7),
  Color(0xFFD46FCF),
];
