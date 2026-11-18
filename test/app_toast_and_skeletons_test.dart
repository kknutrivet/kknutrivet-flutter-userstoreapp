import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/widgets/common.dart';
import 'package:nvit_app/core/widgets/skeletons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('showToast renders styled success and error toasts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        home: const Scaffold(body: Center(child: Text('Host'))),
      ),
    );

    showToast('Added to cart');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Added to cart'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    showToast('Payment failed', isError: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Payment failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);

    var undone = false;
    showToast(
      'Removed item',
      type: AppToastType.info,
      actionLabel: 'Undo',
      onAction: () => undone = true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, isTrue);
  });

  testWidgets('shimmer skeletons render cleanly without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 360, child: ProductDetailSkeleton()),
                SizedBox(height: 360, child: ComboDetailSkeleton()),
                SizedBox(height: 360, child: OrderListSkeleton()),
                SizedBox(height: 360, child: ListCardSkeleton()),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ProductDetailSkeleton), findsOneWidget);
    expect(find.byType(ComboDetailSkeleton), findsOneWidget);
    expect(find.byType(OrderListSkeleton), findsOneWidget);
    expect(find.byType(ListCardSkeleton), findsOneWidget);
  });

  testWidgets('OfflineBannerWrapper shows offline pill when disconnected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOfflineProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MaterialApp(
          home: OfflineBannerWrapper(
            child: Scaffold(body: Center(child: Text('Body'))),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('No internet — showing cached data'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('AppErrorFallbackCard renders branded fallback UI', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppErrorFallbackCard()));
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
