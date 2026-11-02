import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../analytics/analytics_service.dart';
import '../analytics/mixpanel_service.dart';
import '../animations/app_animations.dart';
import '../crashlytics/crashlytics_service.dart';

import '../../features/addresses/screens/address_form_screen.dart';
import '../../features/addresses/screens/addresses_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/calculator/screens/calculator_screen.dart';
import '../../features/health/screens/disease_detail_screen.dart';
import '../../features/health/screens/diseases_screen.dart';
import '../../features/help/screens/help_screen.dart';
import '../../features/help/screens/pincode_check_screen.dart';
import '../../features/help/screens/static_page_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/pet_care/screens/pet_care_screen.dart';
import '../../features/referral/screens/referral_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/vet/screens/ask_dr_paw_screen.dart';
import '../../features/vet/screens/vet_insights_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/blog/screens/blog_detail_screen.dart';
import '../../features/blog/screens/blog_list_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/combos/screens/combo_detail_screen.dart';
import '../../features/consultations/screens/book_consultation_screen.dart';
import '../../features/consultations/screens/consultation_detail_screen.dart';
import '../../features/consultations/screens/consultations_home_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/pets/screens/pet_detail_screen.dart';
import '../../features/pets/screens/pet_form_screen.dart';
import '../../features/pets/screens/pets_screen.dart';
import '../../features/prescriptions/screens/prescriptions_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/product_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/shots/screens/shots_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../models/address.dart';
import '../../models/product.dart';
import '../../providers/app_providers.dart';

const _publicPaths = {
  '/splash',
  '/onboarding',
  '/home',
  '/products',
  '/combos',
  '/combo',
  '/cart',
  '/search',
  '/login',
  '/forgot-password',
  '/blog',
  '/shots',
  '/diseases',
  '/health-concerns',
  '/consultations',
  '/care-chat',
  '/prescriptions',
  '/scan',
  '/vet',
  '/pet-care',
  '/calculator',
  '/pincode',
  '/help',
  '/info',
  '/checkout',
  '/addresses',
};

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    observers: [
      if (AnalyticsService.instance.observer != null)
        AnalyticsService.instance.observer!,
      AnalyticsService.instance.navigatorObserver,
    ],
    refreshListenable: GoRouterRefreshAuth(ref),
    redirect: (context, state) {
      // Splash owns its own navigation once auth/onboarding state resolves.
      if (state.matchedLocation == '/splash') return null;

      final onboardingState = ref.read(onboardingProvider);
      if (onboardingState.value == false &&
          state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      final authState = ref.read(authProvider);
      final isLoggedIn = authState.value != null;
      final loggingIn = state.matchedLocation == '/login';
      final isPublic =
          _publicPaths.any((p) => state.matchedLocation.startsWith(p)) ||
          state.matchedLocation.startsWith('/product/') ||
          state.matchedLocation.startsWith('/combos/') ||
          state.matchedLocation.startsWith('/combo/') ||
          state.matchedLocation.startsWith('/blog/');

      if (authState.isLoading || onboardingState.isLoading) return null;
      if (!isLoggedIn && !isPublic && !loggingIn) {
        // Remember where the user was headed so sign-in returns them
        // there instead of always dropping them on /home.
        ref.read(pendingAuthRedirectProvider.notifier).state =
            state.uri.toString();
        return '/login';
      }
      // Logged-in on /login: redirect away to destination or /home.
      if (isLoggedIn && loggingIn) {
        final pending = ref.read(pendingAuthRedirectProvider);
        ref.read(pendingAuthRedirectProvider.notifier).state = null;
        final target =
            (pending == null || pending == '/login') ? '/home' : pending;
        return target;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: const ValueKey('login-page'),
          opaque: false,
          barrierColor: Colors.transparent,
          barrierDismissible: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) => ProductListScreen(
                  initialAnimalType: state.uri.queryParameters['animalType'],
                  initialCategory: state.uri.queryParameters['category'],
                  initialSearch: state.uri.queryParameters['search'],
                  initialDisease: state.uri.queryParameters['disease'],
                  initialSort: state.uri.queryParameters['sort'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consultations',
                builder: (context, state) => const ConsultationsHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shots',
                builder: (context, state) => ShotsScreen(
                  initialProductId: state.uri.queryParameters['product'],
                  initialShotId: state.uri.queryParameters['shot'],
                  initialAnimal: state.uri.queryParameters['animal'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/diseases',
        builder: (context, state) => const DiseasesScreen(),
      ),
      GoRoute(
        path: '/prescriptions',
        builder: (context, state) => const PrescriptionsScreen(),
      ),
      GoRoute(
        path: '/care-chat',
        redirect: (_, _) => '/consultations',
      ),
      GoRoute(
        path: '/health-concerns',
        redirect: (_, _) => '/diseases',
      ),
      GoRoute(
        path: '/health-concerns/:slug',
        redirect: (context, state) =>
            '/diseases/${state.pathParameters['slug'] ?? ''}',
      ),
      GoRoute(
        path: '/pets',
        builder: (context, state) => const PetsScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) => AppTransitions.fadeSlidePage(
          key: state.pageKey,
          child: ProductDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/products/:id',
        pageBuilder: (context, state) => AppTransitions.fadeSlidePage(
          key: state.pageKey,
          child: ProductDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/combos',
        redirect: (_, _) => '/products?category=Combos',
      ),
      GoRoute(
        path: '/combos/:id',
        pageBuilder: (context, state) => AppTransitions.fadeSlidePage(
          key: state.pageKey,
          child: ComboDetailScreen(comboId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/combo/:id',
        pageBuilder: (context, state) => AppTransitions.fadeSlidePage(
          key: state.pageKey,
          child: ComboDetailScreen(comboId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) => AppTransitions.modalSlidePage(
          key: state.pageKey,
          child: const CartScreen(),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => AppTransitions.fadeSlidePage(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) => AppTransitions.fadeSlidePage(
          key: state.pageKey,
          child: const CheckoutScreen(),
        ),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        pageBuilder: (context, state) => AppTransitions.fadeSlidePage(
          key: state.pageKey,
          child: OrderDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/addresses/new',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/addresses/:id/edit',
        builder: (context, state) =>
            AddressFormScreen(address: state.extra as Address?),
      ),
      GoRoute(
        path: '/pets/new',
        builder: (context, state) => const PetFormScreen(),
      ),
      GoRoute(
        path: '/pets/:id',
        builder: (context, state) =>
            PetDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/consultations/book',
        builder: (context, state) => BookConsultationScreen(
          followUpOfId: state.uri.queryParameters['followUpOf'],
          initialPetProfileId: state.uri.queryParameters['petProfileId'],
          initialAnimalType: state.uri.queryParameters['animalType'],
        ),
      ),
      GoRoute(
        path: '/consultations/:id',
        builder: (context, state) =>
            ConsultationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/blog',
        builder: (context, state) => const BlogListScreen(),
      ),
      GoRoute(
        path: '/blog/:slug',
        builder: (context, state) =>
            BlogDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/diseases/:slug',
        builder: (context, state) =>
            DiseaseDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/vet',
        builder: (context, state) {
          Product? product;
          String? initialQuestion;
          String? animalType;

          if (state.extra is Product) {
            product = state.extra as Product;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            product = map['product'] as Product?;
            initialQuestion = map['question'] as String?;
            animalType = map['animalType'] as String?;
          }

          initialQuestion ??= state.uri.queryParameters['question'] ??
              state.uri.queryParameters['q'];
          animalType ??= state.uri.queryParameters['animalType'];

          return AskDrPawScreen(
            currentProduct: product,
            initialQuestion: initialQuestion,
            animalType: animalType,
          );
        },
      ),
      GoRoute(
        path: '/vet-insights',
        builder: (context, state) => const VetInsightsScreen(),
      ),
      GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/pet-care',
        builder: (context, state) => const PetCareScreen(),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/pincode',
        builder: (context, state) => const PincodeCheckScreen(),
      ),
      GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
      GoRoute(
        path: '/info/:page',
        builder: (context, state) => _infoPage(state.pathParameters['page']!),
      ),
    ],
  );

  router.routerDelegate.addListener(() {
    final uri = router.routerDelegate.currentConfiguration.uri;
    final path = uri.path;
    if (path.isNotEmpty) {
      final pageName = MixpanelService.pageNameForRoute(path);
      AnalyticsService.instance.logScreenView(
        screenName: pageName,
        path: uri.toString(),
      );
    }
  });

  return router;
});

Widget _infoPage(String page) {
  switch (page) {
    case 'shipping':
      return const StaticPageScreen(
        title: 'Shipping & delivery',
        sections: StaticPageScreen.shipping,
      );
    case 'privacy':
      return const StaticPageScreen(
        title: 'Privacy policy',
        sections: StaticPageScreen.privacy,
      );
    case 'terms':
      return const StaticPageScreen(
        title: 'Terms of service',
        sections: StaticPageScreen.terms,
      );
    case 'returns':
      return const StaticPageScreen(
        title: 'Return & cancellation policy',
        sections: StaticPageScreen.returns,
      );
    case 'about':
    default:
      return const StaticPageScreen(
        title: 'About KK Nutrivet',
        sections: StaticPageScreen.about,
      );
  }
}

class GoRouterRefreshAuth extends ChangeNotifier {
  GoRouterRefreshAuth(this.ref) {
    ref.listen(authProvider, (_, next) {
      final user = next.value;
      CrashlyticsService.instance.setUserId(user?.id);
      AnalyticsService.instance.setUserId(user?.id);
      if (user != null) {
        AnalyticsService.instance.setUserProfile(
          name: user.name,
          email: user.email,
        );
      }
      notifyListeners();
    });
    ref.listen(onboardingProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}
