import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/booking.dart';
import 'package:customer_app/theme/app_theme.dart';
import 'package:customer_app/widgets/app_button.dart';
import 'package:customer_app/widgets/soft_card.dart';
import 'package:customer_app/widgets/status_chip.dart';

void main() {
  testWidgets('Design-system smoke test — core widgets render',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SoftCard(
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StatusChip(status: BookingStatus.enRoute),
                AppButton(
                  label: 'Book Now',
                  isAmber: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('En Route'), findsOneWidget);
    expect(find.text('Book Now'), findsOneWidget);
  });
}
