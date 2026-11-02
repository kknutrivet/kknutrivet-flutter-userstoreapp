import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/animations/app_animations.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  group('AppAnimations Tests', () {
    testWidgets('AppBounce scales down on tap down and returns on tap up', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppBounce(
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('Tap Me'),
                ),
              ),
            ),
          ),
        ),
      );

      final scaleFinder = find.descendant(
        of: find.byType(AppBounce),
        matching: find.byType(ScaleTransition),
      );
      expect(scaleFinder, findsOneWidget);

      var scaleWidget = tester.widget<ScaleTransition>(scaleFinder);
      expect(scaleWidget.scale.value, 1.0);

      // Press down (wait for press timeout + animation duration)
      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap Me')));
      await tester.pump(kPressTimeout);
      await tester.pump(const Duration(milliseconds: 100));

      scaleWidget = tester.widget<ScaleTransition>(scaleFinder);
      expect(scaleWidget.scale.value, lessThan(1.0));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      scaleWidget = tester.widget<ScaleTransition>(scaleFinder);
      expect(scaleWidget.scale.value, 1.0);
      expect(tapped, isTrue);
    });

    testWidgets('AppTextSwitcher renders and updates text with animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextSwitcher(text: '1 item'),
          ),
        ),
      );

      expect(find.text('1 item'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextSwitcher(text: '2 items'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.pumpAndSettle();

      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('AppFadeSlide mounts and animates smoothly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFadeSlide(
              child: Text('Animated Content'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 160));
      expect(find.text('Animated Content'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Animated Content'), findsOneWidget);
    });

    testWidgets('CompactProductCard renders with AppBounce and heroTag', (tester) async {
      final product = Product(
        id: 'prod-anim',
        name: 'Animated Veterinary Tonic',
        slug: 'anim-tonic',
        price: 350,
        mrp: 450,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 180,
                height: 260,
                child: CompactProductCard(
                  product: product,
                  heroTag: 'hero_prod_anim',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Animated Veterinary Tonic'), findsOneWidget);
      expect(find.byType(AppBounce), findsWidgets);
      expect(find.byType(Hero), findsOneWidget);
    });
  });
}
