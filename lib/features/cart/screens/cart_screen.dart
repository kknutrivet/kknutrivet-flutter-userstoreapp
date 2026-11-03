import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/checkout_breadcrumb.dart';
import '../../../core/widgets/common.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../models/store_settings.dart';
import '../../../providers/app_providers.dart';
import '../widgets/cart_coupons_and_coins.dart';
import '../widgets/cart_impulse_addons.dart';
import '../widgets/cart_item_tiles.dart';
import '../widgets/cart_summary_and_bars.dart';

export '../widgets/cart_coupons_and_coins.dart';
export '../widgets/cart_impulse_addons.dart';
export '../widgets/cart_item_tiles.dart';
export '../widgets/cart_summary_and_bars.dart';

/// Cart replica of the website's mobile cart (`src/app/cart/page.tsx`):
/// breadcrumb, Rx review banner (none/pending/approved), free-delivery
/// progress, grouped Care Combo Bundle cards, smart "UPGRADE & SAVE" banner,
/// cross-sell combos rail, prescription assistance banner, coupon offers sheet
/// + validation, KK Coins Slider editor (30% cap), order summary, sticky checkout bar.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final settingsAsync = ref.watch(storeSettingsProvider);
    final combosAsync = ref.watch(homeCombosProvider);
    final combos = combosAsync.value ?? const <ComboBundle>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE6EFEA)),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          errorBuilder: (_, _, _) => const Text(
            'KK NUTRIVET',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
      ),
      body: cartAsync.when(
        data: (items) {
          if (items.isEmpty) return const EmptyCartView();
          final subtotal = ref.watch(cartTotalProvider);
          final cartCount = ref.watch(cartCountProvider);
          final draft = ref.watch(checkoutDraftProvider);
          final pincode = ref.watch(deliveryPincodeProvider).valueOrNull;
          final deliveryInfo = ref.watch(deliveryEtaProvider).valueOrNull;
          final settings =
              settingsAsync.valueOrNull ?? StoreSettings.defaults();
          final outOfStock = items.any((i) => i.hasStockIssue);
          final discount = draft.couponDiscount + draft.pointsToRedeem;
          final merchandiseAfterDiscount = (subtotal - discount).clamp(
            0.0,
            double.infinity,
          );
          final freeDeliveryThreshold = settings.effectiveFreeDeliveryThreshold(
            pincode: pincode,
            source: deliveryInfo?.source,
          );
          final baseDeliveryCharge = settings.effectiveDeliveryCharge(
            pincode: pincode,
            source: deliveryInfo?.source,
          );
          final deliveryFee = settings.calculateDeliveryFee(
            merchandiseAfterDiscount,
            pincode: pincode,
            source: deliveryInfo?.source,
          );
          final total = (merchandiseAfterDiscount + deliveryFee).clamp(
            0.0,
            double.infinity,
          );
          final earnedCoins = (subtotal * 0.05).round();
          final cartEntries = _buildCartEntries(items, combos);

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            children: [
              // Editorial Cart Title + Item Badge (matching `src/app/cart/page.tsx`)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Cart',
                      style: AppTheme.serif(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWash,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.primaryWashDeep),
                      ),
                      child: Text(
                        '$cartCount ${cartCount == 1 ? "item" : "items"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const CheckoutBreadcrumb(currentStep: 0),
              const SizedBox(height: 10),
              CartRxBanner(items: items),
              CartFreeDeliveryBar(
                subtotal: merchandiseAfterDiscount,
                threshold: freeDeliveryThreshold,
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryWashDeep),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F052E20),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildItemsHeader(
                      entryCount: cartEntries.length,
                      earnedCoins: earnedCoins,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                      child: Column(children: cartEntries),
                    ),
                  ],
                ),
              ),
              CartCouponRow(subtotal: subtotal),
              const SizedBox(height: 8),
              CartPointsRow(subtotal: subtotal),
              const SizedBox(height: 8),
              const CartDeliveryCheckerCard(),
              const SizedBox(height: 8),
              CartSummaryCard(
                subtotal: subtotal,
                couponCode: draft.couponCode,
                couponDiscount: draft.couponDiscount,
                points: draft.pointsToRedeem,
                deliveryFee: deliveryFee,
                baseDeliveryCharge: baseDeliveryCharge,
                freeDeliveryThreshold: freeDeliveryThreshold,
                total: total.toDouble(),
              ),
              if (outOfStock) ...[
                const SizedBox(height: 8),
                _buildOutOfStockWarning(),
              ],
              // Useful extras for your animal (Matching src/components/cart/CartImpulseAddons.tsx)
              const SizedBox(height: 6),
              CartImpulseAddonsSection(
                amountForFreeDelivery:
                    (freeDeliveryThreshold - merchandiseAfterDiscount).clamp(
                      0.0,
                      double.infinity,
                    ),
                qualifiesForFreeDelivery:
                    freeDeliveryThreshold > 0 &&
                    merchandiseAfterDiscount >= freeDeliveryThreshold,
              ),
              const SizedBox(height: 4),
              // Cross-Sell Combos Rail
              if (combos.where((c) => c.isActive).isNotEmpty) ...[
                const SizedBox(height: 2),
                CrossSellCombosRail(
                  combos: combos.where((c) => c.isActive).toList(),
                  cartItems: items,
                ),
                const SizedBox(height: 10),
              ],
              // Prescription Assistance Banner
              const PrescriptionAssistanceBanner(),
              const SizedBox(height: 10),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message:
              'Could not load this information. Check your connection and retry.',
          onRetry: () => ref.invalidate(cartProvider),
        ),
      ),
      bottomNavigationBar: cartAsync.maybeWhen(
        data: (items) {
          if (items.isEmpty) return null;
          final subtotal = ref.watch(cartTotalProvider);
          final draft = ref.watch(checkoutDraftProvider);
          final pincode = ref.watch(deliveryPincodeProvider).valueOrNull;
          final deliveryInfo = ref.watch(deliveryEtaProvider).valueOrNull;
          final settings = settingsAsync.valueOrNull;
          final blocked = items.any((i) => i.hasStockIssue);
          final merchandiseAfterDiscount =
              (subtotal - draft.couponDiscount - draft.pointsToRedeem).clamp(
                0.0,
                double.infinity,
              );
          final freeDeliveryThreshold =
              settings?.effectiveFreeDeliveryThreshold(
                pincode: pincode,
                source: deliveryInfo?.source,
              ) ??
              500.0;
          final baseDeliveryCharge =
              settings?.effectiveDeliveryCharge(
                pincode: pincode,
                source: deliveryInfo?.source,
              ) ??
              49.0;
          final deliveryFee = settings != null
              ? settings.calculateDeliveryFee(
                  merchandiseAfterDiscount,
                  pincode: pincode,
                  source: deliveryInfo?.source,
                )
              : (merchandiseAfterDiscount >= freeDeliveryThreshold
                    ? 0.0
                    : baseDeliveryCharge);
          final total = (merchandiseAfterDiscount + deliveryFee).clamp(
            0.0,
            double.infinity,
          );
          return CartStickyCheckoutBar(
            total: total.toDouble(),
            blocked: blocked,
          );
        },
        orElse: () => null,
      ),
    );
  }

  /// Groups cart items by non-null `comboId` while preserving order.
  List<Widget> _buildCartEntries(
    List<CartItem> items,
    List<ComboBundle> combos,
  ) {
    final renderedComboIds = <String>{};
    final cartEntries = <Widget>[];
    for (final item in items) {
      final cid = item.comboId;
      if (cid != null && cid.isNotEmpty) {
        if (renderedComboIds.add(cid)) {
          final bundleItems = items.where((i) => i.comboId == cid).toList();
          cartEntries.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  ComboBundleCartTile(
                    comboId: cid,
                    bundleItems: bundleItems,
                    combos: combos,
                  ),
                  for (final member in bundleItems.where(
                    (i) => i.hasStockIssue,
                  ))
                    _StockCorrection(item: member),
                ],
              ),
            ),
          );
        }
      } else {
        cartEntries.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                CartItemTile(item: item, allCartItems: items, combos: combos),
                if (item.hasStockIssue) _StockCorrection(item: item),
              ],
            ),
          ),
        );
      }
    }
    return cartEntries;
  }

  /// Cart Items Header with KK Coins Earned Note.
  Widget _buildItemsHeader({
    required int entryCount,
    required int earnedCoins,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        color: AppColors.primaryWashFaint,
        border: Border(bottom: BorderSide(color: AppColors.primaryWashDeep)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: AppColors.primaryDeep,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Cart Items ($entryCount)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (earnedCoins > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: AppColors.coinsBg,
                border: Border.all(color: AppColors.coinsBorder),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '🪙 +$earnedCoins coins',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coinsIcon,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutOfStockWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Review the highlighted items above. Adjust unavailable quantities or remove items to continue.',
        style: TextStyle(fontSize: 12, color: AppColors.error, height: 1.4),
      ),
    );
  }
}

class _StockCorrection extends ConsumerStatefulWidget {
  const _StockCorrection({required this.item});
  final CartItem item;
  @override
  ConsumerState<_StockCorrection> createState() => _StockCorrectionState();
}

class _StockCorrectionState extends ConsumerState<_StockCorrection> {
  bool _busy = false;
  String? _error;
  Future<void> _correct({required bool remove}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final item = widget.item;
    try {
      final cart = ref.read(cartProvider.notifier);
      if (item.comboId?.isNotEmpty == true) {
        await cart.setComboQuantity(item.comboId!, 0);
      } else if (remove) {
        await cart.removeItem(item.id);
      } else {
        await cart.setQuantity(
          productId: item.productId,
          variantId: item.variantId,
          quantity: item.availableStock!,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not update this item. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final available = item.availableStock ?? 0;
    final bundle = item.comboId?.isNotEmpty == true;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.product?.name ?? "Item"}: ${available <= 0 ? "out of stock" : "only $available available"}.',
              style: const TextStyle(color: AppColors.error),
            ),
            if (_error != null) Text(_error!),
            Wrap(
              spacing: 8,
              children: [
                if (!bundle && available >= item.minimumQuantity)
                  TextButton(
                    onPressed: _busy ? null : () => _correct(remove: false),
                    child: Text('Reduce to $available'),
                  ),
                TextButton(
                  onPressed: _busy ? null : () => _correct(remove: true),
                  child: Text(bundle ? 'Remove bundle' : 'Remove item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
