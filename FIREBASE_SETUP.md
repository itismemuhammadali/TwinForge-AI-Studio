# Firebase Setup Guide for AIMR Twin Studio™

## Quick Start (5 minutes)

### 1. Create Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Click "Add project"
- Name it "AIMR Twin Studio"
- Enable Google Analytics (optional)

### 2. Add Apps to Firebase Project

#### Android App
1. Click "Add app" → Select Android
2. Package name: `com.example.ai_video_image_generation_app`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### iOS App
1. Click "Add app" → Select iOS
2. Bundle ID: `com.example.aiVideoImageGenerationApp`
3. Download `GoogleService-Info.plist`
4. Open iOS project in Xcode and add the file

### 3. Update Firebase Options
Edit `lib/services/firebase_options.dart` and replace placeholders with your Firebase credentials:

```dart
// Get these from Firebase Console → Project Settings
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

### 4. Enable Firebase Services

#### Authentication
1. Go to Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password"
4. Enable "Email link sign-in" (optional)

#### Firestore Database
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **Test mode** (for development)
4. Choose region closest to your users

#### Storage (for image uploads)
1. Go to Firebase Console → Storage
2. Click "Get started"
3. Start in **Test mode**

### 5. Set Firestore Security Rules

Replace default rules with:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      
      // User's content collection
      match /content/{document=**} {
        allow read, write: if request.auth.uid == uid;
      }
    }
  }
}
```

### 6. Install Dependencies
```bash
flutter pub get
```

### 7. Run the App
```bash
flutter run
```

---

## Firestore Database Structure

```
users/
  {uid}/
    - email: string
    - displayName: string
    - createdAt: timestamp
    - credits: number
    - subscription: string (free/pro/premium)
    - profileImage: string (URL)
    
    content/
      {contentId}/
        - title: string
        - type: string (image/video/carousel/broll)
        - imageUrl: string
        - videoUrl: string
        - prompt: string
        - model: string
        - createdAt: timestamp
        - updatedAt: timestamp
```

---

## API Integration Points

### Image Generation
- Connect to your image generation API in `lib/services/`
- Save results using `ContentProvider.saveContent()`

### Video Generation (B-Roll)
- Integrate Kling API
- Store video URLs in Firestore

### Talking Head Videos
- Integrate ElevenLabs for voice
- Use Sync.so for lip sync
- Store final video in Firebase Storage

---

## Environment Variables (Optional)

Create `.env` file in project root:
```
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_api_key
```

Then load in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  // ... rest of initialization
}
```

---

## Testing

### Test Authentication
1. Run app
2. Go to Register screen
3. Create account with test email
4. Check Firebase Console → Authentication to see new user

### Test Firestore
1. After login, save content
2. Check Firebase Console → Firestore → users collection
3. Verify data structure

---

## Troubleshooting

### "Firebase not initialized"
- Make sure `FirebaseService.initialize()` is called in `main()`
- Check that Firebase options are correctly set

### "Permission denied" errors
- Check Firestore security rules
- Ensure user is authenticated
- Verify UID matches in rules

### iOS build fails
- Run `flutter clean`
- Run `pod install` in `ios/` folder
- Rebuild with `flutter run`

---

## Next Steps

1. ✅ Firebase Auth connected
2. ✅ Firestore database ready
3. ⏳ Connect image generation API
4. ⏳ Implement carousel generator
5. ⏳ Integrate Kling API for B-Roll
6. ⏳ Add ElevenLabs for talking heads
