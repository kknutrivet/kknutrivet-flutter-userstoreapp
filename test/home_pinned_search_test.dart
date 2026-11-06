import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/widgets/home_top_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('search bar stays pinned under the app bar after scrolling',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const HomeBrandBar(),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
                const HomePinnedSearchBar(),
                SliverList.builder(
                  itemCount: 40,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 80, child: Text('Row $i')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final searchText = find.text('Search products');
    expect(searchText, findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();

    // Still on screen, sitting right under the 56dp brand bar.
    expect(searchText, findsOneWidget);
    final top = tester.getTopLeft(find.byType(HomeSearchField)).dy;
    expect(top, greaterThanOrEqualTo(48));
    expect(top, lessThan(56 + 62));
  });
}
