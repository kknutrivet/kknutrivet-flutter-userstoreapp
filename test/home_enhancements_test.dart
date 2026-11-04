import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/screens/home_screen.dart';
import 'package:nvit_app/features/home/widgets/home_animal_selector.dart';
import 'package:nvit_app/features/home/widgets/home_product_rails.dart';
import 'package:nvit_app/features/home/widgets/home_top_bar.dart';
import 'package:nvit_app/models/delivery.dart';
import 'package:nvit_app/models/pet.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final samplePet = PetProfile(
    id: 'pet_1',
    name: 'Bruno',
    animalType: 'Dog',
    breed: 'Golden Retriever',
  );

  final sampleProduct = Product(
    id: 'prod_1',
    name: 'Calf & Cow Mineral Mixture',
    slug: 'calf-cow-mineral',
    price: 349.0,
    mrp: 399.0,
    stock: 50,
  );

  final sampleDelivery = DeliveryInfo(
    pincode: '760001',
    serviceable: true,
    deliveryDays: 2,
    deliveryDaysMax: 3,
    cod: true,
    prepaid: true,
    city: 'Berhampur',
    source: 'local',
    message: 'Available',
  );

  group('Home Enhancements Widget Tests', () {
    testWidgets('HomeTopBarCard renders delivery promise & speed badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings.defaults())),
            deliveryEtaProvider.overrideWith((ref) => Future.value(sampleDelivery)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomeTopBarCard(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Delivering to Berhampur (null)'), findsOneWidget);
      expect(find.text('2-3 days Delivery'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.textContaining('Free delivery on orders over'), findsOneWidget);
    });

    testWidgets('HomeMyPetsBar renders pets and toggles species selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homePetsProvider.overrideWith((ref) => [samplePet]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  return const HomeMyPetsBar();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('My Pets & Animals'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Golden Retriever'), findsOneWidget);
      expect(find.text('Add Pet'), findsOneWidget);

      // Tap on pet Bruno -> selects 'Dog' in selectedHomeAnimalProvider
      await tester.tap(find.text('Bruno'));
      await tester.pump();

      expect(capturedRef.read(selectedHomeAnimalProvider), 'Dog');

      // Tap again -> deselects
      await tester.tap(find.text('Bruno'));
      await tester.pump();

      expect(capturedRef.read(selectedHomeAnimalProvider), isNull);
    });

    testWidgets('HomeMyPetsBar hides when user has no pets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homePetsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomeMyPetsBar(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('My Pets & Animals'), findsNothing);
    });

    testWidgets('HomeReorderRail renders past order products and hides when empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. With products
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('with_products'),
          overrides: [
            recentReorderProductsProvider.overrideWith((ref) => [sampleProduct]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeReorderRail(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Buy Again · Quick Reorder'), findsOneWidget);
      expect(find.text('Calf & Cow Mineral Mixture'), findsOneWidget);

      // 2. Without products -> hides completely
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('empty_products'),
          overrides: [
            recentReorderProductsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeReorderRail(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Buy Again · Quick Reorder'), findsNothing);
    });

    testWidgets('HomeBrandBar renders Dr. Paw AI avatar and Cart action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartCountProvider.overrideWith((ref) => 3),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  HomeBrandBar(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Dr. Paw AI Button with "AI" badge & paw icon
      expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);

      // Shopping Cart Button with count badge "3"
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });
  });
}
