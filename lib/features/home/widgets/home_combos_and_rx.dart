import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Semantics(
        button: true,
        label: 'Upload care slip. Camera or gallery photo.',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/prescriptions'),
            child: Image.asset(
              'assets/marketing_image/upload-care-slip-banner.webp',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeComboHint {
  const HomeComboHint({required this.id, required this.savings});
  final String id;
  final int savings;
}

final homeLoadedCombosProvider = StateProvider<List<ComboBundle>>((ref) => const []);

final homeComboLookupProvider = Provider<Map<String, HomeComboHint>>((ref) {
  final combos = ref.watch(homeLoadedCombosProvider);
  final map = <String, HomeComboHint>{};
  for (final combo in combos) {
    final savings = combo.originalPrice > combo.comboPrice
        ? (combo.originalPrice - combo.comboPrice).round()
        : 0;
    final hint = HomeComboHint(id: combo.id, savings: savings);
    for (final item in combo.items) {
      if (item.productId.isNotEmpty && !map.containsKey(item.productId)) {
        map[item.productId] = hint;
      }
    }
  }
  return map;
});

class HomeCombosRail extends ConsumerWidget {
  const HomeCombosRail({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<ComboBundle>>>(homeCombosProvider, (_, next) {
      next.whenData((list) {
        if (ref.read(homeLoadedCombosProvider) != list) {
          ref.read(homeLoadedCombosProvider.notifier).state = list;
        }
      });
    });
    final combosAsync = ref.watch(homeCombosProvider);
    return combosAsync.maybeWhen(
      data: (combos) {
        if (combos.isEmpty) return const SizedBox.shrink();
        final activeCombos = selectedAnimal != null && selectedAnimal!.isNotEmpty
            ? combos.where((c) => c.matchesAnimal(selectedAnimal)).toList()
            : combos;
        final shown = activeCombos.take(6).toList();
        if (shown.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Expanded(
                      child: Text(
                        'Care bundles, better value',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Haptics.tap();
                        context.go('/products?category=Combos');
                      },
                      child: const Text(
                        'See all →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF07583F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 244,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => SizedBox(
                    width: 188,
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
        await ref
            .read(cartProvider.notifier)
            .addCombo(
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
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD6E5DC)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1214382B),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtle mint-cream bundle stage
              Container(
                height: 112,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF3FAF6), Color(0xFFEAF5EE)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFDFECE4)),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (combo.image != null && combo.image!.isNotEmpty)
                      AppNetworkImage(
                        imageUrl: combo.image,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        errorWidget: (_, _, _) => _comboItemsCollage(combo),
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
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF07583F),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2207583F),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'SAVE ${combo.savingPercent}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: Color(0xFFC9FF67),
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
                                onPressed: _busy
                                    ? null
                                    : () => _changeQuantity(1),
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
