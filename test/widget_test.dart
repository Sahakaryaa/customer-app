import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SahaKaryaCustomerApp()),
    );
    // Just verifies the app builds and renders
    expect(find.byType(SahaKaryaCustomerApp), findsOneWidget);
  });
}
