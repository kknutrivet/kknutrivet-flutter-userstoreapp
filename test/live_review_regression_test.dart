import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/theme/app_theme.dart';
import 'package:nvit_app/core/utils/order_status.dart';
import 'package:nvit_app/features/blog/screens/blog_detail_screen.dart';
import 'package:nvit_app/features/calculator/screens/calculator_screen.dart';

void main() {
  test('courier identifiers become readable labels', () {
    expect(
      courierStatusLabel('bag_received_at_via'),
      'Arrived at transit facility',
    );
    expect(courierStatusLabel('NEW_TRANSIT_EVENT'), 'New Transit Event');
  });
  test('article title is deduplicated without removing unrelated content', () {
    expect(
      articleBodyWithoutDuplicateTitle('# Care guide\n\nBody', 'Care guide'),
      'Body',
    );
    expect(
      articleBodyWithoutDuplicateTitle(
        '## Different heading\nBody',
        'Care guide',
      ),
      '## Different heading\nBody',
    );
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('meal controls fit a $width phone and remain selectable', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const CalculatorScreen()),
      );
      await tester.ensureVisible(find.text('3 meals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 meals'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '3 meals'))
            .selected,
        isTrue,
      );
    });
  }
}
