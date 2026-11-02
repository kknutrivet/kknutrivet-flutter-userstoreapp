import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/providers/auth_service.dart';
import 'package:nvit_app/providers/cart_service.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(ApiClient.instance);

  @override
  Future<AppUser> loginWithFirebaseGoogle(String idToken, {String? referralCode}) async {
    return AppUser(
      id: 'google-user-123',
      email: 'user@gmail.com',
      name: 'Google User',
      authProvider: 'google',
    );
  }

  @override
  Future<AppUser> login(String email, String password) async {
    return AppUser(
      id: 'email-user-123',
      email: email,
      name: 'Email User',
      authProvider: 'email',
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakeCartService extends CartService {
  _FakeCartService() : super(ApiClient.instance);

  final List<CartItem> _serverItems = [];
  List<Map<String, dynamic>> lastMergedItems = [];

  @override
  Future<List<CartItem>> fetchCart() async => List.of(_serverItems);

  @override
  Future<void> mergeGuestCart(List<Map<String, dynamic>> items) async {
    lastMergedItems = List.of(items);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  group('Auth & Cart Circular Dependency Regression Tests', () {
    test('reading cartProvider while authProvider is loading/changing does not trigger CircularDependencyError', () async {
      final fakeAuth = _FakeAuthService();
      final fakeCart = _FakeCartService();

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(fakeAuth),
          cartServiceProvider.overrideWithValue(fakeCart),
        ],
      );
      addTearDown(container.dispose);

      // Add item as guest first
      await container.read(cartProvider.notifier).addItem(
            productId: 'sample-p1',
            quantity: 2,
            product: Product(id: 'sample-p1', slug: 'sample-dog-food', name: 'Sample Dog Food', price: 500),
          );

      expect(container.read(cartCountProvider), 2);

      // Verify authProvider is currently null (guest)
      final initialUser = await container.read(authProvider.future);
      expect(initialUser, isNull);

      // Trigger login - this previously triggered CircularDependencyError
      // because authProvider was reading cartProvider while cartProvider was reading authProvider.
      await container.read(authProvider.notifier).login('user@gmail.com', 'password');

      final loggedInUser = container.read(authProvider).value;
      expect(loggedInUser, isNotNull);
      expect(loggedInUser?.email, 'user@gmail.com');

      // Ensure cartProvider cleanly merged without throwing CircularDependencyError
      final cartItems = await container.read(cartProvider.future);
      expect(cartItems, isNotNull);
      expect(fakeCart.lastMergedItems.length, 1);
      expect(fakeCart.lastMergedItems.first['productId'], 'sample-p1');

      // Logout and ensure no circular exception
      await container.read(authProvider.notifier).logout();
      expect(container.read(authProvider).value, isNull);
    });

    test('loginWithFirebaseGoogle through AuthService completes without Riverpod cycle', () async {
      final fakeAuth = _FakeAuthService();
      final fakeCart = _FakeCartService();

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(fakeAuth),
          cartServiceProvider.overrideWithValue(fakeCart),
        ],
      );
      addTearDown(container.dispose);

      // Read cart first to mount CartNotifier
      await container.read(cartProvider.future);

      // Call loginWithFirebaseGoogle
      final user = await container
          .read(authServiceProvider)
          .loginWithFirebaseGoogle('mock-id-token');

      expect(user.email, 'user@gmail.com');
      expect(user.authProvider, 'google');
    });
  });
}
