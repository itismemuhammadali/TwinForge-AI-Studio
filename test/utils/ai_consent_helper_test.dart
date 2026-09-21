import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_video_image_generation_app/utils/ai_consent_helper.dart';
import 'package:ai_video_image_generation_app/providers/user_provider.dart';

class MockUserProvider extends ChangeNotifier implements UserProvider {
  bool _consent = false;

  @override
  bool get aiDataConsentGranted => _consent;

  @override
  Future<void> setAiDataConsent(bool granted) async {
    _consent = granted;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

    testWidgets('pumps AiConsentHelper modal and renders title and controls properly', (tester) async {
      final mockProvider = MockUserProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AiConsentHelper.ensureConsent(context, allowMaybeLater: true),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('AI Content Processing'), findsOneWidget);
      expect(find.text('Agree & Continue'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
    });
  });
}
