import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/art_post.dart';
import '../../services/auth_service.dart';
import '../../services/art_post_service.dart';
import '../onboarding/onboarding_events_debug_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with AutomaticKeepAliveClientMixin<ProfileTab> {
  final AuthService _authService = AuthService();
  final ArtPostService _artPostService = ArtPostService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  late User? user = _currentUser;
  bool _isEditing = false;

  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = _currentUser?.displayName ?? '';
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(_currentUser!.uid);
    if (profile != null) {
      setState(() {
        _bioController.text = profile.bio;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      await _authService.updateUserProfile(_currentUser!.uid, {
        'displayName': _displayNameController.text,
        'bio': _bioController.text,
      });
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        // authStateChanges in AuthWrapper drives navigation after sign-out.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Artist Profile'),
        actions: [
          GestureDetector(
            onTap: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(
                _isEditing ? Icons.check : Icons.edit,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _currentUser?.photoURL != null
                        ? CachedNetworkImageProvider(_currentUser!.photoURL!)
                        : null,
                    child: _currentUser?.photoURL == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing)
                    Column(
                      children: [
                        Text(
                          _currentUser?.displayName ?? 'Artist',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _currentUser?.email ?? '',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _displayNameController,
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bio Section
            Text(
              'Bio',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell us about your art and yourself...',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _bioController.text.isEmpty
                      ? 'No bio yet. Edit your profile to add one!'
                      : _bioController.text,
                  style: TextStyle(
                    color: _bioController.text.isEmpty
                        ? Colors.grey[500]
                        : Colors.grey[300],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Stats Section
            Text(
              'Artist Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ArtPost>>(
              stream: _artPostService.getUserPosts(_currentUser!.uid),
              builder: (context, snapshot) {
                int totalLikes = 0;
                int totalViews = 0;
                int totalCritiques = 0;
                int artCount = 0;

                if (snapshot.hasData) {
                  artCount = snapshot.data!.length;
                  for (var post in snapshot.data!) {
                    totalLikes += post.likeCount;
                    totalViews += post.viewCount;
                    totalCritiques += post.critiqueCount;
                  }
                }

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  children: [
                    _StatCard(
                      title: 'Artworks',
                      value: artCount.toString(),
                      icon: Icons.image,
                    ),
                    _StatCard(
                      title: 'Total Likes',
                      value: totalLikes.toString(),
                      icon: Icons.favorite,
                    ),
                    _StatCard(
                      title: 'Total Views',
                      value: totalViews.toString(),
                      icon: Icons.visibility,
                    ),
                    _StatCard(
                      title: 'Critiques',
                      value: totalCritiques.toString(),
                      icon: Icons.comment,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // My Artworks Section
            Text(
              'My Artworks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ArtPost>>(
              stream: _artPostService.getUserPosts(_currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No artworks yet',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                final posts = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          if (post.imageUrl.isNotEmpty)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[700],
                              ),
                              child: Image.network(
                                post.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image,
                                    color: Colors.grey[600],
                                  );
                                },
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${post.askingPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.favorite,
                                        size: 14, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      post.likeCount.toString(),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.comment,
                                        size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      post.critiqueCount.toString(),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
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
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OnboardingEventsDebugScreen(
                        userId: _currentUser!.uid,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('View Onboarding Debug Events'),
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About ArtConnect',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ArtConnect is a community platform for artists to share their work, receive constructive feedback, price their art fairly, and visualize how their work would look in different environments.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
