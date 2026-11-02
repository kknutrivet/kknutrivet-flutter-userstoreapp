import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/router/app_router.dart';
import 'package:nvit_app/features/auth/screens/login_screen.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/providers/auth_service.dart';
import 'package:nvit_app/providers/cart_service.dart';

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

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(ApiClient.instance);

  @override
  Future<AppUser> login(String email, String password) async {
    return AppUser(
      id: 'test-user',
      email: email,
      name: 'Test User',
      authProvider: 'email',
    );
  }

  @override
  Future<AppUser> verifyOtp(String phone, String code, {String? name, String? referralCode}) async {
    return AppUser(
      id: 'test-user',
      email: 'test@kknutrivet.in',
      phone: phone,
      name: name ?? 'Test User',
      authProvider: 'phone',
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakeCartService extends CartService {
  _FakeCartService() : super(ApiClient.instance);

  @override
  Future<List<CartItem>> fetchCart() async => const [];

  @override
  Future<void> mergeGuestCart(List<Map<String, dynamic>> items) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  });

  testWidgets('When user logs in, login screen dismisses from /login to /home or previous route', (tester) async {
    final fakeAuth = _FakeAuthService();
    final fakeCart = _FakeCartService();
    final fakeApi = _FakeApiClient();

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApi),
        authServiceProvider.overrideWithValue(fakeAuth),
        cartServiceProvider.overrideWithValue(fakeCart),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 800));

    // Push /login
    router.push('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(router.state.matchedLocation, '/login');

    // Trigger verifyOtp via notifier
    await container.read(authProvider.notifier).verifyOtp('9876543210', '123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify LoginScreen has dismissed and route is /home
    expect(router.state.matchedLocation, '/home');
    expect(find.byType(LoginScreen), findsNothing);
  });
}
