import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/in_app_announcement_dialog.dart';
import '../../../providers/app_providers.dart';
import '../widgets/home_animal_selector.dart';
import '../widgets/home_care_bento.dart';
import '../widgets/home_combos_and_rx.dart';
import '../widgets/home_community_and_footer.dart';
import '../widgets/home_models_and_data.dart';
import '../widgets/home_product_rails.dart';
import '../widgets/home_story_and_trust.dart';
import '../widgets/home_top_bar.dart';

export '../../../providers/app_providers.dart'
    show
        deliveryEtaProvider,
        deliveryPincodeProvider,
        homeCombosProvider,
        selectedHomeAnimalProvider;
export '../widgets/home_models_and_data.dart'
    show
        animalTypeProductsProvider,
        bestSellersProductsProvider,
        homeBlogPostsProvider,
        homeBrandsProvider,
        homeCareProductsProvider,
        homeConcernsProvider,
        homePetsProvider,
        homeShotsProvider,
        recentReorderProductsProvider,
        spotlightProductsProvider,
        trendingProductsProvider;

/// Modern Veterinary & Animal Care Commerce Homepage.
/// Combines editorial curation (Lora serif + studio bento grids) with
/// personalized species filtering, quick reorder, and video discovery.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      InAppAnnouncementCoordinator.checkAndShow(
        context,
        ref,
        currentRoute: '/home',
      );
    });
  }

  void _onScroll() {
    final next = _scrollController.hasClients && _scrollController.offset > 380;
    if (next != _showBackToTop && mounted) {
      setState(() => _showBackToTop = next);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(storeSettingsProvider);
    ref.invalidate(homeBrandsProvider);
    ref.invalidate(homeBlogPostsProvider);
    ref.invalidate(homeConcernsProvider);
    ref.invalidate(homePetsProvider);
    ref.invalidate(recentReorderProductsProvider);
    ref.invalidate(homeCombosProvider);
    ref.invalidate(homepageSectionsProvider);
    ref.invalidate(bestSellersProductsProvider);
    ref.invalidate(spotlightProductsProvider);
    ref.invalidate(homeCareProductsProvider);
    ref.invalidate(homeShotsProvider);
    ref.invalidate(trendingProductsProvider);
    for (final a in kHomeAnimals) {
      ref.invalidate(animalTypeProductsProvider(a.value));
    }
    await Future.wait([
      ref.read(categoriesProvider.future),
      ref.read(homeBrandsProvider.future),
      ref.read(homeBlogPostsProvider.future),
      ref.read(homeCombosProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(selectedHomeAnimalProvider, (prev, next) {
      if (prev != next &&
          _scrollController.hasClients &&
          _scrollController.offset > 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });

    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final animalTheme = homeAnimalThemeFor(selectedAnimal);
    final selectedEntry = findHomeAnimalEntry(selectedAnimal);
    final pets = ref.watch(homePetsProvider).valueOrNull;
    final preferredEntry = selectedEntry == null && pets != null && pets.isNotEmpty
        ? findHomeAnimalEntry(pets.first.animalType)
        : null;
    final List<HomeAnimalEntry> activeAnimalEntries = selectedEntry != null
        ? [selectedEntry]
        : preferredEntry != null
            ? [
                preferredEntry,
                ...kHomeAnimals.where((e) => e.value != preferredEntry.value),
              ]
            : kHomeAnimals;
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              height: topInset,
              color: animalTheme.headerBg,
            ),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: AppColors.primaryDeep,
                    onRefresh: _onRefresh,
                    child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 1. Cream Top Bar, Pinned Search & Pinned Species Tab Strip
                const HomeBrandBar(),
                const HomePinnedSearchBar(),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedSpeciesTabDelegate(),
                ),

                // 2. Active Order Alert at very top when user has an ongoing order
                const SliverToBoxAdapter(child: HomeActiveOrderBanner()),

                // 3. Care in spotlight (Horizontal Pastel Tiles)
                const SliverToBoxAdapter(child: HomeCareBentoSection()),

                // When an animal tab is active, surface its products immediately above the fold
                if (selectedEntry != null)
                  SliverToBoxAdapter(
                    child: HomeAnimalProductRail(entry: selectedEntry),
                  ),

                // 4. Value Combos in top 3rd slot
                SliverToBoxAdapter(
                  child: HomeCombosRail(selectedAnimal: selectedAnimal),
                ),

                // 5. Shop by category (Horizontal Full-Bleed Tiles) & Category Product Shelves
                SliverToBoxAdapter(
                  child: HomeCategorySelector(selectedAnimal: selectedAnimal),
                ),
                SliverToBoxAdapter(
                  child: HomeCategoryProductShelves(selectedAnimal: selectedAnimal),
                ),

                // 6. 1-Tap Reorder & Featured Products
                const SliverToBoxAdapter(child: HomeReorderRail()),
                SliverToBoxAdapter(
                  child: HomeFeaturedProductsRail(selectedAnimal: selectedAnimal),
                ),

                // 7. Care by concern & Video Shots
                const SliverToBoxAdapter(child: HomeConcernsRail()),
                const SliverToBoxAdapter(child: HomeShotsRail()),

                // 8. Dynamic Species Product Shelves & Home Care
                if (selectedEntry == null)
                  for (var i = 0; i < activeAnimalEntries.length; i++) ...[
                    SliverToBoxAdapter(
                      child: HomeAnimalProductRail(entry: activeAnimalEntries[i]),
                    ),
                    if (i == 3) const SliverToBoxAdapter(child: HomeCareProductRail()),
                  ],
                if (selectedEntry != null)
                  const SliverToBoxAdapter(child: HomeCareProductRail()),

                // 7. Social Proof, Vet Knowledge & Atmospheric Brand Sign-Off
                const SliverToBoxAdapter(child: HomeReviewsBand()),
                SliverToBoxAdapter(
                  child: HomeKnowledgeRail(selectedAnimal: selectedAnimal),
                ),
                const SliverToBoxAdapter(child: HomeBrandSignatureFooter()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
          if (_showBackToTop)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 54 + 60 + 58 + 8,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: const Color(0xE61C1C1C),
                  borderRadius: BorderRadius.circular(999),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Back to top',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
    );
  }
}

class _PinnedSpeciesTabDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 62;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const SizedBox(
      height: _height,
      child: HomeAnimalSelector(),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSpeciesTabDelegate oldDelegate) => false;
}
