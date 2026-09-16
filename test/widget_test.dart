import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/main.dart';
import 'package:canteen_app/screens/onboarding_screen.dart';

void main() {
  testWidgets('CanteenApp launches and renders onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CanteenApp());
    await tester.pump();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Order from anywhere'), findsOneWidget);
  });
}
