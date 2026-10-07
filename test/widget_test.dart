import 'package:flutter_test/flutter_test.dart';
import 'package:communication/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ArgusApp(),
      ),
    );

    // Verify that the brand name "ARGUS" is found on the splash screen.
    expect(find.text('ARGUS'), findsOneWidget);
  });
}
