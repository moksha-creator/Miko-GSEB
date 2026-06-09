import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_ipad/main.dart';

void main() {
  testWidgets('Smoke test - builds StudentIpadApp successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: StudentIpadApp()));
  });
}
