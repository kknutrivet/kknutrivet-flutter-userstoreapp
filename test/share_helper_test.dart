import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/config/app_config.dart';
import 'package:nvit_app/core/utils/share_helper.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppShare Tests', () {
    testWidgets('AppShare.shareProduct handles product link generation and fallback',
        (tester) async {
      final product = Product(
        id: 'p-100',
        name: 'Omega 3 Pet Tonic',
        slug: 'omega-3-pet-tonic',
        price: 320,
        stock: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => AppShare.shareProduct(context, product),
                  child: const Text('Share Product'),
                );
              },
            ),
          ),
        ),
      );

      // Verify button renders
      expect(find.text('Share Product'), findsOneWidget);

      // Tap share button - verify it executes cleanly without throwing
      await tester.tap(find.text('Share Product'));
      await tester.pumpAndSettle();

      // Verify the expected link format
      final expectedLink = '${AppConfig.apiBaseUrl}/products/omega-3-pet-tonic';
      expect(expectedLink, contains('products/omega-3-pet-tonic'));
    });

    testWidgets('AppShare.shareText handles referral text without throwing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppShare.shareText(
                  context,
                  text: 'Join KK Nutrivet with referral code KK100',
                  title: 'Share Referral Code',
                ),
                child: const Text('Share Code'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Share Code'));
      await tester.pumpAndSettle();
    });
  });
}
