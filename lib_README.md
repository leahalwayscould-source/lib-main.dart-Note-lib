# ArtConnect - Artist Community App

A Flutter-based mobile application that enables artists to share their work, receive constructive critiques, price their art fairly, and visualize how their artwork would look in different environments.

## 🎨 Features

### 1. **Art Gallery & Critique Community** (Primary Feature)
- Upload and share your artwork with the artist community
- View a feed of artworks from other artists
- Like and comment on artworks
- Provide structured critiques with ratings (1-5 stars)
- Community engagement through feedback

### 2. **Art Pricing Calculator**
- Calculate fair market prices for your artwork based on:
  - Years of experience
  - Medium (Oil, Digital, Watercolor, etc.)
  - Size of artwork
  - Production hours
  - Your skill level
  - Market demand bonus for established artists
- Includes professional pricing breakdowns
- Pro tips for pricing strategies

### 3. **Art Mockup Viewer**
- Visualize how your art looks in different environments:
  - Modern Living Room
  - Minimalist Office
  - Gallery White Wall
  - Brick Loft
  - Bedroom Accent Wall
  - Cafe Corner
- Customize wall colors
- Adjust artwork size
- Tilt frames for realistic presentation
- Save mockups for presentations

### 4. **Artist Profiles**
- Complete artist profiles with bio
- View your artwork portfolio
- Track statistics (likes, views, critiques)
- Manage profile information

### 5. **Authentication**
- Secure Google Firebase authentication
- Email/password sign up and sign in
- User profile management

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point & auth wrapper
├── firebase_options.dart              # Firebase configuration
│
├── models/
│   ├── artist_user.dart              # User profile model
│   ├── art_post.dart                 # Art post model
│   └── critique.dart                 # Critique/comment model
│
├── services/
│   ├── auth_service.dart             # Firebase authentication
│   ├── art_post_service.dart         # Art post database operations
│   └── critique_service.dart         # Critique database operations
│
└── screens/
    ├── auth/
    │   └── auth_screen.dart          # Login/Sign Up screen
    └── home/
        ├── home_screen.dart          # Main navigation hub
        ├── gallery_tab.dart          # Art gallery feed
        ├── upload_art_screen.dart    # Upload artwork
        ├── art_detail_screen.dart    # Detailed art view & critiques
        ├── pricing_tab.dart          # Pricing calculator
        ├── mockup_tab.dart           # Environment mockup viewer
        └── profile_tab.dart          # Artist profile

pubspec.yaml                           # Dependencies & project config
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- Firebase project (for backend)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd lib-main.dart-Note-lib
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [firebase.google.com](https://firebase.google.com)
   - Get your Firebase credentials
   - Update `lib/firebase_options.dart` with your credentials
   - For iOS: Run `flutterfire configure`

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Setup

1. **Enable Authentication**
   - Go to Firebase Console → Authentication
   - Enable Email/Password authentication

2. **Create Firestore Database**
   - Create a new Firestore database
   - Set up the following collections:
     - `users` - Artist profiles
     - `artPosts` - Uploaded artworks
     - `critiques` - Comments and feedback

3. **Enable Cloud Storage**
   - For future image uploads functionality

### Firestore Collections Schema

**users**
```
{
  email: string,
  displayName: string,
  profileImageUrl: string,
  bio: string,
  specialties: string[],
  averageRating: number,
  totalCritiques: number,
  createdAt: timestamp
}
```

**artPosts**
```
{
  artistUid: string,
  artistName: string,
  artistProfileImage: string,
  title: string,
  description: string,
  imageUrl: string,
  tags: string[],
  medium: string,
  style: string,
  askingPrice: number,
  viewCount: number,
  likeCount: number,
  critiqueCount: number,
  likedBy: string[],
  createdAt: timestamp,
  updatedAt: timestamp,
  imageUrls: string[]
}
```

**critiques**
```
{
  postId: string,
  critiquerUid: string,
  critiquerName: string,
  critiquerProfileImage: string,
  comment: string,
  rating: number (1-5),
  likes: number,
  likedBy: string[],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

## 🎯 Key Dependencies

- **firebase_core** - Firebase initialization
- **firebase_auth** - Authentication
- **cloud_firestore** - Database
- **firebase_storage** - Cloud storage
- **provider** - State management
- **image_picker** - Image selection
- **google_nav_bar** - Custom navigation bar
- **cached_network_image** - Image caching
- **intl** - Internationalization

## 🛣️ Future Enhancements

1. **Real Image Upload**
   - Integrate Firebase Storage for actual image uploads
   - Image compression and optimization

2. **Social Features**
   - Follow/unfollow artists
   - Direct messaging
   - Artist discovery by specialties

3. **E-commerce Integration**
   - Buy/sell artwork
   - Payment processing
   - Order management

4. **Advanced Analytics**
   - Detailed performance metrics
   - Price trend analysis
   - Market insights

5. **AR Features**
   - Augmented reality art placement
   - Real-time visualization

6. **Search & Discovery**
   - Advanced filter options
   - Search by tags, medium, style
   - Trending artworks

## 📱 Navigation Structure

```
AuthScreen (Login/Sign Up)
    ↓
HomeScreen (Main Hub)
    ├── Gallery Tab
    │   ├── Art Feed
    │   ├── Upload Art Screen
    │   └── Art Detail Screen (with Critiques)
    ├── Pricing Tab
    │   └── Pricing Calculator
    ├── Mockup Tab
    │   └── Environment Mockup Viewer
    └── Profile Tab
        └── Artist Profile & Statistics
```

## 🎨 Design

- **Theme**: Dark mode optimized for creative work
- **Color Scheme**: Deep Purple primary with grey accents
- **Typography**: Material 3 design system
- **Navigation**: Google Nav Bar with 4 main sections

## 📝 Usage Guide

### For Artists

1. **Create Account**
   - Sign up with email and display name

2. **Upload Artwork**
   - Go to Gallery → Upload Art
   - Fill in title, description, medium, style
   - Add tags and pricing
   - Submit

3. **Receive Feedback**
   - View critiques on your artwork
   - Build reputation through engagement

4. **Price Your Work**
   - Use Pricing Calculator
   - Adjust factors based on market
   - Get fair valuation

5. **Preview Mockups**
   - Visualize art in different settings
   - Adjust wall colors and size
   - Help buyers envision the piece

## 🔐 Security

- Firebase Authentication for secure login
- Firestore security rules (to be configured)
- Data encryption in transit
- User privacy protection

## 📄 License

[Add your license here]

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests.

## 📞 Support

For issues or questions, please open an issue on the repository.

---

**ArtConnect** - Empowering Artists Worldwide 🎨
