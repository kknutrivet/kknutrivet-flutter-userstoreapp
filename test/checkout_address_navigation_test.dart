import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/checkout/widgets/checkout_address_section.dart';
import 'package:nvit_app/models/address.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleAddress = Address(
    id: 'addr-new-1',
    fullName: 'Ramesh Panda',
    phone: '9876543210',
    fullAddress: 'Plot 42, Green Avenue, Near Forest Gate',
    city: 'Bhubaneswar',
    state: 'Odisha',
    zipCode: '751001',
    isDefault: true,
  );

  group('CheckoutAddressSection Navigation Tests', () {
    testWidgets(
        'tapping Add a delivery address directly opens /addresses/new route',
        (tester) async {
      Address? selected;
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/checkout',
        routes: [
          GoRoute(
            path: '/checkout',
            builder: (context, state) => Scaffold(
              body: CheckoutAddressSection(
                addressesAsync: const AsyncData([]),
                selectedAddressId: null,
                addressExpanded: false,
                onSelectAddress: (addr) => selected = addr,
                onToggleExpanded: () {},
                onDefaultAddressResolved: (addr) {},
              ),
            ),
          ),
          GoRoute(
            path: '/addresses/new',
            builder: (context, state) {
              navigatedRoute = '/addresses/new';
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.pop(sampleAddress),
                  child: const Text('Save Address Mock'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Add a delivery address" button is present
      final addBtnFinder = find.widgetWithText(
        OutlinedButton,
        'Add a delivery address',
      );
      expect(addBtnFinder, findsOneWidget);

      // Tap "Add a delivery address"
      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      // Verify it navigated directly to /addresses/new (NOT /addresses)
      expect(navigatedRoute, '/addresses/new');
      expect(find.text('Save Address Mock'), findsOneWidget);

      // Simulate saving and returning address
      await tester.tap(find.text('Save Address Mock'));
      await tester.pumpAndSettle();

      // Verify the new address was returned and selected
      expect(selected, isNotNull);
      expect(selected!.id, 'addr-new-1');
      expect(selected!.city, 'Bhubaneswar');
    });
  });
}
