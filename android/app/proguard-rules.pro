# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Method Channels
-keep public class * implements io.flutter.plugin.common.MethodChannel.MethodCallHandler { *; }

# Google / Firebase
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# In-App Purchase (Billing Client)
-keep class com.android.billingclient.** { *; }

# Media / ExoPlayer
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Google Play Core & Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Kotlin & Desugaring
-dontwarn kotlinx.coroutines.**
-keepattributes *Annotation*,InnerClasses,Signature,EnclosingMethod
