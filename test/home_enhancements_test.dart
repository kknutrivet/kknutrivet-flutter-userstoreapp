import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/screens/home_screen.dart';
import 'package:nvit_app/features/home/widgets/home_animal_selector.dart';
import 'package:nvit_app/features/home/widgets/home_care_bento.dart';
import 'package:nvit_app/features/home/widgets/home_product_rails.dart';
import 'package:nvit_app/features/home/widgets/home_top_bar.dart';
import 'package:nvit_app/models/address.dart';
import 'package:nvit_app/models/delivery.dart';
import 'package:nvit_app/models/pet.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._user);
  final AppUser? _user;

  @override
  Future<AppUser?> build() async => _user;
}

class _MockPincodeNotifier extends DeliveryPincodeNotifier {
  _MockPincodeNotifier(this._pin);
  final String? _pin;

  @override
  Future<String?> build() async => _pin;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final samplePet = PetProfile(    id: 'pet_1',
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
    testWidgets('HomeTopBarCard renders delivery promise & speed badge', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeSettingsProvider.overrideWith(
              (ref) => Future.value(StoreSettings.defaults()),
            ),
            deliveryPincodeProvider.overrideWith(
              () => _MockPincodeNotifier('760001'),
            ),
            deliveryEtaProvider.overrideWith(
              (ref) => Future.value(sampleDelivery),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomeTopBarCard(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Berhampur · 760001'), findsOneWidget);
      expect(find.text('· 5-7 days'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Free delivery ₹500+'), findsOneWidget);
    });

    testWidgets(
      'HomeTopBarCard formats uppercase city without cutting and lets logged-in user switch between multiple saved addresses, carrying selection to checkout',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final hydAddress = Address(
          id: 'addr_hyd',
          label: 'Home',
          fullName: 'Saroj Panigrahy',
          phone: '9876543210',
          fullAddress: 'Gachibowli',
          city: 'HYDERABAD',
          state: 'Telangana',
          zipCode: '500081',
          isDefault: true,
        );
        final bmpAddress = Address(
          id: 'addr_bmp',
          label: 'Office',
          fullName: 'Saroj Panigrahy',
          phone: '9876543210',
          fullAddress: 'Bapuji Nagar',
          city: 'BERHAMPUR',
          state: 'Odisha',
          zipCode: '760004',
        );

        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              () => _MockAuthNotifier(
                AppUser(id: 'u1', email: 's@test.com', name: 'Saroj'),
              ),
            ),
            addressesProvider.overrideWith(
              (ref) => Future.value([hydAddress, bmpAddress]),
            ),
            storeSettingsProvider.overrideWith(
              (ref) => Future.value(StoreSettings.defaults()),
            ),
            deliveryPincodeProvider.overrideWith(
              () => _MockPincodeNotifier('500081'),
            ),
            deliveryEtaProvider.overrideWith(
              (ref) => Future.value(
                DeliveryInfo(
                  pincode: '500081',
                  serviceable: true,
                  deliveryDays: 2,
                  deliveryDaysMax: 3,
                  cod: true,
                  prepaid: true,
                  city: 'HYDERABAD',
                  source: 'nimbus',
                  message: 'Available',
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: HomeTopBarCard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // City is title-cased ("Hyderabad") and matches the saved address label ("Home: Hyderabad · 500081")
        expect(find.text('Home: Hyderabad · 500081'), findsOneWidget);

        // Tap the delivery pill to open the address selector bottom sheet
        await tester.tap(find.byIcon(Icons.location_on_outlined));
        await tester.pumpAndSettle();

        expect(find.text('SAVED ADDRESSES (2)'), findsOneWidget);
        expect(find.text('Home · Saroj Panigrahy'), findsOneWidget);
        expect(find.text('Office · Saroj Panigrahy'), findsOneWidget);

        // Select the second address ("Office · Saroj Panigrahy")
        await tester.tap(find.text('Office · Saroj Panigrahy'));
        await tester.pumpAndSettle();

        // Verify the selection is stored in selectedDeliveryAddressIdProvider (which CheckoutScreen reads)
        expect(container.read(selectedDeliveryAddressIdProvider), 'addr_bmp');
        expect(find.text('Office: Berhampur · 760004'), findsOneWidget);
      },
    );

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

      expect(find.text('Order again in 1 tap'), findsOneWidget);
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

      expect(find.text('Order again in 1 tap'), findsNothing);
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

      // Dr. Paw AI Button with Paw Icon & "AI" badge
      expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);

      // Shopping Cart Button with count badge "3"
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets(
      'HomeEditorialHeroBanner, HomeCareBentoSection, and HomeBrandSignatureFooter render cleanly without overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      HomeEditorialHeroBanner(),
                      HomeCareBentoSection(),
                      HomeBrandSignatureFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Care in spotlight'), findsOneWidget);
        expect(find.text('Ask\nDr. Paw'), findsOneWidget);
        expect(find.text('Order\nwith Rx'), findsOneWidget);
        expect(find.text('Peak Milk\nStore'), findsOneWidget);
        expect(find.text('Tick & Worm\nShield'), findsOneWidget);
        expect(find.textContaining('INDIA’S ANIMAL'), findsOneWidget);
      },
    );
  });
}
