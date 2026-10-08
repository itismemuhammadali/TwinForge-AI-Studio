import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/content_provider.dart';
import 'providers/user_provider.dart';
import 'providers/carousel_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/library_provider.dart';
import 'services/firebase_service.dart';
import 'services/trending_service.dart';
import 'services/higgsfield_service.dart';

import 'services/open_ai_service.dart';
import 'services/iap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase before running the app to ensure Auth state is recovered
  try {
    await FirebaseService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize OpenAI Service (Prompt Intelligence Layer)
  try {
    await OpenAiService.initialize();
  } catch (e) {
    debugPrint('OpenAiService initialization failed: $e');
  }

  // Initialize TrendingService
  try {
    await TrendingService.initialize();
  } catch (e) {
    debugPrint('TrendingService initialization failed: $e');
  }

  // Initialize Higgsfield Service
  try {
    await HiggsfieldService.initialize();
  } catch (e) {
    debugPrint('HiggsfieldService initialization failed: $e');
  }

  runApp(const AimrTwinApp());
}

class AimrTwinApp extends StatelessWidget {
  const AimrTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CarouselProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => IapService()),
      ],
      child: MaterialApp(
        title: 'Twinora',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFB1946C),
            surface: Color(0xFF1A1A1A),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
