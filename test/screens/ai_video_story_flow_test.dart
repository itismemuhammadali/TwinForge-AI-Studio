import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_video_image_generation_app/screens/ai_video_story_creation_screen.dart';
import 'package:ai_video_image_generation_app/screens/ai_video_story_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiVideoStoryFlow Widget Tests', () {
    testWidgets('AiVideoStoryCreationScreen renders all steps, style grid, model cards, and duration pills', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiVideoStoryCreationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & tagline
      expect(find.text('TWINORA'), findsOneWidget);
      expect(find.text('CREATE YOUR AI STORY'), findsOneWidget);

      // Verify step headers
      expect(find.text('Your Photo'), findsOneWidget);
      expect(find.text('What do you want to happen?'), findsOneWidget);
      expect(find.text('Choose a Style'), findsOneWidget);
      expect(find.text('Choose Video Model'), findsOneWidget);
      expect(find.text('Video Settings'), findsOneWidget);

      // Verify video model options
      expect(find.text('Kling 1.6'), findsOneWidget);
      expect(find.text('Seedance 2.0'), findsOneWidget);

      // Verify duration pills
      expect(find.text('5s'), findsOneWidget);
      expect(find.text('10s'), findsOneWidget);
      expect(find.text('15s'), findsOneWidget);

      // Verify generate video button
      expect(find.text('GENERATE VIDEO'), findsOneWidget);
      expect(find.text('This will cost 20 credits'), findsOneWidget);
    });

    testWidgets('AiVideoStoryResultScreen renders title, model subtitle, action buttons, and prompt card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AiVideoStoryResultScreen(
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
            promptUsed: 'Cinematic shot. Walk into a luxury executive office.',
            videoModel: 'Kling 1.6',
            style: 'Cinematic',
            durationSeconds: 5,
          ),
        ),
      );
      await tester.pump();

      // Verify header title & model subtitle
      expect(find.text('Your AI Video'), findsOneWidget);
      expect(find.text('Generated with Kling 1.6'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Regenerate'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      // Verify prompt card title & generated prompt text
      expect(find.text('Prompt used '), findsOneWidget);
      expect(find.text('(AI Generated)'), findsOneWidget);
      expect(find.text('Cinematic shot. Walk into a luxury executive office.'), findsOneWidget);
    });
  });
}
