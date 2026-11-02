import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/checkout/widgets/checkout_payment_and_review.dart';
import 'package:nvit_app/models/delivery.dart';
import 'package:nvit_app/models/order.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Partial COD / Advance Payment Tests', () {
    test('StoreSettings.partialCodQuote calculates advance and balance correctly', () {
      final settings = StoreSettings(
        freeDeliveryThreshold: 500,
        deliveryCharge: 49,
        partialCodEnabled: true,
        partialCodPercent: 20,
        partialCodMinimum: 100,
      );

      // Order total = 1000: 20% = 200, balance = 800
      final quote1 = settings.partialCodQuote(1000);
      expect(quote1.advance, 200.0);
      expect(quote1.balance, 800.0);

      // Order total = 300: 20% = 60, but minimum is 100 -> advance = 100, balance = 200
      final quote2 = settings.partialCodQuote(300);
      expect(quote2.advance, 100.0);
      expect(quote2.balance, 200.0);

      // Order total = 50: min 100 capped by total -> advance = 50, balance = 0
      final quote3 = settings.partialCodQuote(50);
      expect(quote3.advance, 50.0);
      expect(quote3.balance, 0.0);
    });

    test('Order model parses partialCod and computes codDueAmount correctly', () {
      final json = {
        'id': 'ord-123',
        'orderNumber': 'KKN-123',
        'totalAmount': 1000.0,
        'status': 'CONFIRMED',
        'paymentMethod': 'CASHFREE',
        'paymentStatus': 'ADVANCE_PAID',
        'partialCod': true,
        'advanceAmount': 200.0,
        'onlinePaidAmount': 200.0,
        'createdAt': '2026-11-02T10:00:00Z',
      };

      final order = Order.fromJson(json);
      expect(order.partialCod, isTrue);
      expect(order.advanceAmount, 200.0);
      expect(order.onlinePaidAmount, 200.0);
      expect(order.codDueAmount, 800.0);
      expect(order.isPaidOnline, isTrue);
    });

    testWidgets('CheckoutPaymentSection renders Partial COD option with advance amount and zero fee badge', (tester) async {
      String selectedMethod = 'CASHFREE';

      final settings = StoreSettings(
        freeDeliveryThreshold: 500,
        deliveryCharge: 49,
        partialCodEnabled: true,
        partialCodPercent: 20,
        partialCodMinimum: 100,
        codEnabled: true,
        onlinePaymentsEnabled: true,
      );

      final deliveryInfo = DeliveryInfo(
        pincode: '760001',
        city: 'Brahmapur',
        serviceable: true,
        cod: true,
        prepaid: true,
        deliveryDays: 1,
        deliveryDaysMax: 2,
        source: 'courier',
        message: 'Delivery in 1-2 days',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeSettingsProvider.overrideWith((ref) => Future.value(settings)),
            paymentAvailabilityStatusProvider.overrideWith((ref) => Future.value(
                  const PaymentAvailabilityStatus(
                    onlineEnabled: true,
                    codEnabled: true,
                    userCodAllowed: true,
                    partialCodEnabled: true,
                  ),
                )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return CheckoutPaymentSection(
                    paymentMethod: selectedMethod,
                    delivery: deliveryInfo,
                    codConfirmationEnabled: false,
                    total: 1000.0,
                    onPaymentMethodChanged: (method) {
                      setState(() => selectedMethod = method);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 3 options are displayed
      expect(find.text('Pay online (UPI / Card / Netbanking)'), findsOneWidget);
      expect(find.text('Pay ₹200 advance now'), findsOneWidget);
      expect(find.text('₹0 COD Fee'), findsOneWidget);
      expect(find.text('₹800 on delivery'), findsOneWidget);
      expect(find.text('Cash on Delivery (COD)'), findsOneWidget);

      // Tap on Partial COD option
      await tester.tap(find.text('Pay ₹200 advance now'));
      await tester.pumpAndSettle();

      expect(selectedMethod, 'PARTIAL_COD');
    });
  });
}
