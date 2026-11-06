/// Every route in `lib/core/router/app_router.dart`.
///
/// Shared by the route-coverage tests and the visual-regression suite so a new
/// screen automatically gets a render check and a screenshot slot.
library;

class AppRoute {
  const AppRoute({
    required this.path,
    required this.location,
    required this.name,
    required this.title,
    this.snapshot = true,
  });

  /// URL to navigate to, including query parameters.
  final String path;

  /// `GoRouter` matched location after redirects.
  final String location;

  /// Stable slug used for the golden filename (`<name>.png`).
  final String name;

  /// Human label shown in the visual gallery.
  final String title;

  /// Whether the visual suite should capture this route. Redirect-only aliases
  /// are still covered by the route test but would just duplicate a screen.
  final bool snapshot;
}

const List<AppRoute> appRoutes = [
  AppRoute(path: '/home', location: '/home', name: 'home', title: 'Home'),
  AppRoute(
    path: '/products',
    location: '/products',
    name: 'products',
    title: 'Product catalogue',
  ),
  AppRoute(
    path: '/products?animalType=Dog&category=Spray&search=calm&sort=price',
    location: '/products',
    name: 'products_filtered',
    title: 'Catalogue with filters',
  ),
  AppRoute(
    path: '/product/prod-granliv',
    location: '/product/prod-granliv',
    name: 'product_detail',
    title: 'Product detail',
  ),
  AppRoute(
    path: '/products/prod-granliv',
    location: '/products/prod-granliv',
    name: 'products_alias',
    title: 'Product detail (alias)',
    snapshot: false,
  ),
  AppRoute(
    path: '/combos',
    location: '/products',
    name: 'combos',
    title: 'Combos',
    snapshot: false,
  ),
  AppRoute(
    path: '/combos/combo-liv-deworm',
    location: '/combos/combo-liv-deworm',
    name: 'combo_detail',
    title: 'Combo detail',
  ),
  AppRoute(
    path: '/combo/combo-liv-deworm',
    location: '/combo/combo-liv-deworm',
    name: 'combo_detail_alias',
    title: 'Combo detail (alias)',
    snapshot: false,
  ),
  AppRoute(path: '/cart', location: '/cart', name: 'cart', title: 'Cart'),
  AppRoute(
    path: '/search',
    location: '/search',
    name: 'search',
    title: 'Search',
  ),
  AppRoute(
    path: '/wishlist',
    location: '/wishlist',
    name: 'wishlist',
    title: 'Wishlist',
  ),
  AppRoute(
    path: '/checkout',
    location: '/checkout',
    name: 'checkout',
    title: 'Checkout',
  ),
  AppRoute(
    path: '/orders',
    location: '/orders',
    name: 'orders',
    title: 'Orders',
  ),
  AppRoute(
    path: '/order/order-1',
    location: '/order/order-1',
    name: 'order_detail',
    title: 'Order detail',
  ),
  AppRoute(
    path: '/addresses',
    location: '/addresses',
    name: 'addresses',
    title: 'Saved addresses',
  ),
  AppRoute(
    path: '/addresses/new',
    location: '/addresses/new',
    name: 'address_new',
    title: 'Add address',
  ),
  AppRoute(
    path: '/addresses/addr-1/edit',
    location: '/addresses/addr-1/edit',
    name: 'address_edit',
    title: 'Edit address',
  ),
  AppRoute(
    path: '/consultations',
    location: '/consultations',
    name: 'consultations',
    title: 'Consultations',
  ),
  AppRoute(
    path: '/consultations/book',
    location: '/consultations/book',
    name: 'consultation_book',
    title: 'Book consultation',
  ),
  AppRoute(
    path: '/consultations/booking-1',
    location: '/consultations/booking-1',
    name: 'consultation_detail',
    title: 'Consultation',
  ),
  AppRoute(
    path: '/shots',
    location: '/shots',
    name: 'shots',
    title: 'Shots',
  ),
  AppRoute(
    path: '/shots?product=prod-granliv&shot=shot-1&animal=Dog',
    location: '/shots',
    name: 'shots_product',
    title: 'Shots for a product',
  ),
  AppRoute(
    path: '/profile',
    location: '/profile',
    name: 'profile',
    title: 'Profile',
  ),
  AppRoute(
    path: '/diseases',
    location: '/diseases',
    name: 'diseases',
    title: 'Health concerns',
  ),
  AppRoute(
    path: '/diseases/skin-and-coat',
    location: '/diseases/skin-and-coat',
    name: 'disease_detail',
    title: 'Condition detail',
  ),
  AppRoute(
    path: '/prescriptions',
    location: '/prescriptions',
    name: 'prescriptions',
    title: 'Prescriptions',
  ),
  AppRoute(
    path: '/care-chat',
    location: '/consultations',
    name: 'care_chat',
    title: 'Care chat',
    snapshot: false,
  ),
  AppRoute(
    path: '/health-concerns',
    location: '/diseases',
    name: 'health_concerns',
    title: 'Health concerns (alias)',
    snapshot: false,
  ),
  AppRoute(
    path: '/health-concerns/skin-and-coat',
    location: '/diseases/skin-and-coat',
    name: 'health_concern_detail',
    title: 'Condition detail (alias)',
    snapshot: false,
  ),
  AppRoute(path: '/pets', location: '/pets', name: 'pets', title: 'Pets'),
  AppRoute(
    path: '/pets/new',
    location: '/pets/new',
    name: 'pet_new',
    title: 'Add pet',
  ),
  AppRoute(
    path: '/pets/pet-1',
    location: '/pets/pet-1',
    name: 'pet_detail',
    title: 'Pet detail',
  ),
  AppRoute(path: '/blog', location: '/blog', name: 'blog', title: 'Blog'),
  AppRoute(
    path: '/blog/pet-nutrition-basics',
    location: '/blog/pet-nutrition-basics',
    name: 'blog_detail',
    title: 'Blog article',
  ),
  AppRoute(path: '/vet', location: '/vet', name: 'vet', title: 'Ask Dr. Paw'),
  AppRoute(
    path: '/vet?question=food&animalType=Dog',
    location: '/vet',
    name: 'vet_question',
    title: 'Ask Dr. Paw with a question',
  ),
  AppRoute(
    path: '/vet-insights',
    location: '/vet-insights',
    name: 'vet_insights',
    title: 'Vet insights',
  ),
  AppRoute(
    path: '/scan',
    location: '/scan',
    name: 'scan',
    title: 'Prescription scanner',
  ),
  AppRoute(
    path: '/referral',
    location: '/referral',
    name: 'referral',
    title: 'Referral',
  ),
  AppRoute(
    path: '/pet-care',
    location: '/pet-care',
    name: 'pet_care',
    title: 'Pet care',
  ),
  AppRoute(
    path: '/calculator',
    location: '/calculator',
    name: 'calculator',
    title: 'Nutrition calculator',
  ),
  AppRoute(
    path: '/pincode',
    location: '/pincode',
    name: 'pincode',
    title: 'Pincode check',
  ),
  AppRoute(path: '/help', location: '/help', name: 'help', title: 'Help'),
  AppRoute(
    path: '/info/about',
    location: '/info/about',
    name: 'info_about',
    title: 'About us',
  ),
  AppRoute(
    path: '/info/shipping',
    location: '/info/shipping',
    name: 'info_shipping',
    title: 'Shipping & delivery',
  ),
  AppRoute(
    path: '/info/privacy',
    location: '/info/privacy',
    name: 'info_privacy',
    title: 'Privacy policy',
  ),
  AppRoute(
    path: '/info/terms',
    location: '/info/terms',
    name: 'info_terms',
    title: 'Terms of service',
  ),
  AppRoute(
    path: '/info/returns',
    location: '/info/returns',
    name: 'info_returns',
    title: 'Returns policy',
  ),
  AppRoute(
    path: '/onboarding',
    location: '/onboarding',
    name: 'onboarding',
    title: 'Onboarding',
  ),
  AppRoute(
    path: '/update',
    location: '/home',
    name: 'update',
    title: 'Force update',
    snapshot: false,
  ),
];
