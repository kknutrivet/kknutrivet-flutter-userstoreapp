import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/features/home/widgets/home_animal_selector.dart';
import 'package:nvit_app/features/home/widgets/home_models_and_data.dart';
import 'package:nvit_app/features/products/widgets/catalogue_controls.dart';
import 'package:nvit_app/features/products/widgets/catalogue_sheets.dart';
import 'package:nvit_app/models/category.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/providers/catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductCategory Model Tests', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'cat_1',
        'name': 'Grooming',
        'slug': 'grooming',
        'image': '/images/grooming.png',
        'description': 'Shampoos and brushes',
        'sortOrder': 2,
        'active': true,
      };

      final cat = ProductCategory.fromJson(json);
      expect(cat.id, 'cat_1');
      expect(cat.name, 'Grooming');
      expect(cat.slug, 'grooming');
      expect(cat.image, '/images/grooming.png');
      expect(cat.description, 'Shampoos and brushes');
      expect(cat.sortOrder, 2);
      expect(cat.active, isTrue);
    });

    test('handles inactive category flag', () {
      final json = {
        'id': 'cat_2',
        'name': 'Deprecated Category',
        'slug': 'deprecated',
        'active': false,
      };

      final cat = ProductCategory.fromJson(json);
      expect(cat.name, 'Deprecated Category');
      expect(cat.active, isFalse);
    });

    test('parses parentId and computes isSubcategory correctly', () {
      final parentJson = {
        'id': 'parent_home_care',
        'name': 'Home Care',
        'slug': 'home-care',
        'active': true,
      };
      final subJson = {
        'id': 'sub_cleaners',
        'name': 'Floor Cleaners & Disinfectants',
        'slug': 'floor-cleaners-disinfectants',
        'parentId': 'parent_home_care',
        'active': true,
      };

      final parentCat = ProductCategory.fromJson(parentJson);
      final subCat = ProductCategory.fromJson(subJson);

      expect(parentCat.isSubcategory, isFalse);
      expect(parentCat.parentId, isNull);
      expect(subCat.isSubcategory, isTrue);
      expect(subCat.parentId, 'parent_home_care');
    });
  });

  group('CatalogService fetchCategories Tests', () {
    test('fetches and filters active categories', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(Response(
              requestOptions: options,
              data: [
                {'id': '1', 'name': 'Medicine', 'slug': 'medicine', 'active': true},
                {'id': '2', 'name': 'Disabled Cat', 'slug': 'disabled-cat', 'active': false},
                {'id': '3', 'name': 'Feed', 'slug': 'feed', 'active': true},
              ],
              statusCode: 200,
            ));
          },
        ),
      );

      final client = ApiClient.withDio(dio);
      final service = CatalogService(client);
      final categories = await service.fetchCategories();

      expect(categories.length, 2);
      expect(categories.map((c) => c.name), containsAll(['Medicine', 'Feed']));
      expect(categories.map((c) => c.name), isNot(contains('Disabled Cat')));
    });
  });

  group('activeCategoriesProvider & Disabled Category Tests', () {
    test('omits disabled categories and storeSettings.hiddenCategories', () async {
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Future.value([
                const ProductCategory(id: '1', name: 'Medicine', slug: 'med', active: true),
                const ProductCategory(id: '2', name: 'Deworming', slug: 'deworm', active: true),
                const ProductCategory(id: '3', name: 'Grooming', slug: 'groom', active: false),
                const ProductCategory(id: '4', name: 'Feed', slug: 'feed', active: true),
              ])),
          storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                freeDeliveryThreshold: 500,
                deliveryCharge: 49,
                hiddenCategories: ['Deworming'],
              ))),
        ],
      );
      addTearDown(container.dispose);

      await container.read(categoriesProvider.future);
      await container.read(storeSettingsProvider.future);
      final active = container.read(activeCategoriesProvider);
      // 'Medicine' and 'Feed' should remain
      expect(active, containsAll(['Medicine', 'Feed']));
      // 'Grooming' was active: false in DB
      expect(active, isNot(contains('Grooming')));
      // 'Deworming' was hidden in storeSettings
      expect(active, isNot(contains('Deworming')));
    });

    testWidgets('CatalogueFilterSheet omits disabled category from filter choices', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Future.value([
                const ProductCategory(id: '1', name: 'Medicine', slug: 'med', active: true),
                const ProductCategory(id: '2', name: 'Feed', slug: 'feed', active: true),
                // Grooming and Deworming are disabled
              ])),
          storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                freeDeliveryThreshold: 500,
                deliveryCharge: 49,
                hiddenCategories: const [],
              ))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CatalogueFilterSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Medicine and Feed should be present
      expect(find.text('Medicine'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);

      // Grooming and Deworming should NOT be present because they are disabled in the DB
      expect(find.text('Grooming'), findsNothing);
      expect(find.text('Deworming'), findsNothing);
    });

    testWidgets('HomeShopByNeedChips omits chips whose category is disabled', (tester) async {
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Future.value([
                const ProductCategory(id: '1', name: 'Feed', slug: 'feed', active: true),
                // Deworming, Medicine, and Grooming are disabled
              ])),
          storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                freeDeliveryThreshold: 500,
                deliveryCharge: 49,
              ))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HomeShopByNeedChips(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 'Feed' has category: 'Feed', which is active -> visible
      expect(find.text('Feed'), findsOneWidget);

      // 'Deworming' has category: 'Deworming', which is disabled -> omitted!
      expect(find.text('Deworming'), findsNothing);

      // 'Medicines' has category: 'Medicine', which is disabled -> omitted!
      expect(find.text('Medicines'), findsNothing);

      // 'Grooming & Care' has category: 'Grooming', which is disabled -> omitted!
      expect(find.text('Grooming & Care'), findsNothing);
    });

    testWidgets('HomeShopByNeedChips dynamically appends new active category from backend', (tester) async {
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Future.value([
                const ProductCategory(id: '1', name: 'Feed', slug: 'feed', active: true),
                const ProductCategory(id: '99', name: 'Ayurvedic', slug: 'ayurvedic', active: true),
              ])),
          storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                freeDeliveryThreshold: 500,
                deliveryCharge: 49,
              ))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HomeShopByNeedChips(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Newly added 'Ayurvedic' category chip appears dynamically
      expect(find.text('Ayurvedic'), findsOneWidget);
    });

    testWidgets('disabling Poultry via hiddenCategories hides Poultry from selector and rail', (tester) async {
      final container = ProviderContainer(
        overrides: [
          storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                freeDeliveryThreshold: 500,
                deliveryCharge: 49,
                hiddenCategories: ['Poultry'],
              ))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const HomeAnimalSelector(),
                    HomeAnimalProductRail(entry: kHomeAnimals[4]), // Poultry
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dogs, Cats, Cattle should be visible
      expect(find.text('Shop for Dogs'), findsNothing); // text is in semantic label
      expect(find.text('Dogs'), findsOneWidget);
      expect(find.text('Cats'), findsOneWidget);
      expect(find.text('Cattle'), findsOneWidget);

      // Poultry should NOT be visible anywhere
      expect(find.text('Poultry'), findsNothing);
      expect(find.text('Poultry care you can count on'), findsNothing);
    });
  });

  group('Subcategory and Product Filtering Tests', () {
    test('Product.fromJson parses subCategory correctly', () {
      final json = {
        'id': 'prod_1',
        'name': 'Enzyme Floor Cleaner',
        'slug': 'enzyme-floor-cleaner',
        'price': 299.0,
        'category': 'Home Care',
        'subCategory': 'Floor Cleaners & Disinfectants',
      };
      final product = Product.fromJson(json);
      expect(product.category, 'Home Care');
      expect(product.subCategory, 'Floor Cleaners & Disinfectants');
    });

    test('activeCategoriesProvider excludes subcategories from top-level list', () async {
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Future.value([
                const ProductCategory(id: '1', name: 'Home Care', slug: 'home-care', active: true),
                const ProductCategory(
                  id: '2',
                  name: 'Floor Cleaners & Disinfectants',
                  slug: 'floor-cleaners',
                  parentId: '1',
                  active: true,
                ),
                const ProductCategory(id: '3', name: 'Grooming', slug: 'grooming', active: true),
              ])),
          storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                freeDeliveryThreshold: 500,
                deliveryCharge: 49,
              ))),
        ],
      );
      addTearDown(container.dispose);

      await container.read(categoriesProvider.future);
      final active = container.read(activeCategoriesProvider);

      // Top-level categories should be present
      expect(active, containsAll(['Home Care', 'Grooming']));
      // Subcategories should NOT pollute top-level categories list
      expect(active, isNot(contains('Floor Cleaners & Disinfectants')));
    });

    test('ProductFilter copyWith handles subCategory and category clearing', () {
      final initial = ProductFilter(
        category: 'Home Care',
        subCategory: 'Floor Cleaners & Disinfectants',
      );
      expect(initial.hasAny, isTrue);
      expect(initial.activeCount, 2);

      // Clearing subcategory specifically
      final clearedSub = initial.copyWith(clearSubCategory: true);
      expect(clearedSub.category, 'Home Care');
      expect(clearedSub.subCategory, isNull);
      expect(clearedSub.activeCount, 1);

      // Clearing category also clears subcategory
      final clearedCat = initial.copyWith(clearCategory: true);
      expect(clearedCat.category, isNull);
      expect(clearedCat.subCategory, isNull);
    });

    test('applyClientProductFilters filters by subCategory properly', () {
      final p1 = Product(
        id: '1',
        name: 'Cleaner 1',
        slug: 'cleaner-1',
        price: 100,
        category: 'Home Care',
        subCategory: 'Floor Cleaners & Disinfectants',
      );
      final p2 = Product(
        id: '2',
        name: 'Stain Spray',
        slug: 'stain-spray',
        price: 150,
        category: 'Home Care',
        subCategory: 'Stain & Odor Removers',
      );
      final p3 = Product(
        id: '3',
        name: 'General Product',
        slug: 'general-product',
        price: 200,
        category: 'Home Care',
        subCategory: null,
      );

      final filterCleaners = ProductFilter(
        category: 'Home Care',
        subCategory: 'Floor Cleaners & Disinfectants',
      );
      final results = applyClientProductFilters([p1, p2, p3], filterCleaners);
      expect(results.length, 1);
      expect(results.first.id, '1');

      final filterGeneralHomeCare = ProductFilter(
        category: 'Home Care',
      );
      final allHomeCare = applyClientProductFilters([p1, p2, p3], filterGeneralHomeCare);
      expect(allHomeCare.length, 3);
    });

    testWidgets('CatalogueFilterSheet renders subcategories when parent category selected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => Future.value([
                const ProductCategory(id: '1', name: 'Home Care', slug: 'home-care', active: true),
                const ProductCategory(
                  id: '10',
                  name: 'Floor Cleaners & Disinfectants',
                  slug: 'floor-cleaners',
                  parentId: '1',
                  active: true,
                ),
              ])),
          storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                freeDeliveryThreshold: 500,
                deliveryCharge: 49,
              ))),
          productFilterProvider.overrideWith((ref) => ProductFilter(category: 'Home Care')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CatalogueFilterSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Parent category is displayed
      expect(find.text('Home Care'), findsOneWidget);
      // Subcategory is rendered indented under Home Care
      expect(find.text('↳ Floor Cleaners & Disinfectants'), findsOneWidget);
    });
  });
}
