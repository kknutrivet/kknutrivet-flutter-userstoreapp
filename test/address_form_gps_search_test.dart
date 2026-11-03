import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/theme/app_theme.dart';
import 'package:nvit_app/core/widgets/app_button.dart';
import 'package:nvit_app/features/addresses/screens/address_form_screen.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(this._user);
  final AppUser? _user;

  @override
  Future<AppUser?> build() async => _user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('AddressFormScreen renders Quick GPS & Search Location controls',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => MockAuthNotifier(
              AppUser(
                id: 'u-1',
                email: 'saroj@example.com',
                name: 'Saroj Panigrahy',
                phone: '9876543210',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AddressFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Quick Address Fill section
    expect(find.text('Quick Address Fill'), findsOneWidget);
    expect(find.text('Use Current GPS'), findsOneWidget);
    expect(find.text('Search Location'), findsOneWidget);

    // Verify Address Type chips
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Farm'), findsOneWidget);
    expect(find.text('Clinic'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    // Verify user pre-filled fields
    expect(find.text('Saroj Panigrahy'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);

    // Verify House / Flat / Building No field
    expect(
      find.widgetWithText(
        TextFormField,
        'House / Flat / Building / Apartment No. *',
      ),
      findsOneWidget,
    );

    // Verify Save button is anchored in bottomNavigationBar and bounded in height
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNotNull);
    final buttonFinder = find.descendant(
      of: find.byWidget(scaffold.bottomNavigationBar!),
      matching: find.text('Save Delivery Address'),
    );
    expect(buttonFinder, findsOneWidget);

    final buttonSize = tester.getSize(find.byType(AppButton));
    expect(buttonSize.height, lessThanOrEqualTo(56.0));
    expect(buttonSize.height, greaterThanOrEqualTo(48.0));

    // Verify AppBar and Quick Address Fill are visible on screen simultaneously
    expect(find.text('Add Delivery Address'), findsOneWidget);
    expect(find.text('Quick Address Fill'), findsOneWidget);

    // Verify button check icon renders with white color
    final iconFinder = find.byIcon(Icons.check_rounded);
    expect(iconFinder, findsOneWidget);
    final iconTheme = tester.widget<IconTheme>(
      find.ancestor(of: iconFinder, matching: find.byType(IconTheme)).first,
    );
    expect(iconTheme.data.color, equals(Colors.white));
  });
}
