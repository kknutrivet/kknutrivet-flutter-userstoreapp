import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/widgets/home_hero_carousel.dart';
import 'package:nvit_app/features/home/widgets/home_models_and_data.dart';

Widget _wrapHeroCarousel({Widget? child}) {
  return ProviderScope(
    overrides: [
      homepageSectionsProvider.overrideWith((ref) => Future.value(const [])),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: child ?? const HomeHeroCarousel(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('HomeHeroCarousel UX & Native Feel Tests', () {
    testWidgets(
      'renders PageView with native peeking viewportFraction 0.92',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapHeroCarousel());
        await tester.pump();

        final pageViewFinder = find.byType(PageView);
        expect(pageViewFinder, findsOneWidget);

        final pageView = tester.widget<PageView>(pageViewFinder);
        expect(pageView.controller?.viewportFraction, 0.92);
        expect(pageView.physics, isA<BouncingScrollPhysics>());
      },
    );

    testWidgets(
      'renders 3 indicator dots with first dot active (width 20)',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrapHeroCarousel());
        await tester.pump();

        // Find the 3 semantics labels for indicator pills
        expect(find.bySemanticsLabel('Slide 1 of 3'), findsOneWidget);
        expect(find.bySemanticsLabel('Slide 2 of 3'), findsOneWidget);
        expect(find.bySemanticsLabel('Slide 3 of 3'), findsOneWidget);

        // Verify active container width is 20, while inactive are 6
        final containers = tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .toList();
        final indicatorContainers = containers.where((c) {
          final box = c.decoration as BoxDecoration?;
          return box?.borderRadius == BorderRadius.circular(3);
        }).toList();

        expect(indicatorContainers.length, 3);
        expect(indicatorContainers[0].constraints?.maxWidth, 20.0);
        expect(indicatorContainers[1].constraints?.maxWidth, 6.0);
        expect(indicatorContainers[2].constraints?.maxWidth, 6.0);
      },
    );

    testWidgets('tapping indicator advances page', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapHeroCarousel());
      await tester.pump();

      // Tap slide 2 indicator
      await tester.tap(find.bySemanticsLabel('Slide 2 of 3'));
      await tester.pumpAndSettle();

      // Verify slide 2 is now active
      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      final indicatorContainers = containers.where((c) {
        final box = c.decoration as BoxDecoration?;
        return box?.borderRadius == BorderRadius.circular(3);
      }).toList();

      expect(indicatorContainers[0].constraints?.maxWidth, 6.0);
      expect(indicatorContainers[1].constraints?.maxWidth, 20.0);
    });

    for (final width in [320.0, 360.0, 390.0, 412.0, 768.0]) {
      testWidgets(
        'renders without overflow at ${width}px screen width',
        (tester) async {
          tester.view.physicalSize = Size(width * 3, 800 * 3);
          tester.view.devicePixelRatio = 3.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          FlutterErrorDetails? caughtDetails;
          final originalOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            caughtDetails = details;
          };

          await tester.pumpWidget(
            _wrapHeroCarousel(
              child: const SingleChildScrollView(
                child: HomeHeroCarousel(),
              ),
            ),
          );
          await tester.pump();

          FlutterError.onError = originalOnError;
          expect(
            caughtDetails,
            isNull,
            reason: 'Failed overflow check at ${width}px',
          );
        },
      );
    }
  });
}
