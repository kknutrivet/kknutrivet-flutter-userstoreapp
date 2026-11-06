/// Visual regression tests for every screen in the app.
///
/// Each test renders a screen with real fonts and the production theme, then
/// compares the pixels against a committed golden image.
///
///   flutter test test/visual --update-goldens   // accept new screenshots
///   flutter test test/visual                    // verify no UI changed
///
/// Goldens are generated on macOS and are host-font dependent, so they are
/// tagged `visual` and excluded from the Linux CI run. Regenerate and review
/// them as part of a UI change, then commit the PNGs.
@Tags(['visual'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/services/app_update_service.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/models/user.dart';

import '../support/app_harness.dart';
import '../support/app_routes.dart';

final AppUser _signedIn = testUser();

/// Screens that are not part of the public route table, or that need a
/// different state (signed-out, tablet, forced update).
class VisualVariant {
  const VisualVariant(
    this.name,
    this.title,
    this.route, {
    this.user,
    this.onboardingComplete = true,
    this.size = const Size(390, 844),
    this.overrides = const [],
    this.expectedLocation,
    this.assertLocation = true,
  });

  final String name;
  final String title;
  final String route;
  final AppUser? user;
  final bool onboardingComplete;
  final Size size;
  final List<Override> overrides;
  final String? expectedLocation;
  final bool assertLocation;
}

final List<VisualVariant> variants = [
  VisualVariant('login', 'Sign in', '/login', user: null),
  VisualVariant(
    'forgot_password',
    'Forgot password',
    '/forgot-password',
    user: null,
  ),
  VisualVariant(
    'force_update',
    'Force update',
    '/update',
    overrides: [
      appUpdateCheckProvider.overrideWith(
        (ref) async => const AppUpdateCheckResult(
          status: AppUpdateStatus.updateRequired,
          config: AppUpdateConfig(
            forceUpdateEnabled: true,
            minBuildNumber: 999,
            minAppVersion: '9.0.0',
            latestVersion: '9.0.0',
          ),
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
        ),
      ),
    ],
  ),
  VisualVariant(
    'cart_tablet',
    'Cart (tablet)',
    '/cart',
    user: _signedIn,
    size: const Size(820, 1180),
  ),
  VisualVariant(
    'not_found',
    'Unknown deep link',
    '/this-route-does-not-exist',
    user: _signedIn,
    assertLocation: false,
  ),
];

void main() {
  configureTestEnvironment();

  final shots = <_Shot>[
    for (final route in appRoutes.where((route) => route.snapshot))
      _Shot(
        name: route.name,
        title: route.title,
        route: route.path,
        user: route.name == 'onboarding' ? null : _signedIn,
        onboardingComplete: route.name != 'onboarding',
      ),
    for (final variant in variants)
      _Shot(
        name: variant.name,
        title: variant.title,
        route: variant.route,
        user: variant.user,
        onboardingComplete: variant.onboardingComplete,
        size: variant.size,
        overrides: variant.overrides,
        expectedLocation: variant.expectedLocation,
        assertLocation: variant.assertLocation,
      ),
  ];

  // The local gallery reads this manifest to label screenshots with their
  // route and capture size.
  setUpAll(() {
    final directory = Directory('build/visual-report')
      ..createSync(recursive: true);
    File('${directory.path}/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert([
        for (final shot in shots)
          {
            'name': shot.name,
            'title': shot.title,
            'route': shot.route,
            'width': shot.size.width.round(),
            'height': shot.size.height.round(),
          },
      ]),
    );
  });

  for (final shot in shots) {
    testWidgets(
      'visual: ${shot.name}',
      (tester) async {
        final app = await pumpTestApp(
          tester,
          user: shot.user,
          route: shot.route,
          onboardingComplete: shot.onboardingComplete,
          size: shot.size,
          overrides: shot.overrides,
        );
        await settle(tester);

        if (shot.assertLocation) {
          expect(
            app.location,
            shot.expectedLocation ?? shot.route.split('?').first,
            reason: 'visual snapshot ${shot.name} landed on ${app.location}',
          );
        }
        expect(tester.takeException(), isNull);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${shot.name}.png'),
        );
      },
      tags: ['visual'],
    );
  }
}

class _Shot {
  _Shot({
    required this.name,
    required this.title,
    required this.route,
    this.user,
    this.onboardingComplete = true,
    this.size = const Size(390, 844),
    this.overrides = const [],
    this.expectedLocation,
    this.assertLocation = true,
  });

  final String name;
  final String title;
  final String route;
  final AppUser? user;
  final bool onboardingComplete;
  final Size size;
  final List<Override> overrides;
  final String? expectedLocation;
  final bool assertLocation;
}
