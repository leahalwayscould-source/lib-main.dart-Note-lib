# ArtConnect - Feature Reference & API Guide

## 📋 Features Overview

### 1️⃣ Gallery & Critique Community

**Screens:**
- `GalleryTab` - Main art feed
- `UploadArtScreen` - Create new post
- `ArtDetailScreen` - View details & critiques

**Key Functions:**
```dart
// Get all posts
Stream<List<ArtPost>> getAllPosts()

// Get user's posts
Stream<List<ArtPost>> getUserPosts(String artistUid)

// Like a post
Future<void> likePost(String postId, String userId)

// Create critique
Future<String> createCritique(Critique critique)

// Get post critiques
Stream<List<Critique>> getPostCritiques(String postId)
```

**Data Models:**
- `ArtPost` - Contains title, description, image, price, stats
- `Critique` - Contains comment, rating (1-5), likes

---

### 2️⃣ Pricing Calculator

**Screen:** `PricingTab`

**Pricing Factors:**
- Years of experience (0-50 years)
- Base hourly rate ($10-$500)
- Medium multiplier (0.8x - 2.0x)
- Artwork size (small, medium, large)
- Skill level (1-5 stars)
- Established artist bonus (+30%)

**Calculation Formula:**
```
Base Cost = Production Hours × Hourly Rate

Final Price = Base Cost 
            × Medium Multiplier 
            × Size Multiplier 
            × (1 + Experience × 0.1) 
            × (Skill Rating / 3.0)
            × Established Bonus
```

**Included Elements:**
- Real-time price calculation
- Price breakdown
- Professional tips
- Export/save functionality (pending)

---

### 3️⃣ Art Mockup Viewer

**Screen:** `MockupTab`

**Environments:**
- Modern Living Room
- Minimalist Office
- Gallery White Wall
- Brick Loft
- Bedroom Accent Wall
- Cafe Corner

**Customization Options:**
- Wall colors (7 presets)
- Artwork sizes (4 options)
- Frame tilt angle (-0.1 to 0.1 radians)

**Code Example:**
```dart
// Change environment
setState(() {
  _selectedEnvironment = 'Modern Living Room';
});

// Change wall color
setState(() {
  _selectedWallColor = Colors.grey[400]!;
});

// Tilt frame
_rotationAngle = 0.05; // ~3 degrees
```

**Features:**
- Real-time preview
- Save mockup (UI ready)
- Reset to defaults
- Multiple size comparisons

---

### 4️⃣ User Profiles

**Screen:** `ProfileTab`

**Profile Information:**
- Display name
- Bio
- Profile picture
- Artist specialties
- Email

**Statistics:**
- Total artworks
- Total likes received
- Total views
- Total critiques received

**Functions:**
```dart
// Update profile
Future<void> updateUserProfile(String uid, Map<String, dynamic> data)

// Get user profile
Future<ArtistUser?> getUserProfile(String uid)

// View user's artworks
Stream<List<ArtPost>> getUserPosts(String artistUid)
```

---

### 5️⃣ Authentication

**Screen:** `AuthScreen`

**Features:**
- Sign up with email
- Sign in with email
- Secure password handling
- User profile creation

**Functions:**
```dart
// Sign up
Future<User?> signUp(String email, String password, String displayName)

// Sign in
Future<User?> signIn(String email, String password)

// Sign out
Future<void> signOut()
```

---

## 🔧 Service API Reference

### AuthService

```dart
class AuthService {
  // Authentication
  Future<User?> signUp(String email, String password, String displayName)
  Future<User?> signIn(String email, String password)
  Future<void> signOut()
  
  // Profile Management
  Future<ArtistUser?> getUserProfile(String uid)
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data)
  
  // Auth State
  Stream<User?> get authStateChanges
  User? get currentUser
}
```

### ArtPostService

```dart
class ArtPostService {
  // CRUD Operations
  Future<String> createPost(ArtPost post)
  Future<void> updatePost(String postId, Map<String, dynamic> data)
  Future<void> deletePost(String postId)
  Future<ArtPost?> getPost(String postId)
  
  // Read Operations
  Stream<List<ArtPost>> getAllPosts()
  Stream<List<ArtPost>> getUserPosts(String artistUid)
  Stream<List<ArtPost>> getPostsByTag(String tag)
  
  // Engagement
  Future<void> likePost(String postId, String userId)
  Future<void> unlikePost(String postId, String userId)
  Future<void> incrementViewCount(String postId)
}
```

### CritiqueService

```dart
class CritiqueService {
  // CRUD Operations
  Future<String> createCritique(Critique critique)
  Future<void> deleteCritique(String critiqueId, String postId)
  
  // Read Operations
  Stream<List<Critique>> getPostCritiques(String postId)
  Stream<List<Critique>> getUserCritiques(String critiquerUid)
  
  // Engagement
  Future<void> likeCritique(String critiqueId, String userId)
  Future<void> unlikeCritique(String critiqueId, String userId)
}
```

---

## 📊 Data Models

### ArtistUser

```dart
class ArtistUser {
  String uid;
  String email;
  String displayName;
  String profileImageUrl;
  String bio;
  List<String> specialties;
  double averageRating;
  int totalCritiques;
  DateTime createdAt;
}
```

### ArtPost

```dart
class ArtPost {
  String postId;
  String artistUid;
  String artistName;
  String artistProfileImage;
  String title;
  String description;
  String imageUrl;
  List<String> tags;
  String medium;
  String style;
  double askingPrice;
  int viewCount;
  int likeCount;
  int critiqueCount;
  List<String> likedBy;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> imageUrls;
}
```

### Critique

```dart
class Critique {
  String critiqueId;
  String postId;
  String critiquerUid;
  String critiquerName;
  String critiquerProfileImage;
  String comment;
  double rating;  // 1-5 stars
  int likes;
  List<String> likedBy;
  DateTime createdAt;
  DateTime updatedAt;
}
```

---

## 🎨 UI Components

### Custom Widgets

**_InteractionButton** (gallery_tab.dart)
```dart
// Used for likes, comments, views
Row(
  children: [
    Icon(icon, color: color, size: 20),
    SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 12)),
  ],
)
```

**_StatCard** (profile_tab.dart)
```dart
// Displays artist statistics
Container(
  child: Column(
    children: [Icon, Value, Label],
  ),
)
```

**_CritiqueCard** (art_detail_screen.dart)
```dart
// Displays individual critique
Container(
  child: Column(
    children: [
      Row(critic info),
      SizedBox
      Text(comment),
      Row(likes),
    ],
  ),
)
```

---

## 🔄 User Flow Diagram

```
┌─────────────────┐
│  Launch App     │
└────────┬────────┘
         │
    ┌────▼─────┐
    │ Auth Check│
    └─┬──────┬─┘
      │      │
      │      └─── Not Logged In → AuthScreen
      │           (Sign Up / Sign In)
      │           │
      │           └─── Create Account
      │
      ├─── Logged In → HomeScreen (Navigation)
      │
      ├─── Gallery Tab ─────┬─── View Feed
      │                     ├─── View Details
      │                     ├─── Like/Comment
      │                     └─── Upload Art
      │
      ├─── Pricing Tab ──── Calculate Fair Price
      │
      ├─── Mockup Tab ────── Preview in Environments
      │
      └─── Profile Tab ────┬─── View Stats
                          ├─── Edit Bio
                          ├─── View Artworks
                          └─── Sign Out
```

---

## 🚀 Quick Integration Examples

### Upload Artwork

```dart
final newPost = ArtPost(
  postId: '',
  artistUid: currentUser.uid,
  artistName: userProfile.displayName,
  title: _titleController.text,
  description: _descriptionController.text,
  imageUrl: imageUrl,
  tags: tags,
  medium: _mediumController.text,
  style: _styleController.text,
  askingPrice: double.parse(_priceController.text),
  viewCount: 0,
  likeCount: 0,
  critiqueCount: 0,
  likedBy: [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  imageUrls: [imageUrl],
);

await _artPostService.createPost(newPost);
```

### Leave a Critique

```dart
final critique = Critique(
  critiqueId: '',
  postId: post.postId,
  critiquerUid: currentUser.uid,
  critiquerName: currentUser.displayName,
  critiquerProfileImage: currentUser.photoURL ?? '',
  comment: _critiqueController.text,
  rating: _selectedRating,
  likes: 0,
  likedBy: [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await _critiqueService.createCritique(critique);
```

### Listen to Gallery Stream

```dart
StreamBuilder<List<ArtPost>>(
  stream: _artPostService.getAllPosts(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final posts = snapshot.data!;
      return ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(posts[index]);
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

---

## 🐛 Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Posts not loading | Firestore delayed | Check internet, verify rules |
| Can't upload art | Firebase storage missing | Initialize storage in setup |
| Critiques not saving | User not authenticated | Check Firebase auth status |
| Images showing as broken | Placeholder in use | Replace with Firebase Storage |
| Mockup colors not changing | State not updating | Call setState() in callback |

---

## 📈 Performance Tips

1. **Use StreamBuilder** for real-time updates
2. **Cache images** with cached_network_image
3. **Paginate posts** for large datasets (future)
4. **Lazy load** critiques as needed
5. **Optimize Firestore queries** with proper indexes

---

## 🔐 Security Best Practices

1. Never expose Firebase credentials
2. Always validate user input
3. Use strong passwords
4. Implement rate limiting
5. Regular backups of data
6. Monitor suspicious activities

---

For more details, see [lib_README.md](lib_README.md) or [SETUP_GUIDE.md](SETUP_GUIDE.md)
