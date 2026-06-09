import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teacher_phone/main.dart';

void main() {
  testWidgets('Smoke test - builds TeacherPhoneApp successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TeacherPhoneApp()));
  });
}
