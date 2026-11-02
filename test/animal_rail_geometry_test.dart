import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/products/widgets/catalogue_controls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
      'CatalogueHorizontalAnimalRail selected icon is completely inside the selection box with clean vertical clearance',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productFilterProvider.overrideWith(
            (ref) => ProductFilter(animalType: 'Dog'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CatalogueHorizontalAnimalRail(),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 'Dogs' selection box
    final containerFinder = find.byType(AnimatedContainer).at(1);
    final containerRect = tester.getRect(containerFinder);

    // Verify Dog avatar
    final imageFinder = find.byType(Image).first;
    final imageRect = tester.getRect(imageFinder);

    // Verify avatar is inside the selection container with healthy clearance (> 5px)
    expect(imageRect.top, greaterThan(containerRect.top + 5.0));
    expect(imageRect.bottom, lessThan(containerRect.bottom - 15.0)); // Text is below it
    expect(imageRect.left, greaterThan(containerRect.left));
    expect(imageRect.right, lessThan(containerRect.right));

    // Verify text label is also inside
    final textFinder = find.text('Dogs');
    final textRect = tester.getRect(textFinder);
    expect(textRect.bottom, lessThanOrEqualTo(containerRect.bottom));
    expect(textRect.top, greaterThan(imageRect.bottom));
  });
}
