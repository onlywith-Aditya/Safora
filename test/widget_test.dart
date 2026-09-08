import 'package:flutter_test/flutter_test.dart';
import 'package:safora/core/constants/app_strings.dart';
import 'package:safora/main.dart';

void main() {
  testWidgets('Splash screen loads brand text test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SafeGuardApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the brand name is present on the splash screen.
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text('Safora'), findsOneWidget);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
  });
}
