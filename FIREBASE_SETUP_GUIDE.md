# Firebase Setup Guide for AIMR Twin Studio Mobile App

## Overview
This guide explains how to set up Firebase Firestore and Storage rules for the mobile app.

---

## 1. Firestore Rules Setup

### Steps:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **aimr-twin-studio**
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the entire content from `FIREBASE_FIRESTORE_RULES.txt`
5. Paste it into the Firebase Rules editor
6. Click **"Publish"**

### What These Rules Enable:
- ✅ User signup and profile creation
- ✅ Profile updates (name, bio, gender, etc.)
- ✅ Subscription/plan management
- ✅ Generated images storage
- ✅ Generated videos storage
- ✅ User preferences and notifications
- ✅ Usage tracking for rate limiting
- ✅ Keeps existing website rules intact

### Firestore Collections Structure:
```
users/
├── {userId}/
│   ├── displayName
│   ├── email
│   ├── gender (Female/Male)
│   ├── subscription
│   ├── credits
│   ├── generatedImages/
│   │   └── {imageId}/
│   │       ├── imageUrl
│   │       ├── prompt
│   │       ├── createdAt
│   │       └── gender
│   ├── generatedVideos/
│   │   └── {videoId}/
│   │       ├── videoUrl
│   │       ├── type (talking-head, b-roll, carousel)
│   │       └── status
│   ├── preferences/
│   │   └── {prefId}/
│   │       ├── notifications
│   │       └── theme
│   └── notifications/
│       └── {notificationId}/
│           ├── title
│           ├── message
│           └── read

plans/
├── {planId}/
│   ├── name
│   ├── price
│   └── features

usage/
├── {userId}/
│   ├── imagesUsedToday
│   ├── usageDate
│   └── lastReset
```

---

## 2. Storage Rules Setup

### Steps:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **aimr-twin-studio**
3. Navigate to **Storage** → **Rules** tab
4. Copy the entire content from `FIREBASE_STORAGE_RULES.txt`
5. Paste it into the Firebase Rules editor
6. Click **"Publish"**

### What These Rules Enable:
- ✅ Profile image uploads (5MB max)
- ✅ Generated image storage (10MB max)
- ✅ Generated video storage (100MB max)
- ✅ Reference image (selfie) storage (5MB max)
- ✅ Public assets access
- ✅ User-only access to their own files

### Storage Folder Structure:
```
gs://aimr-twin-studio.firebasestorage.app/
├── users/
│   ├── {userId}/
│   │   ├── profile/
│   │   │   └── profile.jpg
│   │   ├── generatedImages/
│   │   │   ├── image_1.jpg
│   │   │   ├── image_2.jpg
│   │   │   └── ...
│   │   ├── generatedVideos/
│   │   │   ├── video_1.mp4
│   │   │   └── ...
│   │   └── referenceImages/
│   │       ├── selfie_1.jpg
│   │       └── ...
└── public/
    ├── logo.png
    └── assets/
```

---

## 3. Security Features

### Firestore Security:
- ✅ Users can only read/write their own data
- ✅ Usage limits enforced (max 16 images per day)
- ✅ Plans collection is read-only for users
- ✅ Password changes tracked
- ✅ Subscription expiry dates managed

### Storage Security:
- ✅ File size limits enforced
- ✅ File type validation (images/videos only)
- ✅ Users can only access their own files
- ✅ Public assets readable by anyone
- ✅ Automatic cleanup possible via Cloud Functions

---

## 4. Testing the Rules

### Test Firestore Rules:
1. Go to **Firestore Database** → **Rules** tab
2. Click **"Rules Playground"** (bottom right)
3. Test scenarios:
   - ✅ User can create profile
   - ✅ User can update gender
   - ✅ User can save generated images
   - ✅ User cannot access other user's data

### Test Storage Rules:
1. Go to **Storage** → **Rules** tab
2. Click **"Rules Playground"** (bottom right)
3. Test scenarios:
   - ✅ User can upload profile image
   - ✅ User can upload generated images
   - ✅ User cannot access other user's files
   - ✅ File size limits enforced

---

## 5. Troubleshooting

### Issue: "Permission denied" on signup
- **Solution**: Ensure Firestore rules allow `create` for authenticated users

### Issue: Cannot upload images
- **Solution**: Check Storage rules allow `write` for authenticated users in their folder

### Issue: Users can see other user's data
- **Solution**: Verify `request.auth.uid == userId` check in rules

### Issue: File upload fails
- **Solution**: Check file size and type match the rules (images < 5MB, videos < 100MB)

---

## 6. Next Steps

1. ✅ Copy Firestore rules to Firebase Console
2. ✅ Copy Storage rules to Firebase Console
3. ✅ Test rules in Rules Playground
4. ✅ Build and test the mobile app
5. ✅ Monitor usage in Firebase Console

---

## 7. Important Notes

- **Do NOT remove existing website rules** - They are still needed for the web app
- **Test thoroughly** before deploying to production
- **Monitor usage** in Firebase Console for any issues
- **Update rules** if you add new features
- **Keep backups** of these rule files

---

## 8. Support

For issues or questions:
1. Check Firebase documentation: https://firebase.google.com/docs/firestore/security/start
2. Review the rules in this file
3. Test in Rules Playground
4. Check Firebase Console logs for errors

---

**Last Updated**: May 5, 2026
**Project**: AIMR Twin Studio Mobile App
**Firebase Project ID**: aimr-twin-studio
