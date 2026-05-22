# 🔐 Setting Up API Keys & Secrets

This guide explains how to set up your local environment with API keys and secrets.

## ⚠️ Important Security Rules

- **NEVER commit `.env` files to GitHub**
- **NEVER commit `google-services.json` with real credentials**
- **NEVER commit `firebase-key.json` or any `.key` files**
- Always use `.example` files as templates

## Setup Steps

### 1. Environment Variables (.env)

Create a `.env` file in the project root (this file is ignored by git):

```bash
cp .env.example .env
```

Then edit `.env` and add your actual API keys:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=aimr-twin-studio
FIREBASE_API_KEY=AIzaSyBBe5B5PXewFvpaxIg-XjnCJ95K12XR3kg
FIREBASE_APP_ID=1:298990602880:android:f53d8823bcd7cd05297465
FIREBASE_MESSAGING_SENDER_ID=298990602880
FIREBASE_STORAGE_BUCKET=aimr-twin-studio.firebasestorage.app

# Image Generation API
IMAGE_GEN_API_KEY=your_actual_key_here
IMAGE_GEN_API_URL=https://api.example.com/generate-image

# Kling API (B-Roll Videos)
KLING_API_KEY=your_actual_key_here
KLING_API_URL=https://api.klingai.com/v1

# ElevenLabs API (Voice Generation)
ELEVENLABS_API_KEY=your_actual_key_here
ELEVENLABS_API_URL=https://api.elevenlabs.io/v1

# Creatomate API (Carousel Generation)
CREATOMATE_API_KEY=your_actual_key_here
CREATOMATE_API_URL=https://api.creatomate.com/v1

# Sync.so API (Lip Sync)
SYNCSO_API_KEY=your_actual_key_here
SYNCSO_API_URL=https://api.sync.so/v1

# Payment Processing
STRIPE_PUBLIC_KEY=your_actual_key_here
STRIPE_SECRET_KEY=your_actual_key_here

# App Configuration
APP_NAME=AIMR Twin Studio
APP_VERSION=1.0.0
DEBUG_MODE=false
```

### 2. Firebase Configuration (google-services.json)

For Android:

```bash
cp google-services.json.example google-services.json
```

Then replace the placeholder values with your actual Firebase project credentials.

**Location:** `android/app/google-services.json`

For iOS, use Firebase Console to download the `GoogleService-Info.plist` file and place it in:
**Location:** `ios/Runner/GoogleService-Info.plist`

### 3. Loading Environment Variables in Flutter

To use `.env` variables in your Flutter app, use the `flutter_dotenv` package:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

// Access variables
String apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
```

## 📋 Checklist for New Team Members

- [ ] Clone the repository
- [ ] Copy `.env.example` to `.env` and fill in actual keys
- [ ] Copy `google-services.json.example` to `google-services.json` and fill in actual values
- [ ] Download `GoogleService-Info.plist` from Firebase Console for iOS
- [ ] Run `flutter pub get`
- [ ] Run `flutter run` to test

## 🔒 Where to Get API Keys

| Service | Where to Get | Documentation |
|---------|-------------|---------------|
| Firebase | [Firebase Console](https://console.firebase.google.com) | [Setup Guide](./FIREBASE_SETUP.md) |
| Kling AI | [Kling Dashboard](https://klingai.com) | Contact support |
| ElevenLabs | [ElevenLabs Dashboard](https://elevenlabs.io) | [Docs](https://elevenlabs.io/docs) |
| Creatomate | [Creatomate Dashboard](https://creatomate.com) | [Docs](https://creatomate.com/docs) |
| Sync.so | [Sync.so Dashboard](https://sync.so) | [Docs](https://sync.so/docs) |
| Stripe | [Stripe Dashboard](https://dashboard.stripe.com) | [Docs](https://stripe.com/docs) |

## 🚨 If You Accidentally Commit Secrets

If you accidentally commit a file with secrets:

1. **Immediately rotate all exposed keys** in their respective dashboards
2. Remove the file from git history:
   ```bash
   git rm --cached google-services.json
   git commit --amend --no-edit
   git push --force-with-lease
   ```
3. Add the file to `.gitignore`
4. Notify the team

## 📝 Notes

- Each developer should have their own `.env` file locally
- Production deployments should use secure secret management (e.g., GitHub Secrets, Firebase Remote Config)
- Never share `.env` files via email or chat
- Use a password manager to store sensitive credentials
