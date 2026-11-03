import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:nvit_app/core/widgets/lottie_nav_icon.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lottie Nav Assets Validity Tests', () {
    const assets = [
      'assets/lottie/nav_home.json',
      'assets/lottie/nav_shop.json',
      'assets/lottie/nav_consult.json',
      'assets/lottie/nav_health.json',
      'assets/lottie/nav_account.json',
      'assets/lottie/nav_pets.json',
    ];

    for (final path in assets) {
      test('parses $path successfully as valid Lottie composition', () async {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path must exist on disk');
        final bytes = await file.readAsBytes();
        final composition = await LottieComposition.fromBytes(bytes);
        expect(composition, isNotNull);
        expect(composition.duration, greaterThan(Duration.zero));
        expect(composition.bounds.width, greaterThan(0));
        expect(composition.bounds.height, greaterThan(0));
      });
    }
  });

  group('WebsiteBottomNav Lottie Integration Tests', () {
    testWidgets('renders all 5 navigation tabs with LottieNavIcon widgets',
        (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WebsiteBottomNav(
              currentIndex: 0,
              onTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );

      // Verify labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Care'), findsOneWidget);
      expect(find.text('Shots'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Verify 5 LottieNavIcon widgets are rendered (4 standard + 1 raised consult)
      expect(find.byType(LottieNavIcon), findsNWidgets(5));

      // Tap 'Shop' tab
      await tester.tap(find.text('Shop'));
      await tester.pump();
      expect(tappedIndex, 1);

      // Tap 'Consult' floating button
      await tester.tap(find.bySemanticsLabel('Care team chat').first);
      await tester.pump();
      expect(tappedIndex, 2);

      // Tap 'Shots' tab
      await tester.tap(find.text('Shots'));
      await tester.pump();
      expect(tappedIndex, 3);
    });

    testWidgets('renders Account tab with user name when logged in',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WebsiteBottomNav(
              currentIndex: 4,
              userFirstName: 'Saroj',
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Account'), findsOneWidget);
      expect(find.byType(LottieNavIcon), findsNWidgets(5));
    });
  });
}
