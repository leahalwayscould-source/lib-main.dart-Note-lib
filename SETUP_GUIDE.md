# ArtConnect Setup Guide

## 🎯 Quick Start

Follow these steps to get ArtConnect up and running on your machine.

## Step 1: Repository Setup

```bash
# Clone or navigate to your project
cd /workspaces/lib-main.dart-Note-lib

# Get dependencies
flutter pub get
```

## Step 2: Firebase Configuration

### 2.1 Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a new project"
3. Enter project name: `artist-community-app`
4. Enable Google Analytics (optional)
5. Click "Create Project"

### 2.2 Register Your App

**For Android:**
1. In Firebase Console, click "Add app" → Select Android
2. Enter package name: `com.artistcommunity.app`
3. Download `google-services.json`
4. Place it in `android/app/`

**For iOS:**
1. In Firebase Console, click "Add app" → Select iOS
2. Enter bundle ID: `com.artistcommunity.app`
3. Download `GoogleService-Info.plist`
4. Open iOS project in Xcode and add the file

**For Web:**
1. In Firebase Console, click "Add app" → Select Web
2. Get your Firebase config

### 2.3 Update Firebase Options

Update `lib/firebase_options.dart` with your credentials from Firebase Console:

```dart
// Replace with your actual Firebase config
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

## Step 3: Enable Firebase Services

### 3.1 Authentication

1. In Firebase Console → Authentication
2. Click "Get Started"
3. Select "Email/Password"
4. Enable it and click "Save"

### 3.2 Firestore Database

1. In Firebase Console → Firestore Database
2. Click "Create Database"
3. Start in "Test Mode" (for development)
4. Choose your region (closest to you)
5. Click "Enable"

### 3.3 Cloud Storage (Optional, for future image uploads)

1. In Firebase Console → Storage
2. Click "Get Started"
3. Choose region and click "Done"

## Step 4: Firestore Security Rules (Development)

In Firebase Console → Firestore → Rules, use these for development:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads and writes (development only)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **Important**: Update these rules before production!

## Step 5: Run the App

```bash
# For development
flutter run

# For a specific device
flutter run -d <device_id>

# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For Web
flutter run -d web
```

## 📦 Project Structure Verification

Ensure you have these files:

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── artist_user.dart
│   ├── art_post.dart
│   └── critique.dart
├── services/
│   ├── auth_service.dart
│   ├── art_post_service.dart
│   └── critique_service.dart
└── screens/
    ├── auth/
    │   └── auth_screen.dart
    └── home/
        ├── home_screen.dart
        ├── gallery_tab.dart
        ├── upload_art_screen.dart
        ├── art_detail_screen.dart
        ├── pricing_tab.dart
        ├── mockup_tab.dart
        └── profile_tab.dart
```

## 🚀 Next Steps After Setup

### 1. Test Authentication
- Sign up with an email
- Verify user appears in Firebase → Authentication
- Verify user profile created in Firestore

### 2. Test Gallery Feature
- Upload test artwork
- Check if it appears in Firestore
- Try liking and leaving critiques

### 3. Test Other Features
- Use pricing calculator (no backend needed)
- Try mockup viewer
- Update profile

## 🔍 Troubleshooting

### "Plugin firebase_core not found"
```bash
flutter clean
flutter pub get
flutter run
```

### "App crashed on splash screen"
- Check Firebase credentials in `firebase_options.dart`
- Verify Firebase project ID matches
- Check internet connection

### "Firestore operations failing"
- Verify Firestore database is created
- Check security rules allow your user
- Ensure Firebase is properly initialized

### "Image uploads not working"
- Cloud Storage not set up yet
- Currently using placeholder images
- Feature pending full implementation

## 📱 App Walkthrough

### First Time Users

1. **Sign Up**
   - Email: your-email@example.com
   - Display Name: Your Artist Name
   - Password: secure password

2. **Explore Gallery**
   - View sample posts (once created)
   - Like artworks
   - Leave critiques

3. **Upload Your Art**
   - Gallery tab → Upload Art button
   - Fill in details (using placeholder image for now)
   - Add tags and price

4. **Use Pricing Calculator**
   - Pricing tab
   - Adjust factors
   - Get fair price

5. **Preview with Mockup**
   - Mockup tab
   - Choose environment and colors
   - Visualize your art

6. **Manage Profile**
   - Profile tab
   - Edit bio and details
   - View statistics

## 🎨 Feature Development Status

| Feature | Status | Notes |
|---------|--------|-------|
| Authentication | ✅ Complete | Email/password login |
| Art Gallery | ✅ Complete | View, like, comment |
| Upload Art | ⚠️ Partial | Using placeholder images |
| Critiques | ✅ Complete | With ratings and feedback |
| Pricing Calculator | ✅ Complete | Fully functional |
| Mockup Viewer | ✅ Complete | Multiple environments |
| User Profiles | ✅ Complete | With statistics |
| Cloud Storage | ⏳ Pending | Needed for real images |

## 🔐 Important Security Notes

### Development vs Production

**Development:**
- Firestore rules allow authenticated reads/writes
- Firebase emulator can be used for testing
- No sensitive data restrictions

**Production Checklist:**
- [ ] Implement proper Firestore security rules
- [ ] Enable reCAPTCHA for authentication
- [ ] Set up Cloud Functions
- [ ] Enable HTTPS
- [ ] Add terms of service
- [ ] Implement content moderation
- [ ] Add user reporting features
- [ ] Enable data backups

## 📚 Useful Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Flutter Docs](https://firebase.flutter.dev)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Material Design 3](https://m3.material.io)

## 💡 Tips for Development

1. **Use Firebase Emulator Suite** for offline development
2. **Enable Firestore offline** for testing
3. **Use DevTools** for debugging (flutter devtools)
4. **Test on multiple devices** for responsive design

## 📝 Database Initialization

### Creating Test Data Manually

In Firebase Console → Firestore:

1. Create collection: `artPosts`
2. Add sample document with test artwork
3. Create collection: `critiques`
4. Add sample critique

This helps test the gallery before uploading real artwork.

## 🎯 Next Phase Development

After basic setup, consider:

1. **Real Image Upload**
   - Integrate image_picker properly
   - Upload to Firebase Storage
   - Implement image compression

2. **User Following**
   - Add follow/unfollow functionality
   - Create user discovery

3. **Search & Filter**
   - Implement search by title/artist
   - Filter by medium, style, price range

4. **Payment Integration**
   - Stripe or PayPal integration
   - Order management

---

**Ready to start?** Run `flutter run` and create your first post! 🎨
