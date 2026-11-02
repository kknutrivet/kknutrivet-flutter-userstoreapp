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

  String? lastSentPhone;
  String? lastName;
  String? lastVerifiedPhone;
  String? lastVerifiedCode;
  String? lastReferralCode;

  @override
  Future<void> sendOtp(String phone, [String? name]) async {
    lastSentPhone = phone;
    lastName = name;
  }

  @override
  Future<AppUser> verifyOtp(
    String phone,
    String code, {
    String? name,
    String? referralCode,
  }) async {
    lastVerifiedPhone = phone;
    lastVerifiedCode = code;
    lastName = name;
    lastReferralCode = referralCode;

    return AppUser(
      id: 'phone-user-456',
      email: '9876543210@kknutrivet.in',
      phone: phone,
      name: name ?? 'OTP User',
      authProvider: 'phone',
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

  group('Mobile Number & OTP Authentication Tests', () {
    test('sendOtp and verifyOtp flow passes phone, code, name, and referral to backend', () async {
      final fakeAuth = _FakeAuthService();
      final fakeCart = _FakeCartService();

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(fakeAuth),
          cartServiceProvider.overrideWithValue(fakeCart),
        ],
      );
      addTearDown(container.dispose);

      // Add item as guest before signing in
      await container.read(cartProvider.notifier).addItem(
            productId: 'sample-p2',
            quantity: 1,
            product: Product(id: 'sample-p2', slug: 'sample-vitamin', name: 'Sample Vitamin', price: 350),
          );

      expect(container.read(cartCountProvider), 1);

      // Step 1: Send OTP
      await container.read(authServiceProvider).sendOtp('9876543210', 'Rahul Sharma');
      expect(fakeAuth.lastSentPhone, '9876543210');
      expect(fakeAuth.lastName, 'Rahul Sharma');

      // Step 2: Verify OTP via AuthNotifier
      await container.read(authProvider.notifier).verifyOtp(
            '9876543210',
            '123456',
            name: 'Rahul Sharma',
            referralCode: 'KKFRIEND',
          );

      expect(fakeAuth.lastVerifiedPhone, '9876543210');
      expect(fakeAuth.lastVerifiedCode, '123456');
      expect(fakeAuth.lastReferralCode, 'KKFRIEND');

      // Check user state
      final user = container.read(authProvider).value;
      expect(user, isNotNull);
      expect(user?.phone, '9876543210');
      expect(user?.name, 'Rahul Sharma');
      expect(user?.authProvider, 'phone');

      // Ensure guest cart was merged seamlessly
      final cartItems = await container.read(cartProvider.future);
      expect(cartItems, isNotNull);
      expect(fakeCart.lastMergedItems.length, 1);
      expect(fakeCart.lastMergedItems.first['productId'], 'sample-p2');
    });
  });
}
