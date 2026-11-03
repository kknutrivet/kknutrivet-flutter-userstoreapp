import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/storage/token_storage.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/providers/cart_service.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(this._user);
  final AppUser? _user;

  @override
  Future<AppUser?> build() async => _user;

  @override
  Future<void> logout() async {
    state = const AsyncData(null);
  }
}

class Throwing401CartService extends CartService {
  Throwing401CartService() : super(ApiClient.instance);

  @override
  Future<List<CartItem>> fetchCart() async {
    throw ApiException('Unauthorized', statusCode: 401);
  }

  @override
  Future<void> addItem({
    required String productId,
    String? variantId,
    int quantity = 1,
  }) async {
    throw ApiException('Unauthorized', statusCode: 401);
  }

  @override
  Future<void> mergeGuestCart(List<Map<String, dynamic>> items) async {
    throw ApiException('Unauthorized', statusCode: 401);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final testProduct = Product(
    id: 'prod-cart-1',
    name: 'Royal Canin Maxi Adult',
    slug: 'royal-canin-maxi-adult',
    price: 999.0,
    mrp: 1299.0,
  );

  group('CartNotifier Guest Cart Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });
      await TokenStorage.instance.clearToken();
    });

    test('guest can add item to cart without throwing unhandled exception', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify initially empty
      final initialCart = await container.read(cartProvider.future);
      expect(initialCart, isEmpty);
      expect(container.read(cartCountProvider), 0);

      // Add item as guest
      await container.read(cartProvider.notifier).addItem(
        productId: testProduct.id,
        quantity: 1,
        product: testProduct,
      );

      final updatedCart = container.read(cartProvider).value;
      expect(updatedCart, isNotNull);
      expect(updatedCart!.length, 1);
      expect(updatedCart.first.productId, testProduct.id);
      expect(updatedCart.first.quantity, 1);
      expect(container.read(cartCountProvider), 1);

      // Increment quantity
      await container.read(cartProvider.notifier).setQuantity(
        productId: testProduct.id,
        quantity: 2,
      );

      final incrementedCart = container.read(cartProvider).value;
      expect(incrementedCart!.first.quantity, 2);
      expect(container.read(cartCountProvider), 2);

      // Decrement to 0 (remove)
      await container.read(cartProvider.notifier).setQuantity(
        productId: testProduct.id,
        quantity: 0,
      );

      final emptyCart = container.read(cartProvider).value;
      expect(emptyCart, isEmpty);
      expect(container.read(cartCountProvider), 0);
    });

    test('guest can add and update combo in cart', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(cartProvider.notifier).addCombo(
        'combo-1',
        comboName: 'Puppy Starter Kit',
        comboPrice: 1499.0,
      );

      final cart = container.read(cartProvider).value;
      expect(cart, isNotNull);
      expect(cart!.length, 1);
      expect(cart.first.comboId, 'combo-1');
      expect(cart.first.comboName, 'Puppy Starter Kit');
      expect(cart.first.comboPrice, 1499.0);
      expect(cart.first.quantity, 1);

      await container.read(cartProvider.notifier).setComboQuantity('combo-1', 2);
      final updatedCart = container.read(cartProvider).value;
      expect(updatedCart!.first.quantity, 2);

      await container.read(cartProvider.notifier).setComboQuantity('combo-1', 0);
      expect(container.read(cartProvider).value, isEmpty);
    });

    test('recovers from 401 by clearing session and saving item to guest cart', () async {
      final mockAuth = MockAuthNotifier(AppUser(id: 'u1', email: 'test@test.com'));
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => mockAuth),
          cartServiceProvider.overrideWithValue(Throwing401CartService()),
        ],
      );
      addTearDown(container.dispose);

      // Initialize auth so state is ready
      await container.read(authProvider.future);
      expect(container.read(authProvider).value, isNotNull);

      // Add item while authenticated with stale token
      await container.read(cartProvider.notifier).addItem(
        productId: testProduct.id,
        quantity: 1,
        product: testProduct,
      );

      // Flush microtask for logout
      await Future<void>.delayed(Duration.zero);

      // Verify that auth was cleared (logged out)
      expect(container.read(authProvider).value, isNull);

      // Verify that item was saved to guest cart anyway!
      final cart = container.read(cartProvider).value;
      expect(cart, isNotNull);
      expect(cart!.length, 1);
      expect(cart.first.productId, testProduct.id);
      expect(cart.first.quantity, 1);
      expect(container.read(cartCountProvider), 1);
    });

    test('persists cart items across app restarts (SharedPreferences)', () async {
      final firstSession = ProviderContainer();
      await firstSession.read(cartProvider.future);
      await firstSession.read(cartProvider.notifier).addItem(
        productId: testProduct.id,
        quantity: 3,
        product: testProduct,
      );
      // Let unawaited SharedPreferences write complete
      await Future<void>.delayed(const Duration(milliseconds: 20));
      firstSession.dispose();

      // Simulate app restart with a brand new ProviderContainer
      final secondSession = ProviderContainer();
      addTearDown(secondSession.dispose);

      final restoredCart = await secondSession.read(cartProvider.future);
      expect(restoredCart.length, 1);
      expect(restoredCart.first.productId, testProduct.id);
      expect(restoredCart.first.quantity, 3);
      expect(restoredCart.first.product?.name, testProduct.name);
      expect(secondSession.read(cartCountProvider), 3);
    });
  });
}
