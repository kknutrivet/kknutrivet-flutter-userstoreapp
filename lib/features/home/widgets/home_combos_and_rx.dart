import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

// ── 6. PrescriptionUploadFeature (matches src/components/home/PrescriptionUploadFeature.tsx) ──
class HomePrescriptionCard extends ConsumerWidget {
  const HomePrescriptionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(storeSettingsProvider).valueOrNull;
    final discountPercent = settings?.prescriptionDiscountPercent ?? 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F3),
          border: Border.all(color: const Color(0xFFDCE7DF)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: Color(0xFF426151),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'CARE SLIP SUPPORT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: Color(0xFF426151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (discountPercent > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '🪙 +$discountPercent% KK Coins',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Your care slip.\nYour shopping, simplified.',
              style: TextStyle(
                fontSize: 23,
                height: 1.22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: Color(0xFF173D30),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share a photo or PDF. Our team helps find the products you need.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF52665A),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Haptics.tap();
                  context.push('/prescriptions');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF176448),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_rounded, size: 17),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Upload care slip',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Free review · Photo or PDF',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF52665A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 7. CombosRail (matches src/components/home/CombosRail.tsx) ─────────────
class HomeCombosRail extends ConsumerWidget {
  const HomeCombosRail({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combosAsync = ref.watch(homeCombosProvider);
    return combosAsync.maybeWhen(
      data: (combos) {
        if (combos.isEmpty) return const SizedBox.shrink();
        final filtered = selectedAnimal != null && selectedAnimal!.isNotEmpty
            ? combos.where((c) => c.matchesAnimal(selectedAnimal)).toList()
            : combos;
        final activeCombos = filtered.isNotEmpty ? filtered : combos;
        final shown = activeCombos.take(6).toList();
        if (shown.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F1E7),
            border: Border(
              top: BorderSide(color: Color(0xFFE9DCCB)),
              bottom: BorderSide(color: Color(0xFFE9DCCB)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEE0C8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 23,
                        color: Color(0xFF796038),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Care bundles, better value',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Color(0xFF413C29),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Essentials together. A little more saved.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF637367),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: const Color(0xFF796038),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          Haptics.tap();
                          context.push('/products?category=Combos');
                        },
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 294,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 210,
                    child: HomeComboCard(combo: shown[i]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── HomeComboCard (matches src/components/home/HomeComboCard.tsx) ──────────
class HomeComboCard extends ConsumerStatefulWidget {
  const HomeComboCard({super.key, required this.combo});
  final ComboBundle combo;

  @override
  ConsumerState<HomeComboCard> createState() => _HomeComboCardState();
}

class _HomeComboCardState extends ConsumerState<HomeComboCard> {
  bool _busy = false;

  Future<void> _changeQuantity(int nextQty) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      Haptics.tap();
      final currentQty = ref.read(comboCartQuantityProvider(widget.combo.id));
      if (currentQty == 0 && nextQty > 0) {
        await ref.read(cartProvider.notifier).addCombo(
          widget.combo.id,
          comboName: widget.combo.name,
          comboPrice: widget.combo.comboPrice,
          comboImage: widget.combo.image,
        );
        showToast('${widget.combo.name} bundle added to cart!');
      } else if (nextQty == 0) {
        await ref
            .read(cartProvider.notifier)
            .setComboQuantity(widget.combo.id, 0);
        showToast('${widget.combo.name} bundle removed from cart');
      } else {
        await ref
            .read(cartProvider.notifier)
            .setComboQuantity(widget.combo.id, nextQty);
        showToast('Updated bundle quantity to $nextQty');
      }
    } catch (e) {
      showToast('Could not update bundle: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.combo;
    final qty = ref.watch(comboCartQuantityProvider(combo.id));

    return AppBounce(
      pressedScale: 0.98,
      onTap: () {
        Haptics.tap();
        context.push('/combos/${combo.id}');
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDFE7E1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean white image area matching webapp HomeComboCard
              SizedBox(
                height: 156,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Colors.white),
                    if (combo.image != null && combo.image!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: AppNetworkImage(
                          imageUrl: combo.image,
                          fit: BoxFit.contain,
                          memCacheWidth: 600,
                          errorWidget: (_, _, _) => _comboItemsCollage(combo),
                        ),
                      )
                    else
                      _comboItemsCollage(combo),
                    if (combo.savingPercent > 0)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3EA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save ${combo.savingPercent}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF176448),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${combo.items.length} ${combo.items.length == 1 ? 'product' : 'products'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF637367),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 38,
                      child: Text(
                        combo.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17322B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${formatInr(combo.comboPrice)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF17322B),
                          ),
                        ),
                        if (combo.originalPrice > combo.comboPrice)
                          Text(
                            '₹${formatInr(combo.originalPrice)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF637367),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    AppScaleSwitcher(
                      child: qty > 0
                          ? Container(
                              key: const ValueKey('combo_stepper'),
                              height: 38,
                              width: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF07583F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _busy
                                          ? null
                                          : () => _changeQuantity(qty - 1),
                                      child: const Center(
                                        child: Text(
                                          '−',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: _busy
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : AppTextSwitcher(
                                              text: '$qty',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _busy
                                          ? null
                                          : () => _changeQuantity(qty + 1),
                                      child: const Center(
                                        child: Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              key: const ValueKey('combo_add'),
                              height: 38,
                              width: 80,
                              child: FilledButton(
                                onPressed:
                                    _busy ? null : () => _changeQuantity(1),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF07583F),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comboItemsCollage(ComboBundle combo) {
    final preview = combo.items.take(3).toList();
    if (preview.isEmpty) {
      return const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 26,
          color: Color(0xFF176448),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < preview.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AppNetworkImage(
                imageUrl: preview[i].product?.image,
                fit: BoxFit.contain,
                memCacheWidth: 200,
                fallbackIcon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
