import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_video_image_generation_app/utils/ai_consent_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiConsentHelper Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('hasConsentedLocally returns false initially', () async {
      final consented = await AiConsentHelper.hasConsentedLocally();
      expect(consented, false);
    });

    test('hasConsentedLocally returns true when key is set', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_data_consent_granted', true);

      final consented = await AiConsentHelper.hasConsentedLocally();
      expect(consented, true);
    });
  });
}
