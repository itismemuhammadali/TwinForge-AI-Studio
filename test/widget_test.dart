import 'package:flutter_test/flutter_test.dart';
import 'package:ai_video_image_generation_app/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AimrTwinApp());
    expect(find.text('TWINORA'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
