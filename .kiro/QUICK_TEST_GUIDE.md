# Quick Testing Guide - Template Prompt Generation

## What Changed
The Gemini prompt now extracts **DETAILED scene descriptions** instead of generic vague text.

### Old Prompt (Useless)
❌ "A person in a professional, stylized pose with excellent lighting and composition"

### New Prompt (Detailed)
✅ "A meeting room with 5 people. Three seated around table facing camera with papers/laptops. Two standing in background - one facing left, one in profile. Natural light from windows on right creates bright highlights on table with soft shadows on faces..."

---

## Quick Test Steps

### Test 1: Open and Analyze Template
1. **Launch app** → Navigate to PhotoshootScreen (template selection)
2. **Click any template image** (preferably one with multiple people/complex scene)
3. **GenerateScreen opens** → Watch the prompt box
4. **Loading state** → Should show spinner + "Analyzing template style..."
5. **Wait 10-20 seconds** → Gemini API processes
6. **Result** → Prompt appears in text box

**What to look for:**
- ✅ Prompt describes the actual scene in detail
- ✅ Mentions specific elements (people, furniture, setting)
- ✅ Describes poses and positions
- ✅ NOT generic bullshit
- ✅ Text is editable

---

### Test 2: Edit and Use Prompt
1. **Template prompt displays** 
2. **Edit the text** (make any changes)
3. **Upload your own photo** in PHASE 01
4. **Scroll to PHASE 04** → Final Touches
5. **Click RENDER TWIN** button
6. **Generation runs** with your edited prompt
7. **Image appears** in ImageEditScreen

**What to look for:**
- ✅ Your edits are preserved
- ✅ Generation uses your edited prompt
- ✅ Image reflects the scene description

---

### Test 3: Error Handling (Optional)
1. **Poor internet** → Watch error state
2. **Click "Retry"** → Should retry analysis
3. **Click "Skip & Continue"** → Should proceed without prompt

**What to look for:**
- ✅ Error messages are clear
- ✅ Retry button works
- ✅ Skip option is available

---

## Expected Prompt Quality

### Good ✅
- "Meeting room with wooden conference table, 5 people seated around it..."
- "Professional office setting, two people standing by window discussing documents..."
- "Casual coffee shop scene, person at table with laptop, facing camera, warm lighting..."

### Bad ❌
- "A professional setting"
- "Person in a nice pose"
- "Good lighting and composition"

---

## Troubleshooting

### If prompt doesn't show:
1. Check internet connection
2. Wait 15-20 seconds (API can be slow)
3. Check Firebase Remote Config has Gemini API key

### If prompt is still generic:
1. Template might not have enough detail
2. Try a different template image
3. Gemini API sometimes needs retry

### If button is disabled:
1. Wait for template analysis to complete
2. Upload an image in PHASE 01 first

---

## Success Criteria
- ✅ Prompt describes **actual scene** (not generic)
- ✅ Mentions **specific elements** (people, objects, settings)
- ✅ **Detailed poses & positions** are described
- ✅ Prompt is **editable**
- ✅ **Image generates** with edited prompt
- ✅ **No crashes**

---

**Ready to test! 🚀**
