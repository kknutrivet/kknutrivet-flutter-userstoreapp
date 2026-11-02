import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics_service.dart';
import '../core/auth/firebase_auth_service.dart';
import '../core/network/api_client.dart';
import '../core/storage/delivery_pincode_storage.dart';
import '../core/storage/guest_cart_storage.dart';
import '../core/storage/onboarding_storage.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/wishlist_storage.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/delivery.dart';
import '../models/product.dart';
import '../models/store_settings.dart';
import '../models/user.dart';
import 'address_service.dart';
import 'ai_service.dart';
import 'auth_service.dart';
import 'cart_service.dart';
import 'catalog_service.dart';
import 'consultation_service.dart';
import 'content_service.dart';
import 'delivery_service.dart';
import 'notification_service.dart';
import 'order_service.dart';
import 'pet_service.dart';
import 'prescription_service.dart';
import 'referral_service.dart';
import 'settings_service.dart';
import 'upload_service.dart';

final apiClientProvider = Provider((ref) => ApiClient.instance);

final authServiceProvider = Provider((ref) => AuthService(ref.watch(apiClientProvider)));
final catalogServiceProvider = Provider((ref) => CatalogService(ref.watch(apiClientProvider)));
final cartServiceProvider = Provider((ref) => CartService(ref.watch(apiClientProvider)));
final addressServiceProvider = Provider((ref) => AddressService(ref.watch(apiClientProvider)));
final orderServiceProvider = Provider((ref) => OrderService(ref.watch(apiClientProvider)));
final petServiceProvider = Provider((ref) => PetService(ref.watch(apiClientProvider)));
final consultationServiceProvider =
    Provider((ref) => ConsultationService(ref.watch(apiClientProvider)));
final prescriptionServiceProvider =
    Provider((ref) => PrescriptionService(ref.watch(apiClientProvider)));
final contentServiceProvider = Provider((ref) => ContentService(ref.watch(apiClientProvider)));
final deliveryServiceProvider = Provider((ref) => DeliveryService(ref.watch(apiClientProvider)));
final aiServiceProvider = Provider((ref) => AiService(ref.watch(apiClientProvider)));
final referralServiceProvider = Provider((ref) => ReferralService(ref.watch(apiClientProvider)));
final uploadServiceProvider = Provider((ref) => UploadService(ref.watch(apiClientProvider)));
final settingsServiceProvider = Provider((ref) => SettingsService(ref.watch(apiClientProvider)));
final notificationServiceProvider =
    Provider((ref) => NotificationService(ref.watch(apiClientProvider)));

final storeSettingsProvider = FutureProvider<StoreSettings>((ref) {
  return ref.read(settingsServiceProvider).fetchSettings();
});

/// Fetches active categories from `/api/categories`.
final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) {
  return ref.read(catalogServiceProvider).fetchCategories();
});

/// Returns active category names, dynamically driven by the database `Category` table (`active: true`)
/// and respecting `storeSettings.hiddenCategories`. Falls back to canonical categories if offline.
final activeCategoriesProvider = Provider<List<String>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  final hidden =
      ref.watch(storeSettingsProvider).valueOrNull?.hiddenCategories ?? const [];

  const canonicalCategories = [
    'Medicine',
    'Supplement & Nutrition',
    'Spray',
    'Device',
    'Grooming',
    'Feed',
    'Deworming',
    'Home Care',
  ];

  final backendCategories = categoriesAsync.valueOrNull;
  final baseList = (backendCategories != null && backendCategories.isNotEmpty)
      ? backendCategories
          .where((c) => c.active && !c.isSubcategory)
          .map((c) => c.name)
          .toList()
      : canonicalCategories;

  return baseList.where((cat) => !hidden.contains(cat)).toList();
});

/// Auth state: null = signed out, AppUser = signed in.
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final token = await TokenStorage.instance.readToken();
    if (token == null) return null;
    try {
      return await ref.read(authServiceProvider).fetchProfile();
    } catch (_) {
      await TokenStorage.instance.clearToken();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).login(email, password),
    );
    if (state.value != null) {
      AnalyticsService.instance.logLogin(method: 'password');
    }
    if (state.hasError) throw state.error!;
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).register(
          email: email,
          password: password,
          name: name,
          phone: phone,
          referralCode: referralCode,
        ));
    if (state.value != null) {
      AnalyticsService.instance.logSignUp(method: 'password');
    }
    if (state.hasError) throw state.error!;
  }

  Future<void> verifyOtp(
    String phone,
    String code, {
    String? name,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).verifyOtp(
            phone,
            code,
            name: name,
            referralCode: referralCode,
          ),
    );
    if (state.value != null) {
      AnalyticsService.instance.logLogin(method: 'otp');
    }
    if (state.hasError) throw state.error!;
  }

  Future<void> continueAsGuest() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).continueAsGuest());
    if (state.hasError) throw state.error!;
  }

  /// Google sign-in via the shared Firebase project, then the website's
  /// POST /api/auth/firebase. Falls back to nothing — without Firebase
  /// config there is no Google path, same as the website without keys.
  Future<void> signInWithGoogle({String? referralCode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final idToken =
          await FirebaseAuthService.instance.signInWithGoogle();
      if (idToken == null) {
        return null;
      }
      return ref
          .read(authServiceProvider)
          .loginWithFirebaseGoogle(idToken, referralCode: referralCode);
    });
    if (state.value != null) {
      AnalyticsService.instance.logLogin(method: 'google');
    }
    if (state.hasError) throw state.error!;
  }

  /// Phone-OTP ID token from Firebase → POST /api/auth/firebase-phone.
  Future<void> signInWithFirebasePhone(
    String idToken, {
    String? name,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).loginWithFirebasePhone(
            idToken,
            name: name,
            referralCode: referralCode,
          ),
    );
    if (state.value != null) {
      AnalyticsService.instance.logLogin(method: 'phone_otp');
    }
    if (state.hasError) throw state.error!;
  }

  /// Guest via Firebase anonymous auth (the website's guest path), with a
  /// fallback to the legacy server guest when Firebase isn't configured.
  Future<void> continueAsFirebaseGuest() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final idToken =
            await FirebaseAuthService.instance.signInAnonymously();
        return await ref
            .read(authServiceProvider)
            .continueAsFirebaseGuest(idToken);
      } on FirebaseNotConfiguredException {
        return ref.read(authServiceProvider).continueAsGuest();
      }
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> logout() async {
    await FirebaseAuthService.instance.signOut();
    await ref.read(authServiceProvider).logout();
    AnalyticsService.instance.logLogout();
    state = const AsyncData(null);
  }

  Future<void> refreshProfile() async {
    if (state.value == null) return;
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).fetchProfile());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

/// Where to return after sign-in. Mirrors the website's
/// `sessionStorage:auth_redirect` (set when a protected action forces
/// login, e.g. checkout): the router stores the intercepted location here,
/// the login screen consumes it once on success, defaulting to `/home`.
final pendingAuthRedirectProvider = StateProvider<String?>((ref) => null);

/// Whether the first-run tutorial has been shown before. Drives the splash
/// screen's decision to route new installs through /onboarding.
class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => OnboardingStorage.instance.hasCompletedOnboarding();

  Future<void> complete() async {
    await OnboardingStorage.instance.markCompleted();
    state = const AsyncData(true);
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

/// Cart state: refetched from server for signed-in users, managed locally
/// for guests (persisted in SharedPreferences via `GuestCartStorage`, and
/// merged on login via `_mergeGuestCart`).
class CartNotifier extends AsyncNotifier<List<CartItem>> {
  final List<CartItem> _guestCart = [];
  bool _hydratedFromStorage = false;

  void _persistGuestCart() {
    unawaited(GuestCartStorage.instance.saveAll(List<CartItem>.of(_guestCart)));
  }

  void clearGuestCart() {
    _guestCart.clear();
    unawaited(GuestCartStorage.instance.clear());
  }

  void _addToGuestCart({
    required String productId,
    String? variantId,
    int quantity = 1,
    Product? product,
    ProductVariant? variant,
  }) {
    final existingIndex = _guestCart.indexWhere(
      (i) => i.productId == productId && i.variantId == variantId,
    );
    if (existingIndex >= 0) {
      final existing = _guestCart[existingIndex];
      _guestCart[existingIndex] = CartItem(
        id: existing.id,
        productId: productId,
        variantId: variantId,
        quantity: existing.quantity + quantity,
        product: product ?? existing.product,
        variant: variant ?? existing.variant,
      );
    } else {
      _guestCart.add(CartItem(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}_$productId',
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        product: product,
        variant: variant,
      ));
    }
    _persistGuestCart();
  }

  void _setGuestQuantity({
    required String productId,
    String? variantId,
    required int quantity,
  }) {
    final existingIndex = _guestCart.indexWhere(
      (i) => i.productId == productId && i.variantId == variantId,
    );
    if (existingIndex >= 0) {
      if (quantity <= 0) {
        _guestCart.removeAt(existingIndex);
      } else {
        final existing = _guestCart[existingIndex];
        _guestCart[existingIndex] = CartItem(
          id: existing.id,
          productId: productId,
          variantId: variantId,
          quantity: quantity,
          product: existing.product,
          variant: existing.variant,
        );
      }
      _persistGuestCart();
    }
  }

  void _addGuestCombo(
    String comboId, {
    String? comboName,
    double? comboPrice,
    String? comboImage,
  }) {
    final existingIndex = _guestCart.indexWhere((i) => i.comboId == comboId);
    if (existingIndex >= 0) {
      final existing = _guestCart[existingIndex];
      _guestCart[existingIndex] = CartItem(
        id: existing.id,
        productId: existing.productId,
        comboId: comboId,
        quantity: existing.quantity + 1,
        comboQuantity: (existing.comboQuantity ?? 1) + 1,
        comboName: comboName ?? existing.comboName,
        comboPrice: comboPrice ?? existing.comboPrice,
        comboImage: comboImage ?? existing.comboImage,
      );
    } else {
      _guestCart.add(CartItem(
        id: 'guest_combo_${DateTime.now().millisecondsSinceEpoch}_$comboId',
        productId: comboId,
        comboId: comboId,
        quantity: 1,
        comboQuantity: 1,
        comboName: comboName,
        comboPrice: comboPrice,
        comboImage: comboImage,
      ));
    }
    _persistGuestCart();
  }

  void _setGuestComboQuantity(String comboId, int quantity) {
    final existingIndex = _guestCart.indexWhere((i) => i.comboId == comboId);
    if (existingIndex >= 0) {
      if (quantity <= 0) {
        _guestCart.removeAt(existingIndex);
      } else {
        final existing = _guestCart[existingIndex];
        _guestCart[existingIndex] = CartItem(
          id: existing.id,
          productId: existing.productId,
          comboId: comboId,
          quantity: quantity,
          comboQuantity: quantity,
          comboName: existing.comboName,
          comboPrice: existing.comboPrice,
          comboImage: existing.comboImage,
        );
      }
      _persistGuestCart();
    }
  }

  @override
  Future<List<CartItem>> build() async {
    if (!_hydratedFromStorage) {
      _hydratedFromStorage = true;
      final persisted = await GuestCartStorage.instance.readAll();
      if (_guestCart.isEmpty && persisted.isNotEmpty) {
        _guestCart.addAll(persisted);
      }
    }

    // Watch authProvider so CartNotifier automatically updates on login/logout
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return List.unmodifiable(_guestCart);

    // If items were added while browsing as guest, merge them into the user's account
    if (_guestCart.isNotEmpty) {
      final guestSnapshot = _guestCart
          .map((item) => {
                'productId': item.productId,
                'variantId': ?item.variantId,
                'quantity': item.quantity,
                'comboId': ?item.comboId,
                'comboPrice': ?item.comboPrice,
              })
          .toList();
      try {
        await ref.read(cartServiceProvider).mergeGuestCart(guestSnapshot);
        clearGuestCart();
      } catch (_) {
        // Merge is best-effort: failure here should not block loading account cart
      }
    }

    try {
      final items = await ref.read(cartServiceProvider).fetchCart();
      if (items.isEmpty && _guestCart.isNotEmpty) {
        return List.unmodifiable(_guestCart);
      }
      return items;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        return List.unmodifiable(_guestCart);
      }
      if (_guestCart.isNotEmpty) {
        return List.unmodifiable(_guestCart);
      }
      rethrow;
    } catch (_) {
      if (_guestCart.isNotEmpty) {
        return List.unmodifiable(_guestCart);
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      state = AsyncData(List.unmodifiable(_guestCart));
      return;
    }
    try {
      final items = await ref.read(cartServiceProvider).fetchCart();
      state = AsyncData(items);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        state = AsyncData(List.unmodifiable(_guestCart));
      } else if (_guestCart.isNotEmpty) {
        state = AsyncData(List.unmodifiable(_guestCart));
      } else {
        state = AsyncError(e, StackTrace.current);
      }
    } catch (e, st) {
      if (_guestCart.isNotEmpty) {
        state = AsyncData(List.unmodifiable(_guestCart));
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> addItem({
    required String productId,
    String? variantId,
    int quantity = 1,
    Product? product,
    ProductVariant? variant,
  }) async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      _addToGuestCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        product: product,
        variant: variant,
      );
      state = AsyncData(List.unmodifiable(_guestCart));
      return;
    }
    try {
      await ref.read(cartServiceProvider).addItem(
            productId: productId,
            variantId: variantId,
            quantity: quantity,
          );
      await refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _addToGuestCart(
          productId: productId,
          variantId: variantId,
          quantity: quantity,
          product: product,
          variant: variant,
        );
        state = AsyncData(List.unmodifiable(_guestCart));
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        return;
      }
      rethrow;
    }
  }

  Future<void> setQuantity({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      _setGuestQuantity(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );
      state = AsyncData(List.unmodifiable(_guestCart));
      return;
    }
    try {
      await ref.read(cartServiceProvider).setQuantity(
            productId: productId,
            variantId: variantId,
            quantity: quantity,
          );
      await refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _setGuestQuantity(
          productId: productId,
          variantId: variantId,
          quantity: quantity,
        );
        state = AsyncData(List.unmodifiable(_guestCart));
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        return;
      }
      rethrow;
    }
  }

  Future<void> addCombo(
    String comboId, {
    String? comboName,
    double? comboPrice,
    String? comboImage,
  }) async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      _addGuestCombo(
        comboId,
        comboName: comboName,
        comboPrice: comboPrice,
        comboImage: comboImage,
      );
      state = AsyncData(List.unmodifiable(_guestCart));
      return;
    }
    try {
      await ref.read(cartServiceProvider).addCombo(comboId);
      await refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _addGuestCombo(
          comboId,
          comboName: comboName,
          comboPrice: comboPrice,
          comboImage: comboImage,
        );
        state = AsyncData(List.unmodifiable(_guestCart));
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        return;
      }
      rethrow;
    }
  }

  Future<void> setComboQuantity(String comboId, int quantity) async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      _setGuestComboQuantity(comboId, quantity);
      state = AsyncData(List.unmodifiable(_guestCart));
      return;
    }
    try {
      await ref.read(cartServiceProvider).setComboQuantity(comboId, quantity);
      await refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _setGuestComboQuantity(comboId, quantity);
        state = AsyncData(List.unmodifiable(_guestCart));
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        return;
      }
      rethrow;
    }
  }

  Future<void> removeItem(String cartItemId) async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      _guestCart.removeWhere((i) => i.id == cartItemId);
      _persistGuestCart();
      state = AsyncData(List.unmodifiable(_guestCart));
      return;
    }
    try {
      await ref.read(cartServiceProvider).removeItem(cartItemId);
      await refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _guestCart.removeWhere((i) => i.id == cartItemId);
        _persistGuestCart();
        state = AsyncData(List.unmodifiable(_guestCart));
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        return;
      }
      rethrow;
    }
  }

  Future<void> clear() async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      clearGuestCart();
      state = const AsyncData([]);
      return;
    }
    try {
      await ref.read(cartServiceProvider).clearCart();
      clearGuestCart();
      await refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        clearGuestCart();
        state = const AsyncData([]);
        Future.microtask(() => ref.read(authProvider.notifier).logout());
        return;
      }
      rethrow;
    }
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

/// Counts total purchasable items in the cart (matching webapp cart-count.ts).
/// Standalone items contribute their selected quantity.
/// All rows belonging to the same combo bundle contribute the bundle quantity only once.
int getCartCount(List<CartItem> items) {
  int standaloneCount = 0;
  final comboQuantities = <String, int>{};

  for (final item in items) {
    final cid = item.comboId;
    if (cid == null || cid.isEmpty) {
      standaloneCount += item.quantity;
      continue;
    }

    final bundleQuantity =
        (item.comboQuantity != null && item.comboQuantity! > 0)
            ? item.comboQuantity!
            : 1;
    final currentMax = comboQuantities[cid] ?? 0;
    if (bundleQuantity > currentMax) {
      comboQuantities[cid] = bundleQuantity;
    }
  }

  final comboTotal = comboQuantities.values.fold(0, (sum, q) => sum + q);
  return standaloneCount + comboTotal;
}

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider).value ?? [];
  return getCartCount(cart);
});

class _ComboSubtotalGroup {
  double price = 0;
  int quantity = 0;
  int fallbackQuantity = 999999;
}

double getCartSubtotal(List<CartItem> items, [List<ComboBundle>? catalogCombos]) {
  double sum = 0;
  final combos = <String, _ComboSubtotalGroup>{};

  for (final item in items) {
    final cid = item.comboId;
    if (cid != null && cid.isNotEmpty) {
      final group = combos[cid] ??= _ComboSubtotalGroup();
      if ((item.comboPrice ?? 0) > 0) {
        group.price = group.price > 0 ? group.price : item.comboPrice!;
      }
      if ((item.comboQuantity ?? 0) > 0) {
        group.quantity = item.comboQuantity! > group.quantity
            ? item.comboQuantity!
            : group.quantity;
      }
      group.fallbackQuantity = item.quantity < group.fallbackQuantity
          ? item.quantity
          : group.fallbackQuantity;
    } else {
      sum += item.lineTotal;
    }
  }

  for (final entry in combos.entries) {
    final cid = entry.key;
    final group = entry.value;
    double price = group.price;
    if (price <= 0 && catalogCombos != null) {
      final matched = catalogCombos.where((c) => c.id == cid).firstOrNull;
      if (matched != null) price = matched.comboPrice;
    }
    final qty = group.quantity > 0
        ? group.quantity
        : (group.fallbackQuantity < 999999 ? group.fallbackQuantity : 1);
    sum += price * qty;
  }

  return sum;
}

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider).value ?? [];
  final combos = ref.watch(homeCombosProvider).valueOrNull;
  return getCartSubtotal(cart, combos);
});

/// Coupon + KK Coins draft shared between cart and checkout — mirrors the
/// website, where the cart's coupon/points editor feeds the same values
/// into the order (`applied_coupon`, `points_to_redeem`).
class CheckoutDraft {
  const CheckoutDraft({
    this.couponCode,
    this.couponDiscount = 0,
    this.pointsToRedeem = 0,
  });

  final String? couponCode;
  final double couponDiscount;
  final int pointsToRedeem;

  CheckoutDraft copyWith({
    String? couponCode,
    bool clearCoupon = false,
    double? couponDiscount,
    int? pointsToRedeem,
  }) =>
      CheckoutDraft(
        couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
        couponDiscount: couponDiscount ?? this.couponDiscount,
        pointsToRedeem: pointsToRedeem ?? this.pointsToRedeem,
      );
}

final checkoutDraftProvider =
    StateProvider<CheckoutDraft>((ref) => const CheckoutDraft());

/// On-device wishlist (product id set) — see WishlistStorage for why this
/// isn't synced to the account.
class WishlistNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => WishlistStorage.instance.readAll();

  Future<void> toggle(String productId) async {
    final current = Set<String>.from(state.value ?? {});
    if (!current.add(productId)) current.remove(productId);
    state = AsyncData(current);
    await WishlistStorage.instance.saveAll(current);
  }

  bool isFavorite(String productId) => (state.value ?? const {}).contains(productId);
}

final wishlistProvider = AsyncNotifierProvider<WishlistNotifier, Set<String>>(WishlistNotifier.new);

/// Cart quantity already added for a given (productId, variantId) pair —
/// backs the Blinkit-style on-card +/- stepper so cards can render "ADD" vs
/// a live quantity without a separate cart screen visit.
final cartQuantityProvider = Provider.family<int, (String productId, String? variantId)>((ref, key) {
  final cart = ref.watch(cartProvider).value ?? [];
  for (final item in cart) {
    if (item.comboId == null && item.productId == key.$1 && item.variantId == key.$2) {
      return item.quantity;
    }
  }
  return 0;
});

final comboCartQuantityProvider = Provider.family<int, String>((ref, comboId) {
  final cart = ref.watch(cartProvider).value ?? [];
  for (final item in cart) {
    if (item.comboId == comboId) return item.comboQuantity ?? item.quantity;
  }
  return 0;
});

final homeCombosProvider = FutureProvider.autoDispose<List<ComboBundle>>((ref) {
  return ref.read(catalogServiceProvider).fetchCombos();
});

final comboDetailProvider =
    FutureProvider.autoDispose.family<ComboBundle?, String>((ref, id) async {
  final single = await ref.read(catalogServiceProvider).fetchCombo(id);
  if (single != null) return single;
  try {
    final all = await ref.read(catalogServiceProvider).fetchCombos();
    for (final c in all) {
      if (c.id == id) return c;
    }
  } catch (_) {}
  return null;
});

/// Selected animal on the Home screen (`useHomeAnimal` on web). Null = All animals.
final selectedHomeAnimalProvider = StateProvider<String?>((ref) => null);

/// Delivery pincode the user has set on-device, and the live NimbusPost-backed
/// serviceability/ETA for it — powers the Blinkit-style "Deliver to ..." bar.
class DeliveryPincodeNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => DeliveryPincodeStorage.instance.read();

  Future<void> setPincode(String pincode) async {
    await DeliveryPincodeStorage.instance.save(pincode);
    state = AsyncData(pincode);
  }
}

final deliveryPincodeProvider =
    AsyncNotifierProvider<DeliveryPincodeNotifier, String?>(DeliveryPincodeNotifier.new);

final deliveryEtaProvider = FutureProvider.autoDispose<DeliveryInfo?>((ref) async {
  final pincode = ref.watch(deliveryPincodeProvider).value;
  if (pincode == null || pincode.length != 6) return null;
  return ref.read(deliveryServiceProvider).checkPincode(pincode);
});
