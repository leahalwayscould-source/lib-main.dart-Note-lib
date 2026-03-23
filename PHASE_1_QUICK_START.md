# Quick Start: Deploy & Test Phase 1

## 🚀 Step 1: Deploy Storage Rules (2 minutes)

```bash
cd /workspaces/lib-main.dart-Note-lib
firebase deploy --only storage
```

**Expected output:**
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/YOUR_PROJECT/overview
```

---

## ✅ Step 2: Get Your Dependencies Ready

```bash
flutter pub get
```

This ensures `image_picker` and `firebase_storage` are installed.

---

## 🧪 Step 3: Test Real Image Upload (LOCAL)

### A. Start Your App
```bash
flutter run -d chrome  # for web testing
# OR
flutter run           # for iOS/Android
```

### B. Test Flow
1. **Sign up** with new account (free tier)
2. Go to **Gallery** tab
3. Click **"Upload"** button  
4. Fill in artwork details:
   - Title: "My First Upload"
   - Description: "Testing real image upload"
   - Medium: "Digital"
   - Style: "Contemporary"
5. Click **"Pick Image from Gallery"**
6. Select an image from your device
7. You'll see image preview
8. Click **"Upload Art"** button
9. Watch **progress bar** go 0-100%
10. Image appears in gallery ✅

### C. Verify Success
- ✅ Image shows in gallery (not placeholder)
- ✅ Upload progress bar worked
- ✅ No error messages
- ✅ Check Firebase Storage: `art_uploads/{userId}/` folder has image

---

## 📊 Expected Test Results

### After Deploying Storage Rules

| Test | Expected | Success? |
|------|----------|----------|
| Deploy command succeeds | `✔ Deploy complete!` | ✅ |
| Run app | App starts without errors | ✅ |
| Pick image | Image preview shows | ✅ |
| Upload starts | Progress 0% → 100% | ✅ |
| Upload completes | Image in gallery | ✅ |
| Check Firebase Storage | Image file exists | ✅ |

---

## 🔍 Verify in Firebase Console

### Check Storage
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Select your project
3. Go to **Storage** tab
4. You should see folder: `art_uploads/{userId}/image_file.jpg`

### Check Firestore
1. Go to **Firestore Database** tab
2. Go to `artPosts` collection
3. New document should have:
   - `imageUrl`: (Firebase Storage URL, not placeholder)
   - `artistUid`: Your user ID
   - `title`: "My First Upload"
   - `createdAt`: Current timestamp

---

## ⚠️ Troubleshooting

### Issue: Deploy fails - "Property X is invalid"
**Solution:** Make sure `storage.rules` file exists and is valid
```bash
cat storage.rules  # Verify file contents
```

### Issue: "Failed to pick image"
**Solution:** Grant app permission
- iOS: Settings → App → Photos → Allow
- Android: Settings → Apps → Your App → Permissions → Photos

### Issue: Upload stuck at 0%
**Solution:** Check Firestore rules
```bash
firebase deploy --only firestore:rules
```

### Issue: Image not appearing in gallery
**Solution:**
1. Refresh app (hot reload)
2. Go to Gallery tab again
3. Check Firebase Storage for file
4. Check Firestore `artPosts` collection for record

---

## ✅ Phase 1 Part A: COMPLETE ✅

Once all tests pass:
- ✅ **Real images** stored in Firebase Storage
- ✅ **Upload progress** visible to users
- ✅ **Storage secured** with rules
- ✅ **Ready for Phase 1 Part B: Stripe**

---

## 🎯 Next: Phase 1 Part B - Real Stripe Integration

Once image upload works, follow [PHASE_1_SETUP.md](PHASE_1_SETUP.md) to:
1. Add `flutter_stripe` package
2. Get Stripe test keys
3. Create Cloud Function
4. Test real payment processing

---

## 💡 Pro Tips

### Test Multiple Uploads
- Upload 5 images (free limit)
- 6th should show dialog "Upload limit reached"
- Upgrade to Basic tier
- Upload 20+ more images ✅

### Test Image Quality
- Try different sizes/formats
- Max 50 MB per image (enforced)
- JPG, PNG, GIF, WebP all supported

### Monitor Firebase Console
- Watch storage grow in real-time
- See upload progress in Cloud Functions logs
- Check Security Rules for access violations

---

## 📞 Support

If you hit issues:
1. Check error messages carefully
2. Verify Firebase rules are deployed
3. Check Firebase console logs
4. Ensure app has permissions
5. Try hot restart: `flutter clean && flutter pub get`

**Ready to deploy?** Run:
```bash
firebase deploy --only storage
```

Good luck! 🚀
