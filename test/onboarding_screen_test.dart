import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('OnboardingScreen Widget & Flow Tests', () {
    testWidgets(
      'renders first slide with brand header, progress, and highlights',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingProvider.overrideWith(() => _MockOnboardingNotifier()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // Brand Identity & Header
        expect(find.byType(Image), findsWidgets);
        expect(find.text('Skip'), findsOneWidget);

        // Slide 1 Content
        expect(find.text('Authentic Veterinary Care'), findsOneWidget);
        expect(find.text('SHOP WITH CONFIDENCE'), findsOneWidget);
        expect(find.text('Step 1 of 4'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);

        // Check highlights
      },
    );

    testWidgets(
      'can step through slides and shows back button and final finish CTA',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockNotifier = _MockOnboardingNotifier();
        final router = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [onboardingProvider.overrideWith(() => mockNotifier)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // Step to Slide 2
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Consult Certified Vets'), findsOneWidget);
        expect(find.text('Step 2 of 4'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Advance real wall-clock past AppButton 500ms debounce
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 550)),
        );
        await tester.pump();

        // Step to Slide 3
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Prescription Concierge'), findsOneWidget);
        expect(find.text('Step 3 of 4'), findsOneWidget);

        // Advance real wall-clock past AppButton 500ms debounce
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 550)),
        );
        await tester.pump();

        // Step to Slide 4
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Smart Pet Care & Reminders'), findsOneWidget);
        expect(find.text('Step 4 of 4'), findsOneWidget);
        expect(find.text('Explore KK Nutrivet'), findsOneWidget);

        // Advance real wall-clock past AppButton 500ms debounce
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 550)),
        );
        await tester.pump();

        // Finish Onboarding
        await tester.tap(find.text('Explore KK Nutrivet'));
        await tester.pumpAndSettle();

        expect(mockNotifier.completed, isTrue);
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Skip to Store marks tutorial as complete and navigates home',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockNotifier = _MockOnboardingNotifier();
        final router = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (context, state) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [onboardingProvider.overrideWith(() => mockNotifier)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(mockNotifier.completed, isTrue);
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );
  });
}

class _MockOnboardingNotifier extends OnboardingNotifier {
  bool completed = false;

  @override
  Future<bool> build() async => false;

  @override
  Future<void> complete() async {
    completed = true;
    state = const AsyncValue.data(true);
  }
}
