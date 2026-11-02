import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/theme/app_theme.dart';
import 'package:nvit_app/core/widgets/app_button.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Readable card and accessible primary action at 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final product = Product(id: 'sample', slug: 'sample', name: 'Daily nutrition supplement for dogs', price: 399, mrp: 499,
      requiresPrescription: true, variants: [ProductVariant(id: 'pack', name: '100 g', price: 399, mrp: 499, stock: 10)]);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: AppTheme.light, home: RepaintBoundary(key: key,
      child: Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Care for every companion', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), const Text('Customer app · component preview'), const SizedBox(height: 24),
        SizedBox(width: 180, height: 400, child: CompactProductCard(product: product)),
        const SizedBox(height: 20), AppButton(label: 'Continue shopping', size: AppButtonSize.sm, onPressed: () {}),
      ])))),
    ))));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AppButton)).height, greaterThanOrEqualTo(48));
    expect(find.text('Rx required'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
