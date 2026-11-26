import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nvit_app/core/i18n/app_language.dart';
import 'package:nvit_app/core/i18n/app_strings.dart';
import 'package:nvit_app/core/widgets/language_switcher.dart';
import 'package:nvit_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('5-language AppStrings & AppLocale parity', () {
    test('all 5 supported locales have complete non-empty UI strings', () {
      expect(AppLocale.values.map((l) => l.code).toList(), [
        'en',
        'hi',
        'or',
        'te',
        'ta',
      ]);

      for (final locale in AppLocale.values) {
        final s = AppStrings.of(locale);
        expect(s.navHome.isNotEmpty, true);
        expect(s.navShop.isNotEmpty, true);
        expect(s.navCare.isNotEmpty, true);
        expect(s.navShots.isNotEmpty, true);
        expect(s.navAccount.isNotEmpty, true);
        expect(s.cart.isNotEmpty, true);
        expect(s.paymentMethod.isNotEmpty, true);
        expect(s.myAccount.isNotEmpty, true);
      }
    });

    test('Product parses translations JSON and falls back cleanly to English', () {
      final product = Product.fromJson({
        'id': 'p-1',
        'name': 'Calci-Boost 1L',
        'slug': 'calci-boost-1l',
        'description': 'Liquid calcium supplement',
        'price': 320,
        'translations': {
          'hi': {
            'name': 'कैल्सी-बूस्ट 1 लीटर',
            'description': 'तरल कैल्शियम सप्लीमेंट',
          },
          'or': {'name': 'କ୍ୟାଲସି-ବୁଷ୍ଟ 1 ଲିଟର'},
        },
      });

      expect(product.localizedName('en'), 'Calci-Boost 1L');
      expect(product.localizedName('hi'), 'कैल्सी-बूस्ट 1 लीटर');
      expect(product.localizedName('or'), 'କ୍ୟାଲସି-ବୁଷ୍ଟ 1 ଲିଟର');
      expect(product.localizedName('ta'), 'Calci-Boost 1L'); // graceful fallback
      expect(product.localizedDescription('hi'), 'तरल कैल्शियम सप्लीमेंट');
      expect(product.localizedDescription('or'), 'Liquid calcium supplement');
    });

    test('LanguageNotifier persists selected locale to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(languageProvider), AppLocale.en);
      await container.read(languageProvider.notifier).setLocale(AppLocale.hi);
      expect(container.read(languageProvider), AppLocale.hi);
      expect(container.read(appStringsProvider).cart, 'कार्ट');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLocaleStorageKey), 'hi');
    });
  });

  testWidgets('LanguageSwitcher opens 5-language sheet and switches locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: LanguageSwitcher(compact: true)),
          ),
        ),
      ),
    );

    expect(find.text('EN'), findsOneWidget);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('हिंदी'), findsOneWidget);
    expect(find.text('ଓଡ଼ିଆ'), findsOneWidget);
    expect(find.text('తెలుగు'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);

    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();

    expect(find.text('हिंदी'), findsOneWidget);
  });
}
