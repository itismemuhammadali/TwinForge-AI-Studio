import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_video_image_generation_app/screens/talking_head_creation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: TalkingHeadCreationScreen(),
    );
  }

  group('TalkingHeadCreationScreen Widget Tests', () {
    testWidgets('renders header, prompt input field, style cards, and video model selectors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify header title
      expect(find.text('CREATE TALKING HEAD'), findsOneWidget);

      // Verify prompt label and text field
      expect(find.text('WHAT DO YOU WANT TO HAPPEN?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify visual style section
      expect(find.text('CHOOSE VISUAL STYLE'), findsOneWidget);
      expect(find.text('Cinematic'), findsOneWidget);
      expect(find.text('UGC'), findsOneWidget);
      expect(find.text('Luxury'), findsOneWidget);

      // Verify video model section
      expect(find.text('CHOOSE VIDEO MODEL'), findsOneWidget);
      expect(find.text('Kling 1.6'), findsOneWidget);
      expect(find.text('Seedance 2.0'), findsOneWidget);

      // Verify generate button
      expect(find.text('GENERATE TALKING HEAD'), findsOneWidget);
    });

    testWidgets('allows selecting video model engine cards', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final seedanceCard = find.text('Seedance 2.0');
      expect(seedanceCard, findsOneWidget);

      await tester.tap(seedanceCard, warnIfMissed: false);
      await tester.pumpAndSettle();
    });
  });
}
