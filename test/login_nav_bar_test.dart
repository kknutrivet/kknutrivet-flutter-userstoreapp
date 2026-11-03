import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/router/app_router.dart';
import 'package:nvit_app/features/auth/screens/login_screen.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';

class _FakeApiClient implements ApiClient {
  @override
  void updateBaseUrl(String newBaseUrl) {}

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => [];

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> upload(String path, String filePath,
      {String fileField = 'file', Map<String, dynamic>? fields}) async =>
      {};
}

class _MockOnboardingNotifier extends OnboardingNotifier {
  _MockOnboardingNotifier(this._val);
  final bool _val;
  @override
  Future<bool> build() async => _val;
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<AppUser?> build() async => null;

  void emitUser(AppUser user) {
    state = AsyncData(user);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('bottom nav is not visible or clickable when login dialog is open', (tester) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(_FakeApiClient()),
        onboardingProvider.overrideWith(() => _MockOnboardingNotifier(true)),
        authProvider.overrideWith(() => _MockAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go('/home');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify on home screen with bottom nav
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    // Tap 'Sign in' / Account icon in MainShell's bottom nav
    await tester.tap(find.text('Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify LoginScreen is open
    expect(find.byType(LoginScreen), findsOneWidget);

    // Verify LoginScreen does NOT render WebsiteBottomNav
    expect(
      find.descendant(of: find.byType(LoginScreen), matching: find.byType(WebsiteBottomNav)),
      findsNothing,
    );

    // Verify modal backdrop dismisses the dialog when tapped outside
    // Tap top-left area outside dialog card (offset 20, 20)
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // After dismiss, we are back on home screen and bottom nav is visible again
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
  });

  testWidgets('login dialog dismisses automatically when auth state becomes signed in', (tester) async {
    final mockAuth = _MockAuthNotifier();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(_FakeApiClient()),
        onboardingProvider.overrideWith(() => _MockOnboardingNotifier(true)),
        authProvider.overrideWith(() => mockAuth),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go('/home');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Open LoginScreen
    await tester.tap(find.text('Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoginScreen), findsOneWidget);

    // Simulate login completion (e.g. Google Sign-In)
    mockAuth.emitUser(
      AppUser(id: '123', email: 'test@kknutrivet.in', name: 'Saroj', isAnonymous: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // LoginScreen MUST be dismissed and user directed to /profile
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('login dialog dismisses and returns to current screen when no pending redirect exists', (tester) async {
    final mockAuth = _MockAuthNotifier();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(_FakeApiClient()),
        onboardingProvider.overrideWith(() => _MockOnboardingNotifier(true)),
        authProvider.overrideWith(() => mockAuth),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    router.go('/home');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Open LoginScreen without setting pending redirect (e.g. from a modal or action)
    router.push('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoginScreen), findsOneWidget);

    // Simulate login completion
    mockAuth.emitUser(
      AppUser(id: '123', email: 'test@kknutrivet.in', name: 'Saroj', isAnonymous: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // LoginScreen MUST be dismissed and user remains on /home
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
  });
}
