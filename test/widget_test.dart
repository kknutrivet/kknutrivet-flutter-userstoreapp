import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nvit_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('KkNutrivetApp root widget instantiates cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KkNutrivetApp(),
      ),
    );

    // Pump past the 700ms splash screen timer
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byType(KkNutrivetApp), findsOneWidget);
  });
}
