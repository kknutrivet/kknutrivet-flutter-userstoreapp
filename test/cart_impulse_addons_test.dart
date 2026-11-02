import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/cart/widgets/cart_impulse_addons.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  final sampleProduct = Product(
    id: 'extra-1',
    slug: 'pet-grooming-glove',
    name: 'Pet Grooming Glove',
    price: 120,
    mrp: 180,
    stock: 20,
    category: 'Grooming',
    animalTypes: ['Dog', 'Cat'],
  );

  testWidgets(
      'CartImpulseAddonsSection renders title, subtitle, and product card',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartImpulseAddonsProvider(0)
              .overrideWith((ref) async => [sampleProduct]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CartImpulseAddonsSection(
                amountForFreeDelivery: 0,
                qualifiesForFreeDelivery: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Useful extras for your animal'), findsOneWidget);
    expect(
      find.text('Food, grooming and accessories matched to your cart'),
      findsOneWidget,
    );
    expect(find.text('Pet Grooming Glove'), findsOneWidget);
    expect(find.text('₹120'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets(
      'CartImpulseAddonsSection renders free delivery gap message when not qualified',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartImpulseAddonsProvider(80)
              .overrideWith((ref) async => [sampleProduct]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CartImpulseAddonsSection(
                amountForFreeDelivery: 80,
                qualifiesForFreeDelivery: false,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Useful extras for your animal'), findsOneWidget);
    expect(
      find.text(
          'Add ₹80 more for free delivery. Extras matched to your animal.'),
      findsOneWidget,
    );
  });
}
