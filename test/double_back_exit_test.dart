import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nvit_app/core/widgets/app_toast.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';

void main() {
  testWidgets(
    'MainShell requires double back press on Home tab and switches to Home from other tabs',
    (tester) async {
      int systemPopCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.pop') {
              systemPopCount += 1;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, _) => const Center(child: Text('HOME_BODY')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/products',
                    builder: (_, _) => const Center(child: Text('SHOP_BODY')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/consultations',
                    builder: (_, _) => const Center(child: Text('CARE_BODY')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/shots',
                    builder: (_, _) => const Center(child: Text('SHOTS_BODY')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (_, _) =>
                        const Center(child: Text('PROFILE_BODY')),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/pushed-detail',
            builder: (_, _) => const Scaffold(body: Text('PUSHED_DETAIL')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            scaffoldMessengerKey: appScaffoldMessengerKey,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('HOME_BODY'), findsOneWidget);

      // 1. Switch to Shop tab -> single back press returns to Home without exiting
      router.go('/products');
      await tester.pumpAndSettle();
      expect(find.text('SHOP_BODY'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('HOME_BODY'), findsOneWidget);
      expect(systemPopCount, 0);

      // 2. Push a detail route on top -> single back press pops detail route normally
      router.push('/pushed-detail');
      await tester.pumpAndSettle();
      expect(find.text('PUSHED_DETAIL'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('HOME_BODY'), findsOneWidget);
      expect(find.text('Press back again to exit'), findsNothing);
      expect(systemPopCount, 0);

      // 3. First back press on Home tab -> shows warning toast, does NOT exit
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(systemPopCount, 0);

      // 4. Second back press within 2 seconds -> exits via SystemNavigator.pop()
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(systemPopCount, 1);

      // Drain remaining SnackBar timer cleanly
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
