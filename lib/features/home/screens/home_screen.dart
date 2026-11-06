import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/in_app_announcement_dialog.dart';
import '../../../providers/app_providers.dart';
import '../widgets/home_animal_selector.dart';
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

/// Replica of the website's mobile homepage
/// (`src/components/MobileHomeExperience.tsx` in kknutrivet-webapp)
/// enhanced with dynamic delivery promise, quick pet switcher, and reorder rail.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      InAppAnnouncementCoordinator.checkAndShow(
        context,
        ref,
        currentRoute: '/home',
      );
    });
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
    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final audience = homeAudienceFor(selectedAnimal);

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: _onRefresh,
        child: CustomScrollView(
            slivers: [
              const HomeBrandBar(),
              const SliverToBoxAdapter(child: HomeTopBarCard()),
              const HomePinnedSearchBar(),
              const SliverToBoxAdapter(child: HomeMyPetsBar()),
              const SliverToBoxAdapter(child: HomeAnimalSelector()),
              SliverToBoxAdapter(
                child: HomeCategorySelector(selectedAnimal: selectedAnimal),
              ),
              const SliverToBoxAdapter(child: HomeReorderRail()),
              const SliverToBoxAdapter(child: HomeConcernsRail()),
              SliverToBoxAdapter(
                child: HomeFeaturedProductsRail(selectedAnimal: selectedAnimal),
              ),
              const SliverToBoxAdapter(child: HomeShotsRail()),
              SliverToBoxAdapter(
                child: HomeAnimalProductRail(entry: kHomeAnimals[0]),
              ),
              SliverToBoxAdapter(
                child: HomeAnimalProductRail(entry: kHomeAnimals[1]),
              ),
              const SliverToBoxAdapter(child: HomePrescriptionCard()),
              const SliverToBoxAdapter(child: HomeCareProductRail()),
              SliverToBoxAdapter(
                child: HomeAnimalProductRail(entry: kHomeAnimals[2]),
              ),
              SliverToBoxAdapter(
                child: HomeAnimalProductRail(entry: kHomeAnimals[3]),
              ),
              SliverToBoxAdapter(
                child: HomeCombosRail(selectedAnimal: selectedAnimal),
              ),
              SliverToBoxAdapter(
                child: HomeAnimalProductRail(entry: kHomeAnimals[4]),
              ),
              const SliverToBoxAdapter(child: HomeTrustPanel()),
              SliverToBoxAdapter(
                child: HomeAnimalProductRail(entry: kHomeAnimals[5]),
              ),
              const SliverToBoxAdapter(child: HomeCareReachStoryCard()),
              const SliverToBoxAdapter(child: HomeReviewsBand()),
              const SliverToBoxAdapter(child: HomeMonsoonCareBanner()),
              SliverToBoxAdapter(
                child: HomeKnowledgeRail(selectedAnimal: selectedAnimal),
              ),
              if (audience != 'livestock')
                const SliverToBoxAdapter(child: HomeCareSpaceCard()),
              const SliverToBoxAdapter(child: HomeBrandsRail()),
              const SliverToBoxAdapter(child: HomeHelpRail()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      );
  }
}
