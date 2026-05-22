# 🎬 Core Feature Flow - What We Built

## The User Journey

```
1. Upload Selfie
   ↓
2. Generate Image (AI)
   ↓
3. Edit Image (Add/Modify with Prompts)
   ↓
4. Choose Conversion Type
   ├─ Talking Head (Add voice & lip sync)
   ├─ B-Roll (Cinematic motion)
   └─ Carousel (Social media post)
```

---

## Files Created

### 1. **GeneratedContent Model** (`lib/models/generated_content.dart`)
- Stores image data with metadata
- Tracks original and edited versions
- Stores prompts and edit history

### 2. **Image Edit Screen** (`lib/screens/image_edit_screen.dart`)
- Display generated image
- Input field for edit prompts (e.g., "Add sunglasses", "Change background")
- Apply edit button
- Continue to conversion button

### 3. **Conversion Screen** (`lib/screens/conversion_screen.dart`)
- Shows the edited image
- Three options:
  - **Talking Head** - Add voice & lip sync
  - **B-Roll** - Cinematic motion effects
  - **Carousel** - Social media carousel

### 4. **Updated Screens**
- `generate_screen.dart` - Now flows to ImageEditScreen after generation
- `talking_head_screen.dart` - Accepts content from conversion flow
- `broll_screen.dart` - Accepts content from conversion flow
- `carousel_screen.dart` - Accepts content from conversion flow

---

## The Flow in Code

### Step 1: User generates image
```dart
// GenerateScreen → Generate button clicked
GeneratedContent generatedContent = GeneratedContent(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  originalImageUrl: 'https://...',
  prompt: 'Business, Office, Professional Outfit',
  createdAt: DateTime.now(),
  contentType: 'original',
  metadata: {...},
);

// Navigate to edit screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ImageEditScreen(content: generatedContent),
  ),
);
```

### Step 2: User edits image
```dart
// ImageEditScreen → User enters edit prompt
// "Add sunglasses", "Change background to beach", etc.

// Apply edit button calls API
await apiService.editImage(
  imageUrl: content.originalImageUrl,
  editPrompt: _editPromptCtrl.text,
);

// Save edited content
await contentProvider.saveContent(uid, editedContent.toMap());

// Navigate to conversion screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ConversionScreen(content: editedContent),
  ),
);
```

### Step 3: User chooses conversion type
```dart
// ConversionScreen → User taps one of three options

// Option 1: Talking Head
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TalkingHeadScreen(content: content),
  ),
);

// Option 2: B-Roll
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BrollScreen(content: content),
  ),
);

// Option 3: Carousel
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CarouselScreen(content: content),
  ),
);
```

### Step 4: User creates final video/carousel
```dart
// TalkingHeadScreen/BrollScreen/CarouselScreen
// User fills in specific details:
// - Talking Head: Script + Voice style
// - B-Roll: Motion style + Duration
// - Carousel: Template + Text overlay

// Generate button calls appropriate API
// Result saved to gallery
```

---

## What Each Screen Does

### GenerateScreen
- **Input:** Selfie upload + customization options
- **Output:** Generated image
- **Next:** ImageEditScreen

### ImageEditScreen
- **Input:** Generated image + edit prompt
- **Output:** Edited image
- **Next:** ConversionScreen

### ConversionScreen
- **Input:** Edited image
- **Output:** User choice (Talking Head / B-Roll / Carousel)
- **Next:** Selected conversion screen

### TalkingHeadScreen
- **Input:** Image + Script + Voice style
- **Output:** Talking head video
- **APIs:** ElevenLabs (voice) + Sync.so (lip sync)

### BrollScreen
- **Input:** Image + Motion style + Duration
- **Output:** B-Roll video
- **APIs:** Kling API

### CarouselScreen
- **Input:** Image + Template + Text
- **Output:** Social media carousel
- **APIs:** Creatomate

---

## Data Flow

```
GeneratedContent Model
├── originalImageUrl (from generation)
├── editedImageUrl (after edit)
├── prompt (original generation prompt)
├── editPrompt (edit modifications)
├── metadata (all settings used)
└── contentType ('original' or 'edited')

↓ Saved to Firestore
users/{uid}/content/{contentId}

↓ Used in conversion screens
TalkingHeadScreen / BrollScreen / CarouselScreen

↓ Final video/carousel generated
Saved back to Firestore + Storage
```

---

## API Integration Points

### Image Edit
```dart
// TODO: Implement in ApiService
await apiService.editImage(
  imageUrl: originalImageUrl,
  editPrompt: 'Add sunglasses',
);
```

### Talking Head
```dart
// ElevenLabs - Voice generation
await apiService.generateVoice(
  text: script,
  voiceId: selectedVoice,
);

// Sync.so - Lip sync
await apiService.generateLipSync(
  videoUrl: videoUrl,
  audioUrl: audioUrl,
);
```

### B-Roll
```dart
// Kling API - Video generation
await apiService.generateBRollVideo(
  imageUrl: imageUrl,
  motionStyle: 'slow_push',
);
```

### Carousel
```dart
// Creatomate - Carousel generation
await apiService.generateCarousel(
  imageUrls: [imageUrl],
  templateId: templateId,
);
```

---

## Status

✅ **Complete** - All screens connected and flowing properly
✅ **No Errors** - All code compiles without issues
✅ **Ready for API Integration** - Just need to implement actual API calls

---

## Next Steps

1. **Implement Image Edit API** - Connect to image editing service
2. **Implement Talking Head APIs** - ElevenLabs + Sync.so
3. **Implement B-Roll API** - Kling API
4. **Implement Carousel API** - Creatomate
5. **Test End-to-End** - Full flow from selfie to final video

---

## Quick Test

To test the flow:
1. Go to PhotoshootScreen
2. Click any style (e.g., "Business")
3. Upload a selfie
4. Click "RENDER TWIN"
5. You'll see ImageEditScreen
6. Enter an edit prompt (e.g., "Add sunglasses")
7. Click "APPLY EDIT"
8. Click "CONTINUE TO CONVERSION"
9. Choose Talking Head / B-Roll / Carousel
10. Fill in details and generate

**That's the complete user flow!** 🎬
