# Talking Heads Workflow - Complete Implementation Plan

## Overview
Complete workflow from image selection through video generation with voice to final stitching with audio/voice cloning.

---

## Workflow Flow Chart

```
Explorer Screen
    ↓
Talking Head Options Screen
├─ Upload from Gallery
├─ Select from Library
└─ Create Template (Generate Image)
    ↓
Review Screen (Image preview + "TURN INTO TALKING HEAD" button)
    ↓
[NEW] Talking Head Setup Screen
├─ Image Preview
├─ Duration Selector (1-15 seconds, slider)
├─ Prompt Box (for video description)
└─ Generate Video Button
    ↓
[NEW] Talking Head Generation Screen
├─ Display Generated Video
├─ Regenerate Button
└─ Proceed Button
    ↓
[NEW] Talking Head Review Screen
├─ Video Preview
├─ Save to Gallery checkbox
└─ Proceed to Voice Button
    ↓
[NEW] Talking Head Voice Options Screen
├─ Option 1: Voice Cloning
│  ├─ Upload Audio Sample
│  ├─ Enter Script/Prompt
│  └─ Generate Voice (FAL AI)
├─ Option 2: Record Microphone
│  ├─ Record Audio (max = video duration)
│  ├─ Play/Review Audio
│  └─ Proceed Button
    ↓
[NEW] Talking Head Stitch Screen
├─ Show Stitching Progress (Sync Labs API)
├─ Display Stitched Video
├─ Save to Gallery checkbox
└─ Save Video Button
    ↓
Saved to Gallery/Library
```

---

## Screen-by-Screen Implementation Details

### Screen 1: Talking Head Options (NEW)
**Purpose:** Allow user to choose image source for talking head creation

**UI Components:**
- Three large tappable cards:
  1. "Upload from Gallery" → Image picker
  2. "Select from Library" → Show user's previous images
  3. "Create Template" → Navigate to template generation
- Each option navigates to Review Screen with selected image

**Logic:**
- Gallery pick → Validate image → Go to Review Screen
- Library select → Load image → Go to Review Screen
- Template → Navigate to template generation flow → Review Screen

---

### Screen 2: Review Screen (EXISTING - MODIFY)
**Purpose:** Preview selected/generated image before turning into talking head

**Existing UI:**
- Large image preview
- "TURN INTO TALKING HEAD" button ← **Current button, keep as is**

**Button Action:**
- Navigate to: **Talking Head Setup Screen**
- Pass data: Selected image + file path

---

### Screen 3: Talking Head Setup Screen (NEW - PRIORITY)
**Purpose:** Set duration and video prompt before generation

**UI Components:**

#### 3.1 Image Preview (Top)
- Display the selected image in a rounded container
- Size: ~200x300 or proportional to screen
- Border: Gold accent border (0.5-1.5pt)

#### 3.2 Duration Selector (Slider)
- **Type:** Horizontal slider (NOT discrete points)
- **Range:** 1-15 seconds
- **Display:** Show current value (e.g., "8 seconds")
- **Interaction:** Smooth dragging, real-time value update
- **Visual:** Gold color for track fill, circular thumb

#### 3.3 Prompt Box (Text Input)
- **Label:** "Describe the video prompt"
- **Placeholder:** "How should the video look? What should happen?"
- **Type:** Multi-line TextField
- **Height:** ~120-150px
- **Behavior:** User types the prompt describing desired video outcome

#### 3.4 Generate Video Button
- **Label:** "GENERATE VIDEO"
- **Style:** Gold button (filled)
- **Action:** 
  - Validate: duration selected, prompt entered
  - Call FAL AI Kling V3 with:
    - `videoInput`: selected image file
    - `prompt`: user-entered prompt
    - `duration`: selected duration (1-15 seconds)
  - Navigate to: Talking Head Generation Screen

**Data to Store (Provider):**
```
- selectedImage: File
- selectedDuration: int (1-15)
- videoPrompt: String
- generatedVideoUrl: String (empty until generation complete)
```

---

### Screen 4: Talking Head Generation Screen (NEW)
**Purpose:** Show video generation progress and preview generated video

**UI Components:**

#### 4.1 Loading State (During Generation)
- Circular progress indicator (gold)
- Text: "Generating Video..."
- Subtitle: "Using Kling V3, this may take 1-5 minutes"

#### 4.2 Video Preview (After Generation)
- VideoPlayer showing generated video
- Play/Pause controls
- Full-width, rounded corners, gold border

#### 4.3 Action Buttons
- **Regenerate Button** (Outlined)
  - Action: Go back to Setup Screen with same settings
  - Allow user to modify prompt/duration and try again
- **Proceed Button** (Filled Gold)
  - Action: Navigate to Talking Head Review Screen
  - Pass: generatedVideoUrl, selectedDuration

**Data Flow:**
- Input: selectedImage, selectedDuration, videoPrompt (from previous screen)
- Process: Call FAL AI Kling V3 API
- Output: generatedVideoUrl stored in provider
- Storage: Save in TalkingHeadProvider

---

### Screen 5: Talking Head Review Screen (NEW)
**Purpose:** Final preview of generated video before voice work

**UI Components:**

#### 5.1 Video Preview
- Same as Generation Screen
- VideoPlayer with play/pause

#### 5.2 Save to Gallery Checkbox
- **Label:** "Save video to gallery"
- **Type:** Checkbox
- **Default:** OFF
- **Behavior:** If checked, video will be saved to device gallery after stitching

#### 5.3 Proceed to Voice Button
- **Label:** "PROCEED TO VOICE"
- **Action:** Navigate to Voice Options Screen

---

### Screen 6: Talking Head Voice Options Screen (NEW)
**Purpose:** Choose between voice cloning or microphone recording

**UI Components:**

#### 6.1 Two Option Cards (Tappable)

**Option 1: Voice Cloning**
- **Icon:** Person speaking icon
- **Title:** "VOICE CLONING"
- **Subtitle:** "Upload sample + script = AI voice"
- **Action:** 
  - Navigate to Voice Cloning Sub-Screen
  - Collect: Audio sample file + Script text
  - Call FAL AI voice cloning model
  - Generate audio with script

**Option 2: Record Microphone**
- **Icon:** Microphone icon
- **Title:** "RECORD VOICE"
- **Subtitle:** "Record your own voice"
- **Action:**
  - Navigate to Microphone Recording Screen

---

### Screen 6A: Voice Cloning Sub-Screen (NEW - OPTIONAL)
**Purpose:** Upload voice sample and script for voice cloning

**UI Components:**

#### 6A.1 Audio Sample Upload
- Button: "Upload Voice Sample (mp3, wav, m4a)"
- Displays: Uploaded file name + play button
- Playback: AudioPlayer to preview the sample

#### 6A.2 Script Input
- Multi-line TextField
- **Placeholder:** "Enter the script/prompt for the AI voice"
- **Note:** Script will be converted to speech using the uploaded voice sample

#### 6A.3 Generate Voice Button
- **Label:** "GENERATE VOICE"
- **Validation:** Audio sample + Script both provided
- **Action:**
  - Call FAL AI voice cloning model:
    - `audio_sample`: uploaded audio bytes
    - `script`: user script text
    - `video_duration`: video duration (for matching)
  - Store generated audio URL in provider
  - Navigate to Stitch Screen

---

### Screen 6B: Microphone Recording Screen (NEW - PRIORITY)
**Purpose:** Record audio with duration limit matching video

**UI Components:**

#### 6B.1 Duration Limit Info Box
- **Display:** "Maximum recording: {selectedDuration} seconds"
- **Warning Color:** Gold/yellow accent
- **Info Text:** "Audio cannot exceed video duration"

#### 6B.2 Recording Button (Large Circular)
- **Design:** Large circle (80x80px minimum)
- **Icon:** Microphone icon
- **Behavior:**
  - TAP to START recording
  - TAP again to STOP recording
  - Shows: "TAP TO RECORD" when idle
  - Shows: "Recording... {currentSeconds}s" when active (red background)
  - Auto-stops when max duration reached

#### 6B.3 Recording Controls (When Recording)
- **STOP Button:** Finalize recording
- **CANCEL Button:** Discard recording and start over

#### 6B.4 Audio Playback (After Recording)
- Play/Pause button (circular, gold)
- Shows: Audio duration vs video duration
- Playback with AudioPlayer
- Visual feedback: Different UI when audio is ready

#### 6B.5 Action Buttons (After Recording)
- **RECORD NEW Button** (Outlined)
  - Discard current recording, start fresh
- **PROCEED Button** (Filled Gold)
  - Validate: Audio duration ≤ video duration
  - Store audio URL in provider
  - Navigate to Stitch Screen

**Data to Store:**
```
- recordedAudioUrl: String (local file path initially)
- recordedAudioDuration: int (seconds)
- uploadedAudioUrl: String (after Firebase upload)
```

**Important Constraints:**
- Max recording duration = video duration
- Audio format: .m4a (AAC codec)
- Auto-stop recording when max duration reached
- Show countdown timer during recording

---

### Screen 7: Talking Head Stitch Screen (NEW - PRIORITY)
**Purpose:** Combine video with audio/voice using Sync Labs lip sync API

**UI Components:**

#### 7.1 Stitching State (During Processing)
- Circular progress indicator (gold, spinning)
- Text: "Stitching Audio..."
- Subtitle: "Syncing lips with audio (may take 5-10 minutes)"
- Large animated icon

#### 7.2 Video Preview (After Stitching Complete)
- VideoPlayer showing lip-synced video
- Play/Pause controls
- Gold border, rounded corners
- Full width

#### 7.3 Save Options Checkbox
- **Label:** "Save to gallery"
- **Default:** OFF
- **Behavior:** If checked, save to device gallery; otherwise save to library

#### 7.4 Action Buttons
- **SAVE VIDEO Button** (Filled Gold)
  - Action: Save video based on checkbox setting
  - Navigate back to home/library
  - Show success message

#### 7.5 Error Handling
- Show error message if stitching fails
- Provide RETRY button
- BACK button to return to previous screen

---

## API Calls & Integration Points

### API 1: FAL AI Kling V3 (Video Generation)
**Endpoint:** FAL AI via `fal.run()`

**Input:**
```json
{
  "video_input": File/Buffer,
  "prompt": String,
  "duration_seconds": int (1-15)
}
```

**Output:**
```json
{
  "video": String (video URL)
}
```

**Provider to Call:** `FalAiService` or existing service

---

### API 2: FAL AI Voice Cloning (Optional)
**Endpoint:** FAL AI voice cloning model

**Input:**
```json
{
  "audio_sample": Buffer,
  "script": String,
  "duration_seconds": int
}
```

**Output:**
```json
{
  "audio": String (audio URL)
}
```

---

### API 3: Sync Labs Lip Sync
**Endpoint:** `POST https://api.sync.so/v2/generate`

**Headers:**
```
x-api-key: {SYNCLABS_API_KEY} (from Firebase Remote Config)
Content-Type: application/json
```

**Request Body:**
```json
{
  "model": "sync-3",
  "input": [
    {"type": "video", "url": String},
    {"type": "audio", "url": String}
  ],
  "options": {"sync_mode": "loop"}
}
```

**Response:**
```json
{
  "id": String (generation ID)
}
```

**Polling Endpoint:** `GET https://api.sync.so/v2/generate/{generationId}`

**Poll Response:**
```json
{
  "status": "COMPLETED|PROCESSING|FAILED",
  "outputUrl": String (video URL, only if COMPLETED),
  "error": String (if FAILED)
}
```

**Poll Interval:** 5 seconds
**Timeout:** 10-15 minutes

---

## State Management (Provider)

### TalkingHeadProvider Class
```dart
class TalkingHeadProvider extends ChangeNotifier {
  // Image Selection
  File? selectedImage;
  
  // Video Settings
  int selectedDuration = 8; // 1-15 seconds
  String videoPrompt = '';
  String? generatedVideoUrl;
  
  // Voice Options
  VoiceMode voiceMode; // VoiceMode.CLONE | VoiceMode.MICROPHONE
  
  // Voice Cloning
  File? voiceSampleFile;
  String voiceScript = '';
  String? generatedVoiceUrl;
  
  // Microphone Recording
  String? recordedAudioUrl; // Local file path during recording
  int recordedAudioDuration = 0;
  String? uploadedAudioUrl; // Firebase URL after upload
  
  // Final Stitching
  String? stitchedVideoUrl;
  bool saveToGallery = false;
  
  // Methods
  void setSelectedImage(File image) { }
  void setDuration(int seconds) { }
  void setVideoPrompt(String prompt) { }
  void setGeneratedVideoUrl(String url) { }
  void setVoiceMode(VoiceMode mode) { }
  void setRecordedAudioUrl(String url, {required int durationSeconds}) { }
  void setStitchedVideoUrl(String url) { }
  void reset() { } // Clear all data after saving
}
```

---

## File Structure to Create

```
lib/
├── providers/
│   └── talking_head_provider.dart (NEW)
├── screens/
│   ├── talking_head_options_screen.dart (NEW)
│   ├── talking_head_setup_screen.dart (NEW)
│   ├── talking_head_generation_screen.dart (NEW)
│   ├── talking_head_review_screen.dart (NEW)
│   ├── talking_head_voice_options_screen.dart (NEW)
│   ├── talking_head_voice_cloning_screen.dart (NEW - OPTIONAL)
│   ├── talking_head_microphone_screen.dart (NEW)
│   └── talking_head_stitch_screen.dart (NEW)
├── services/
│   ├── audio_recording_service.dart (NEW)
│   └── (update StorageService for audio upload)
└── widgets/
    └── (existing app_widgets.dart for buttons, etc.)
```

---

## Dependencies Required (Verify in pubspec.yaml)

- `provider` - State management
- `record` - Audio recording (microphone)
- `audioplayers` - Audio playback
- `video_player` - Video preview/playback
- `http` - HTTP requests (Sync Labs API)
- `firebase_remote_config` - Fetch API keys (Sync Labs)
- `firebase_storage` - Upload audio files
- `firebase_auth` - User authentication
- `cloud_firestore` - Store video metadata
- `image_picker` - Pick audio/video files
- `gal` - Save to device gallery
- `path_provider` - Get temp directory for recordings
- `image` - Image manipulation (if needed)

---

## Implementation Order (Tasks)

### Task 1: Create TalkingHeadProvider
- State management for entire workflow
- Store: image, duration, prompt, video, audio, settings
- Methods to update each field

### Task 2: Create Talking Head Options Screen
- Three cards: Gallery, Library, Template
- Navigation logic to Review Screen

### Task 3: Create Talking Head Setup Screen ⭐
- Image preview at top
- Duration slider (1-15 seconds)
- Prompt text box
- Generate Video button → calls FAL AI Kling V3
- Navigate to Generation Screen

### Task 4: Create Talking Head Generation Screen
- Show loading state during video generation
- Show video preview when ready
- Regenerate button → back to Setup
- Proceed button → Review Screen

### Task 5: Create Talking Head Review Screen
- Video preview
- Save to gallery checkbox
- Proceed to Voice button

### Task 6: Create Talking Head Voice Options Screen
- Two option cards (Voice Cloning | Microphone)
- Navigate to respective sub-screens

### Task 7: Create Talking Head Voice Cloning Screen (OPTIONAL)
- Upload audio sample
- Enter script
- Call FAL AI voice cloning
- Navigate to Stitch Screen

### Task 8: Create Audio Recording Service ⭐
- Start recording (check permissions)
- Stop recording
- Get duration
- Auto-stop when max duration reached
- Export as .m4a

### Task 9: Create Talking Head Microphone Screen ⭐
- Record button (TAP to start/stop)
- Show duration countdown
- Max duration limit enforcement (auto-stop)
- Play/review recorded audio
- Validate before proceed
- Navigate to Stitch Screen

### Task 10: Create Talking Head Stitch Screen ⭐
- Call Sync Labs API with video + audio
- Poll status endpoint
- Handle completion/failure
- Show stitched video
- Save to gallery/library
- Navigate back to home

### Task 11: Update Review Screen
- Add "TURN INTO TALKING HEAD" button (modify existing)
- Navigate to Talking Head Setup Screen
- Pass selected image

### Task 12: Add Provider to main.dart
- Wrap app with `ChangeNotifierProvider(create: (_) => TalkingHeadProvider())`

### Task 13: Testing & Debugging
- Test full end-to-end workflow
- Handle edge cases (permissions, network errors, API failures)
- Test duration constraints
- Verify audio upload to Firebase
- Verify Sync Labs lip sync integration

---

## Edge Cases & Constraints

### Duration Management
- Slider: 1-15 seconds (NOT discrete points)
- Audio recording: Max = video duration
- Audio upload: Validate against video duration
- Auto-stop recording if max duration reached

### Audio Constraints
- Format: .m4a (AAC codec, 128kbps, 44.1kHz)
- Permissions: Microphone access required
- Upload: To Firebase Storage before Sync Labs API call

### API Constraints
- FAL AI video generation: 1-5 minute wait (loading screen)
- Sync Labs lip sync: 5-10 minute wait (polling with 5s interval)
- Handle API failures: Show error, retry option

### Error Handling
- Missing image → Show error, go back
- Empty prompt → Disable Generate button
- No microphone permission → Show permission denied
- Audio exceeds video duration → Show validation error
- Sync Labs timeout → Show error, retry button

---

## UI/UX Notes

- **Color Scheme:** Use existing app theme (Gold accents, dark background)
- **Buttons:** Gold for primary actions, outlined for secondary
- **Progress:** Circular indicators for loading states
- **Feedback:** SnackBars for success/error messages
- **Navigation:** Back buttons on all new screens
- **Validation:** Disable buttons until requirements met

---

## No Implementation Yet
This plan is **PLANNING ONLY**. Do NOT start coding until approved.
