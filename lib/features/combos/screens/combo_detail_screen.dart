import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

class ComboStory {
  const ComboStory({
    required this.animal,
    required this.subtitle,
    required this.description,
    required this.featureLabels,
    required this.reasons,
    required this.tip,
  });

  final String animal;
  final String subtitle;
  final String description;
  final List<String> featureLabels;
  final List<String> reasons;
  final String tip;
}

ComboStory getComboStory(ComboBundle combo) {
  final searchText = [
    combo.name,
    combo.description,
    ...combo.items.map((i) => i.product?.name),
    ...combo.items.expand((i) => i.product?.animalTypes ?? const <String>[]),
  ].whereType<String>().join(' ').toLowerCase();

  if (RegExp(r'cow|cattle|livestock|calf|buffalo').hasMatch(searchText)) {
    return ComboStory(
      animal: 'cattle',
      subtitle: combo.description?.isNotEmpty == true
          ? combo.description!
          : 'Everyday cattle wellness kit',
      description:
          'A practical daily-care bundle selected to support nutrition, digestion, strength and overall herd wellness.',
      featureLabels: const [
        'Daily nutrition support',
        'Growth & strength',
        'Digestive wellness',
        'Vet-curated essentials',
      ],
      reasons: const [
        'Brings core everyday supplements into one kit',
        'Supports normal growth, appetite and strength',
        'Useful for regular cattle-care routines',
        'Simple, value-led choice for livestock keepers',
      ],
      tip:
          'Introduce supplements consistently and follow the feeding directions on each pack. Keep clean drinking water available at all times.',
    );
  }
  if (RegExp(r'dog|puppy|canine').hasMatch(searchText)) {
    return ComboStory(
      animal: 'dog',
      subtitle: combo.description?.isNotEmpty == true
          ? combo.description!
          : 'Dog wellness and grooming kit',
      description:
          'A considered starter bundle for a dog\'s everyday grooming, coat care and general wellness routine.',
      featureLabels: const [
        'Gentle daily care',
        'Coat & skin support',
        'Everyday wellness',
        'Vet-curated essentials',
      ],
      reasons: const [
        'Combines useful grooming and wellness essentials',
        'Supports a clean, healthy-looking coat',
        'Suitable for a simple regular-care routine',
        'An easy starting point for pet parents',
      ],
      tip:
          'Introduce one new grooming product at a time and follow every label carefully. Stop use if your pet shows irritation.',
    );
  }
  if (RegExp(r'cat|kitten|feline').hasMatch(searchText)) {
    return ComboStory(
      animal: 'cat',
      subtitle: combo.description?.isNotEmpty == true
          ? combo.description!
          : 'Everyday cat-care kit',
      description:
          'A balanced selection of daily-care essentials for a simpler feline wellness routine.',
      featureLabels: const [
        'Everyday care',
        'Skin & coat support',
        'Gentle routine',
        'Vet-curated essentials',
      ],
      reasons: const [
        'Keeps routine cat-care essentials together',
        'Supports coat and everyday wellness',
        'Easy to use as part of a regular routine',
        'Selected for practical at-home care',
      ],
      tip:
          'Cats can be sensitive to new products. Introduce items gradually and always follow the pack directions.',
    );
  }
  if (RegExp(r'poultry|chick|bird|broiler|layer').hasMatch(searchText)) {
    return ComboStory(
      animal: 'poultry',
      subtitle: combo.description?.isNotEmpty == true
          ? combo.description!
          : 'Poultry wellness kit',
      description:
          'A practical bundle for everyday flock nutrition, hydration and wellness management.',
      featureLabels: const [
        'Flock nutrition',
        'Hydration support',
        'Daily wellness',
        'Vet-curated essentials',
      ],
      reasons: const [
        'Groups routine flock-care essentials',
        'Supports normal nutrition and hydration',
        'Convenient for regular farm use',
        'A practical value bundle for keepers',
      ],
      tip:
          'Mix products only as directed and keep drinkers clean. Watch feed and water intake daily for early signs of change.',
    );
  }
  return ComboStory(
    animal: 'general',
    subtitle: combo.description?.isNotEmpty == true
        ? combo.description!
        : 'Everyday animal-care kit',
    description:
        'A thoughtfully grouped selection of animal-health essentials for a simpler everyday care routine.',
    featureLabels: const [
      'Everyday care',
      'Practical value',
      'Simple routine',
      'Vet-curated essentials',
    ],
    reasons: const [
      'Brings useful care essentials into one kit',
      'Makes regular routines easier to manage',
      'Offers better value than buying separately',
      'Selected for practical animal care',
    ],
    tip:
        'Follow every product label and introduce new supplements gradually. Contact a veterinarian when symptoms persist.',
  );
}

String getItemSupportText(String name) {
  final value = name.toLowerCase();
  if (value.contains('calcium')) return 'Everyday calcium and mineral support';
  if (RegExp(r'liver|liv|granliv').hasMatch(value)) {
    return 'Supports normal liver and digestive function';
  }
  if (RegExp(r'mineral|foodwin').hasMatch(value)) {
    return 'Daily mineral nutrition support';
  }
  if (RegExp(r'shampoo|soap|conditioner').hasMatch(value)) {
    return 'Gentle cleansing and coat care';
  }
  if (RegExp(r'vitamin|supplement|tonic').hasMatch(value)) {
    return 'Everyday nutritional support';
  }
  return 'A useful part of the complete care bundle';
}

/// Dedicated Bundle / Combo details page matching web's `ComboClient.tsx`
/// (`/combos/[id]`).
class ComboDetailScreen extends ConsumerStatefulWidget {
  const ComboDetailScreen({super.key, required this.comboId});
  final String comboId;

  @override
  ConsumerState<ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends ConsumerState<ComboDetailScreen> {
  bool _addingToCart = false;

  Future<void> _handleAddCombo(ComboBundle combo) async {
    if (_addingToCart) return;
    setState(() => _addingToCart = true);
    try {
      Haptics.tap();
      await ref.read(cartProvider.notifier).addCombo(
            combo.id,
            comboName: combo.name,
            comboPrice: combo.comboPrice,
            comboImage: combo.image,
          );
      showToast('${combo.name} added to cart!');
    } catch (e) {
      showToast('Could not add bundle: $e', isError: true);
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comboAsync = ref.watch(comboDetailProvider(widget.comboId));
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: comboAsync.maybeWhen(
          data: (combo) => combo != null
              ? Text(
                  combo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )
              : const Text('Care Combo'),
          orElse: () => const Text('Care Combo'),
        ),
        actions: [
          comboAsync.maybeWhen(
            data: (combo) => combo != null
                ? IconButton(
                    icon: const Icon(Icons.share_outlined,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () {
                      final url =
                          '${AppConfig.apiBaseUrl}/combos/${combo.id}';
                      AppShare.shareText(
                        context,
                        text: 'Check out ${combo.name} on KK Nutrivet:\n$url',
                        title: combo.name,
                        subject: combo.name,
                      );
                    },
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    size: 21, color: AppColors.textPrimary),
                onPressed: () => context.push('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: comboAsync.when(
        data: (combo) {
          if (combo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('Combo bundle not found',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }
          return _buildComboContent(context, combo);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Could not load combo bundle details'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(comboDetailProvider(widget.comboId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: comboAsync.maybeWhen(
        data: (combo) => combo != null ? _buildBottomBar(context, combo) : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildComboContent(BuildContext context, ComboBundle combo) {
    final story = getComboStory(combo);
    final featureIcons = [
      Icons.eco_outlined,
      Icons.auto_awesome_outlined,
      Icons.pets_outlined,
      Icons.shield_outlined,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Breadcrumb ──
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/home'),
                child: const Text('Home',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('›',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ),
              GestureDetector(
                onTap: () => context.push('/products?category=Combos'),
                child: const Text('Combos',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('›',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ),
              Expanded(
                child: Text(
                  combo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Hero Media Card ──
          _buildHeroCard(combo),
          const SizedBox(height: 16),

          // ── Badges ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'CARE COMBO',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (combo.savingPercent > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE1CB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Save ${combo.savingPercent}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFA83B23),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${combo.items.length} items',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Title & Subtitle ──
          Text(
            combo.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Color(0xFF073F2F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story.subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF526159),
            ),
          ),
          const SizedBox(height: 12),

          // ── Mobile Price Box ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE7E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMBO PRICE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF526159),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${formatPrice(combo.comboPrice)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B714F),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (combo.originalPrice > combo.comboPrice)
                      Text(
                        '₹${formatPrice(combo.originalPrice)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (combo.savingPercent > 0)
                      Text(
                        'Save ${combo.savingPercent}%',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE04D20),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Description ──
          Text(
            story.description,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // ── 4 Feature Icons 2×2 ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: story.featureLabels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, i) {
              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F0E5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      featureIcons[i % featureIcons.length],
                      size: 16,
                      color: const Color(0xFF175F49),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      story.featureLabels[i],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF43574F),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── What's in this combo ──
          _buildWhatsInThisCombo(context, combo),
          const SizedBox(height: 16),

          // ── Why this combo works ──
          _buildWhyItWorks(story),
          const SizedBox(height: 16),

          // ── Care tip ──
          _buildCareTip(story),
          const SizedBox(height: 16),

          // ── Trust Strip ──
          _buildTrustStrip(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroCard(ComboBundle combo) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F0E7), Color(0xFFEDE4D5)],
        ),
        border: Border.all(color: const Color(0xFFE3D6C6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF304037).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background decorative circle
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFA9C89F).withValues(alpha: 0.25),
                  width: 16,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Image or Collage
          if (combo.image != null && combo.image!.isNotEmpty)
            Positioned.fill(
              child: AppNetworkImage(
                imageUrl: combo.image,
                fit: BoxFit.cover,
                memCacheWidth: 800,
                errorWidget: (_, _, _) => _buildItemsCollage(combo),
              ),
            )
          else
            _buildItemsCollage(combo),

          // Bottom pill badge
          Positioned(
            bottom: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${combo.items.length} CAREFULLY SELECTED PRODUCTS',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: Color(0xFF315B4D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCollage(ComboBundle combo) {
    final items = combo.items.take(4).toList();
    if (items.isEmpty) {
      return const Center(
        child: Icon(Icons.inventory_2_outlined,
            size: 48, color: AppColors.primaryDeep),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final img = item.product?.image;
            return Container(
              margin: EdgeInsets.only(
                left: idx > 0 ? 10 : 0,
                bottom: idx.isOdd ? 10 : 0,
              ),
              width: 68,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E0D2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF403729).withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (img != null && img.isNotEmpty)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AppNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.contain,
                          memCacheWidth: 200,
                          fallbackIcon: Icons.medication_outlined,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.medication_outlined,
                          size: 24, color: AppColors.primaryDeep),
                    ),
                  if (item.quantity > 1)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeep,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '×${item.quantity}',
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWhatsInThisCombo(BuildContext context, ComboBundle combo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 18, color: AppColors.primaryDeep),
              SizedBox(width: 8),
              Text(
                'What\'s in this combo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Each product is authentic, factory sealed and verified.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          for (var i = 0; i < combo.items.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: AppColors.border),
            _buildComboItemRow(context, combo.items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildComboItemRow(BuildContext context, ComboItem item) {
    final product = item.product;
    final name = product?.name ?? 'Item ${item.productId}';
    final supportText = getItemSupportText(name);
    final price = product?.price ?? 0;
    final mrp = product?.mrp;

    return InkWell(
      onTap: () {
        if (product != null) {
          final slugOrId =
              product.slug.isNotEmpty ? product.slug : product.id;
          context.push('/products/$slugOrId');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: product?.image != null && product!.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.image!,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.medication_outlined,
                        size: 20,
                        color: AppColors.primaryDeep,
                      ),
                    )
                  : const Icon(Icons.medication_outlined,
                      size: 20, color: AppColors.primaryDeep),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supportText,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${formatPrice(price)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      if (mrp != null && mrp > price) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${formatPrice(mrp)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryWash,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Qty: ${item.quantity}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyItWorks(ComboStory story) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5E7DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pets_rounded, size: 18, color: Color(0xFF175F49)),
              SizedBox(width: 8),
              Text(
                'Why this combo works',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F4D3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final reason in story.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF365249),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCareTip(ComboStory story) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D9C8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: Color(0xFFF07A35),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Care tip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF23463B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  story.tip,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF53645E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustStrip() {
    final pillars = [
      (Icons.favorite_rounded, 'Trusted by pet & livestock parents'),
      (Icons.verified_rounded, 'Curated for practical everyday care'),
      (Icons.shield_outlined, 'Happiness. Health. Trust.'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF1F7F1), Color(0xFFF7F8F0)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5DC)),
      ),
      child: Column(
        children: pillars.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(p.$1, size: 15, color: const Color(0xFF23483B)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    p.$2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF23483B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ComboBundle combo) {
    final inCartQty = ref.watch(comboCartQuantityProvider(combo.id));
    final inCart = inCartQty > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFD8E3DD))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173C32).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COMBO PRICE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFF74817B),
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${formatPrice(combo.comboPrice)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (combo.originalPrice > combo.comboPrice) ...[
                    const SizedBox(width: 6),
                    Text(
                      '₹${formatPrice(combo.originalPrice)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: inCart
                ? ElevatedButton.icon(
                    onPressed: () => context.push('/cart'),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('View in Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryWash,
                      foregroundColor: AppColors.primaryDeep,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                            color: Color(0xFF0B714F), width: 0.8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed:
                        _addingToCart ? null : () => _handleAddCombo(combo),
                    icon: _addingToCart
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined,
                            size: 18, color: Colors.white),
                    label: Text(_addingToCart ? 'Adding...' : 'Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      iconColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
