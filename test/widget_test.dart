import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_reporter/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FieldReporterApp(),
      ),
    );

    // Verify that the app renders
    expect(find.text('Field Reporter - Ready for Phase 1'), findsOneWidget);
  });
}
