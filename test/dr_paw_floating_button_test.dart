import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/widgets/dr_paw_floating_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('DrPawFloatingButton Widget Tests', () {
    testWidgets('renders Dr. Paw floating button with avatar and AI badge', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: DrPawFloatingButton(),
          ),
        ),
      );

      // Verify widget exists
      expect(find.byType(DrPawFloatingButton), findsOneWidget);

      // Verify AI badge exists
      expect(find.text('AI'), findsOneWidget);

      // Verify accessibility semantics
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Ask Dr. Paw AI veterinary assistant',
        ),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('animates breathing pulse smoothly over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: DrPawFloatingButton(),
          ),
        ),
      );

      expect(find.byType(DrPawFloatingButton), findsOneWidget);

      // Advance clock by 500ms
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(DrPawFloatingButton), findsOneWidget);

      // Advance clock by 1000ms
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(DrPawFloatingButton), findsOneWidget);
    });
  });
}
