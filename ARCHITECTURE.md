# AIMR Twin Studio™ - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                             │
│                      (AIMR Twin Studio)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
        ┌───────▼──────┐ ┌───▼──────┐ ┌───▼──────┐
        │   Screens    │ │ Providers │ │ Services │
        └──────────────┘ └──────────┘ └──────────┘
                │             │             │
        ┌───────┴─────────────┴─────────────┴───────┐
        │                                           │
        │         Firebase Backend                 │
        │  ┌──────────────────────────────────┐   │
        │  │  Authentication (Email/Password) │   │
        │  │  Firestore (User Data & Content) │   │
        │  │  Storage (Images & Videos)       │   │
        │  └──────────────────────────────────┘   │
        │                                           │
        └───────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
    ┌───▼────┐          ┌────▼────┐          ┌────▼────┐
    │ Image  │          │ Video   │          │ Payment │
    │ Gen    │          │ Gen     │          │ System  │
    │ APIs   │          │ APIs    │          │         │
    └────────┘          └────────┘          └────────┘
```

---

## Layer Architecture

### 1. Presentation Layer (UI)
```
Screens/
├── SplashScreen          → App initialization & auth check
├── LoginScreen           → User authentication
├── RegisterScreen        → New user registration
├── MainShell             → Bottom navigation hub
│   ├── ExploreScreen     → Browse content
│   ├── PhotoshootScreen  → Image generation
│   ├── VideoScreen       → Video generation
│   └── EditScreen        → Content editing
├── GalleryScreen         → User's saved content
├── ProfileScreen         → User profile & settings
├── SubscriptionScreen    → Plans & purchases
├── CarouselScreen        → Carousel generator
├── BrollScreen           → B-Roll video generator
└── TalkingHeadScreen     → Talking head videos
```

### 2. State Management Layer (Providers)
```
Providers/
├── AuthProvider
│   ├── currentUser
│   ├── isAuthenticated
│   ├── signUp()
│   ├── signIn()
│   ├── signOut()
│   └── resetPassword()
│
├── ContentProvider
│   ├── contentList
│   ├── loadUserContent()
│   ├── saveContent()
│   └── deleteContent()
│
└── UserProvider
    ├── userProfile
    ├── credits
    ├── subscription
    ├── loadUserProfile()
    ├── addCredits()
    └── deductCredits()
```

### 3. Service Layer
```
Services/
├── FirebaseService
│   ├── Authentication
│   │   ├── signUp()
│   │   ├── signIn()
│   │   ├── signOut()
│   │   └── sendPasswordReset()
│   │
│   ├── Firestore
│   │   ├── createUserProfile()
│   │   ├── getUserProfile()
│   │   ├── updateUserProfile()
│   │   ├── saveGeneratedContent()
│   │   ├── getUserContent()
│   │   └── deleteContent()
│   │
│   └── Storage
│       ├── uploadImage()
│       ├── uploadVideo()
│       └── deleteFile()
│
└── ApiService
    ├── generateImage()
    ├── generateBRollVideo()
    ├── generateVoice()
    ├── generateCarousel()
    ├── generateLipSync()
    └── checkStatus()
```

### 4. Data Layer (Firebase)
```
Firebase/
├── Authentication
│   └── Email/Password auth
│
├── Firestore Database
│   └── users/
│       └── {uid}/
│           ├── email
│           ├── displayName
│           ├── credits
│           ├── subscription
│           └── content/
│               └── {contentId}/
│                   ├── title
│                   ├── type
│                   ├── imageUrl
│                   ├── prompt
│                   └── createdAt
│
└── Storage
    ├── images/
    │   └── {uid}/{imageId}
    └── videos/
        └── {uid}/{videoId}
```

---

## Data Flow Diagrams

### Authentication Flow
```
User Input (Email/Password)
    ↓
LoginScreen
    ↓
AuthProvider.signIn()
    ↓
FirebaseService.signIn()
    ↓
Firebase Auth
    ↓
User Authenticated ✓
    ↓
Navigate to MainShell
```

### Content Generation Flow
```
User Input (Prompt)
    ↓
GenerateScreen
    ↓
ApiService.generateImage()
    ↓
External API (DALL-E, etc.)
    ↓
Image Generated
    ↓
ContentProvider.saveContent()
    ↓
FirebaseService.saveGeneratedContent()
    ↓
Firestore + Storage
    ↓
Content Saved ✓
    ↓
Display in GalleryScreen
```

### User Profile Flow
```
App Launch
    ↓
AuthProvider checks auth state
    ↓
If authenticated:
    ↓
UserProvider.loadUserProfile()
    ↓
FirebaseService.getUserProfile()
    ↓
Firestore
    ↓
Profile Loaded
    ↓
Display in ProfileScreen
```

---

## Component Interaction

### Authentication System
```
┌─────────────────┐
│  LoginScreen    │
└────────┬────────┘
         │ uses
         ▼
┌─────────────────────┐
│  AuthProvider       │
│  - currentUser      │
│  - isAuthenticated  │
└────────┬────────────┘
         │ calls
         ▼
┌──────────────────────┐
│  FirebaseService     │
│  - signIn()          │
│  - signUp()          │
└────────┬─────────────┘
         │ uses
         ▼
┌──────────────────────┐
│  Firebase Auth       │
└──────────────────────┘
```

### Content Management System
```
┌──────────────────┐
│  GenerateScreen  │
└────────┬─────────┘
         │ uses
         ▼
┌──────────────────────┐
│  ContentProvider     │
│  - contentList       │
│  - saveContent()     │
└────────┬─────────────┘
         │ calls
         ▼
┌──────────────────────┐
│  FirebaseService     │
│  - saveContent()     │
│  - getUserContent()  │
└────────┬─────────────┘
         │ uses
         ▼
┌──────────────────────┐
│  Firestore + Storage │
└──────────────────────┘
```

---

## State Management Flow

### Provider Hierarchy
```
MultiProvider (main.dart)
├── AuthProvider
│   └── Listens to Firebase Auth state changes
│       └── Updates currentUser
│           └── Triggers UI rebuild
│
├── ContentProvider
│   └── Listens to Firestore content collection
│       └── Updates contentList
│           └── Triggers UI rebuild
│
└── UserProvider
    └── Loads user profile from Firestore
        └── Updates userProfile
            └── Triggers UI rebuild
```

### Widget Consumption
```
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.isAuthenticated) {
      return MainShell();
    } else {
      return LoginScreen();
    }
  }
)
```

---

## API Integration Points

### Image Generation
```
GenerateScreen
    ↓
ApiService.generateImage()
    ↓
External API (DALL-E, Stable Diffusion, etc.)
    ↓
Image URL returned
    ↓
Save to Firestore + Storage
```

### B-Roll Video Generation
```
BrollScreen
    ↓
ApiService.generateBRollVideo()
    ↓
Kling API
    ↓
Job ID returned
    ↓
Poll status with ApiService.checkStatus()
    ↓
Video URL returned
    ↓
Save to Firestore + Storage
```

### Voice Generation
```
TalkingHeadScreen
    ↓
ApiService.generateVoice()
    ↓
ElevenLabs API
    ↓
Audio URL returned
    ↓
Store audio URL
```

### Carousel Generation
```
CarouselScreen
    ↓
ApiService.generateCarousel()
    ↓
Creatomate API
    ↓
Job ID returned
    ↓
Poll status
    ↓
Video URL returned
    ↓
Save to Firestore + Storage
```

---

## Security Architecture

### Authentication
```
User Credentials
    ↓
Firebase Auth
    ↓
JWT Token (managed by Firebase)
    ↓
Authenticated Requests
```

### Authorization
```
Firestore Security Rules
    ↓
Check request.auth.uid
    ↓
Match with document owner
    ↓
Allow/Deny access
```

### Data Protection
```
User Data
    ↓
Encrypted in transit (HTTPS)
    ↓
Encrypted at rest (Firebase)
    ↓
Isolated by UID
```

---

## Scalability Considerations

### Database Optimization
- Firestore indexes for common queries
- Pagination for large content lists
- Caching strategies for frequently accessed data

### API Rate Limiting
- Queue system for generation requests
- Credit system to prevent abuse
- Exponential backoff for retries

### Storage Optimization
- Image compression before upload
- Video transcoding for multiple formats
- CDN for fast content delivery

### Performance
- Lazy loading of content
- Image caching with Provider
- Offline support with local storage

---

## Error Handling Strategy

```
Try Operation
    ↓
Success? → Update State → Notify UI
    ↓
Failure? → Capture Error → Show to User
    ↓
Retry? → Exponential Backoff → Try Again
    ↓
Max Retries? → Log Error → Suggest Action
```

---

## Testing Strategy

### Unit Tests
- Provider logic
- Service methods
- API calls

### Widget Tests
- Screen rendering
- User interactions
- State updates

### Integration Tests
- End-to-end flows
- Firebase integration
- API integration

---

## Deployment Architecture

```
Development
    ↓
Firebase Emulator (local testing)
    ↓
Staging
    ↓
Firebase Project (staging)
    ↓
Production
    ↓
Firebase Project (production)
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter |
| State Management | Provider |
| Backend | Firebase |
| Database | Firestore |
| Storage | Firebase Storage |
| Authentication | Firebase Auth |
| APIs | REST (HTTP) |
| Image Gen | DALL-E / Stable Diffusion |
| Video Gen | Kling API |
| Voice Gen | ElevenLabs |
| Carousel | Creatomate |
| Lip Sync | Sync.so |

---

## Future Enhancements

1. **Real-time Collaboration** - Multiple users editing same content
2. **Advanced Analytics** - Track user behavior and content performance
3. **ML Recommendations** - Suggest content based on user preferences
4. **Social Features** - Comments, likes, sharing
5. **Advanced Caching** - Service workers for offline support
6. **CDN Integration** - Faster content delivery globally

---

**This architecture is designed to be scalable, maintainable, and secure.**
