import 'package:flutter_test/flutter_test.dart';
import 'package:ai_video_image_generation_app/services/open_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenAiService Unit Tests', () {
    final openAiService = OpenAiService();

    test('generateOptimizedVideoPrompt returns non-empty fallback prompt when API key is empty', () async {
      final prompt = await openAiService.generateOptimizedVideoPrompt(
        userPrompt: 'Walk into a luxury executive office',
        style: 'Cinematic',
        videoModel: 'Kling 1.6',
      );

      expect(prompt, isNotEmpty);
      expect(prompt, contains('Walk into a luxury executive office'));
      expect(prompt, contains('Cinematic'));
    });

    test('generateOptimizedVideoPrompt handles Seedance 2.0 framework correctly', () async {
      final prompt = await openAiService.generateOptimizedVideoPrompt(
        userPrompt: 'Standing on a rooftop at sunset',
        style: 'Luxury',
        videoModel: 'Seedance 2.0',
      );

      expect(prompt, isNotEmpty);
      expect(prompt, contains('Standing on a rooftop at sunset'));
    });

    test('generateOptimizedVideoPrompt supports all 5 visual styles', () async {
      final styles = ['Cinematic', 'UGC', 'Luxury', 'Viral Reel', 'Netflix Documentary'];

      for (final style in styles) {
        final result = await openAiService.generateOptimizedVideoPrompt(
          userPrompt: 'Walking through NYC SoHo',
          style: style,
          videoModel: 'Kling 1.6',
        );

        expect(result, isNotEmpty);
      }
    });
  });
}
