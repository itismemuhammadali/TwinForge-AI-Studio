# 🔑 Gemini API Key Setup via Firebase Remote Config

This guide explains how to securely manage the Gemini API key using Firebase Remote Config instead of hardcoding it in the app.

## Why Firebase Remote Config?

✅ **No hardcoding** - API key is not in source code  
✅ **Remote updates** - Change API key without redeploying app  
✅ **Offline support** - Cached values work offline  
✅ **Easy management** - Update from Firebase Console  
✅ **Secure** - Keys are stored in Firebase backend  

## Setup Steps

### 1. Add Firebase Remote Config Dependency

The dependency has already been added to `pubspec.yaml`:

```yaml
dependencies:
  firebase_remote_config: ^4.3.0
```

Run:
```bash
flutter pub get
```

### 2. Configure Gemini API Key in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **aimr-twin-studio**
3. Navigate to **Remote Config** (in left sidebar under "Build")
4. Click **Create Configuration**
5. Add a new parameter:
   - **Parameter key:** `gemini_api_key`
   - **Default value:** (leave empty for now)
   - **Description:** "Gemini API Key for image generation"

6. Click **Publish Changes**

### 3. Add Your Gemini API Key

1. In Firebase Console → Remote Config
2. Click on the `gemini_api_key` parameter
3. Click **Edit** and add your actual API key (get it from Google Cloud Console)
4. Click **Publish Changes**

### 4. How It Works in the App

The app now:
1. **Initializes** `GeminiService` during splash screen
2. **Fetches** the API key from Firebase Remote Config
3. **Caches** it locally for offline use
4. **Uses** it for all Gemini API calls

### 5. Code Changes Made

**gemini_service.dart:**
- Removed hardcoded API key
- Added `initialize()` method that fetches from Firebase Remote Config
- API key is now loaded dynamically at app startup

**splash_screen.dart:**
- Added `GeminiService.initialize()` call during Firebase initialization
- Happens in parallel with other Firebase services

## 🔄 Updating the API Key

To update the Gemini API key without redeploying:

1. Go to Firebase Console → Remote Config
2. Edit the `gemini_api_key` parameter
3. Enter the new key
4. Click **Publish Changes**
5. Users will get the new key on next app launch (or within 1 hour)

## 🚨 Troubleshooting

### "Gemini API key not configured in Firebase Remote Config"

**Solution:** Make sure you've added the `gemini_api_key` parameter in Firebase Console and published it.

### API calls still failing

1. Check that the API key is correct in Firebase Console
2. Verify the key has Gemini API enabled in Google Cloud Console
3. Check app logs for initialization errors

### Want to test locally?

You can temporarily set a default value in `gemini_service.dart`:

```dart
await _remoteConfig.setDefaults({
  'gemini_api_key': 'YOUR_TEST_KEY_HERE',
});
```

But remember to remove this before committing!

## 📋 Security Best Practices

✅ **DO:**
- Store API key in Firebase Remote Config
- Rotate keys periodically
- Monitor API usage in Google Cloud Console
- Use different keys for dev/staging/production

❌ **DON'T:**
- Hardcode API keys in source code
- Commit `.env` files with real keys
- Share API keys via email or chat
- Use the same key across environments

## 🔗 Related Documentation

- [Firebase Remote Config Docs](https://firebase.google.com/docs/remote-config)
- [Gemini API Docs](https://ai.google.dev/docs)
- [Google Cloud Console](https://console.cloud.google.com)

## 📝 For Team Members

When setting up the app:

1. Clone the repo
2. Run `flutter pub get`
3. Make sure Firebase is initialized (it happens automatically)
4. The Gemini API key will be fetched from Firebase Remote Config
5. No additional setup needed!

The API key is managed centrally in Firebase, so everyone uses the same key automatically.
