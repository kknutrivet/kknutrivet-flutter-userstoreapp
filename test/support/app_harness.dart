/// Test harness that boots the real app router, providers and theme against
/// the [FakeApiClient]. Every automation layer (widget journeys, route
/// coverage, golden screens) should start here so behaviour stays consistent.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nvit_app/core/router/app_router.dart';
import 'package:nvit_app/core/services/app_update_service.dart';
import 'package:nvit_app/core/theme/app_theme.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';

import 'fake_api_client.dart';
import 'fixtures.dart';

/// Call once per test file before declaring tests.
void configureTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

bool _appFontsLoaded = false;

/// Loads the real brand fonts so widget tests layout text with production
/// metrics instead of the wide, tall Ahem test font. Without this, app-level
/// screens report false RenderFlex overflows.
Future<void> loadAppFonts() async {
  if (_appFontsLoaded) return;
  final lora = FontLoader('Lora')
    ..addFont(rootBundle.load('assets/fonts/Lora-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Lora-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Lora-Bold.ttf'));
  final jakarta = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-ExtraBold.ttf'));

  // Widget tests do not register the Material icon font automatically, so
  // icons render as empty boxes unless it is loaded from the test assets.
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));

  await Future.wait([
    lora.load(),
    jakarta.load(),
    materialIcons.load(),
  ]);
  _appFontsLoaded = true;
}

/// Pump helper that is safe with continuous animations (shimmer, lottie).
/// Prefer this over `pumpAndSettle`, which can time out on looping widgets.
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(this._initialUser);

  final AppUser? _initialUser;
  AppUser? currentUser;
  int loginCount = 0;
  int logoutCount = 0;

  @override
  Future<AppUser?> build() async {
    currentUser = _initialUser;
    return _initialUser;
  }

  @override
  Future<void> login(String email, String password) async {
    loginCount++;
    currentUser = AppUser.fromJson(userJson(email: email));
    state = AsyncData(currentUser);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? referralCode,
  }) async {
    currentUser = AppUser.fromJson(
      userJson(email: email, name: name, phone: phone),
    );
    state = AsyncData(currentUser);
  }

  @override
  Future<void> verifyOtp(
    String phone,
    String code, {
    String? name,
    String? referralCode,
  }) async {
    currentUser = AppUser.fromJson(userJson(phone: phone, name: name));
    state = AsyncData(currentUser);
  }

  @override
  Future<void> continueAsGuest() async {
    currentUser = AppUser.fromJson(
      userJson(id: 'guest-1', name: 'Guest', isAnonymous: true, loyaltyPoints: 0),
    );
    state = AsyncData(currentUser);
  }

  @override
  Future<void> logout() async {
    logoutCount++;
    currentUser = null;
    state = const AsyncData(null);
  }
}

class MockOnboardingNotifier extends OnboardingNotifier {
  MockOnboardingNotifier(this.completed);

  bool completed;

  @override
  Future<bool> build() async => completed;

  @override
  Future<void> complete() async {
    completed = true;
    state = const AsyncData(true);
  }
}

class TestApp {
  TestApp({
    required this.tester,
    required this.container,
    required this.router,
    required this.api,
    required this.auth,
    required this.onboarding,
  });

  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final FakeApiClient api;
  final MockAuthNotifier auth;
  final MockOnboardingNotifier onboarding;

  String get location => router.state.matchedLocation;

  Future<void> go(String location) async {
    router.go(location);
    await settle(tester);
  }
}

/// Boots the production widget tree (router + theme + providers) with fakes.
///
/// [route] is where the app should land. Pass `/splash` to let the splash
/// screen perform its real cold-start resolution.
Future<TestApp> pumpTestApp(
  WidgetTester tester, {
  AppUser? user,
  bool onboardingComplete = true,
  FakeApiClient? api,
  List<Override> overrides = const [],
  String route = '/home',
  Size size = const Size(390, 844),
  double devicePixelRatio = 1.0,
}) async {
  await loadAppFonts();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = Size(
    size.width * devicePixelRatio,
    size.height * devicePixelRatio,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final client = api ?? FakeApiClient();
  final auth = MockAuthNotifier(user);
  final onboarding = MockOnboardingNotifier(onboardingComplete);

  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      authProvider.overrideWith(() => auth),
      onboardingProvider.overrideWith(() => onboarding),
      storeSettingsProvider.overrideWith((ref) async => StoreSettings.defaults()),
      appUpdateCheckProvider.overrideWith(
        (ref) async => AppUpdateCheckResult(
          status: AppUpdateStatus.upToDate,
          config: const AppUpdateConfig(),
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
        ),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        title: 'KK Nutrivet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );

  await tester.pump();
  if (route != '/splash') {
    router.go(route);
    await settle(tester);
  }

  return TestApp(
    tester: tester,
    container: container,
    router: router,
    api: client,
    auth: auth,
    onboarding: onboarding,
  );
}

AppUser testUser({String? name, String? email}) =>
    AppUser.fromJson(userJson(name: name ?? 'Asha Panda', email: email ?? 'pet.parent@example.com'));
