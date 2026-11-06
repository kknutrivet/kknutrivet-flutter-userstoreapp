# Automation testing

The app is covered by four layers of automated tests. Each layer has a different
job, and they deliberately share one harness so a screen behaves the same way
everywhere.

| Layer | Location | What it protects |
| --- | --- | --- |
| Unit / widget tests | `test/` (existing `*_test.dart`) | Individual widgets, models and helpers |
| Route coverage | `test/routes/route_coverage_test.dart` | Every route and deep link renders without crashing |
| User journeys | `test/journeys/` | Real multi-screen flows through the production router |
| Service contracts | `test/contracts/service_contract_test.dart` | Endpoint paths, request shapes and JSON parsing |
| Visual regression | `test/visual/` | Pixel changes across key screens, plus a browsable gallery |
| On-device E2E | `integration_test/` | The same flows with real rendering and platform channels |

## Commands

```bash
flutter pub get

# Static analysis (must be clean in CI)
flutter analyze

# Full suite
flutter test

# Full suite + line coverage
flutter test --coverage
dart run tool/check_coverage.dart coverage/lcov.info 55

# One file / one test
flutter test test/journeys/shopping_journey_test.dart
flutter test test/journeys/shopping_journey_test.dart --plain-name "guest can buy"

# Visual regression + browsable screenshot gallery
flutter test test/visual                      # compare against committed goldens
flutter test test/visual --update-goldens     # accept the current rendering
dart run tool/visual_gallery.dart             # build build/visual-report/index.html
open build/visual-report/index.html

# On-device E2E (device id from `flutter devices`)
flutter test integration_test -d <device-id>
```

The coverage gate is a line-coverage floor over `lib/` only. The current
baseline is ~60%, and CI enforces **55%** so coverage cannot silently regress.
When the suite legitimately grows, raise `COVERAGE_THRESHOLD` in
`.github/workflows/flutter-ci.yml` rather than lowering it.

## The shared harness

`test/support/app_harness.dart` boots the **real** app: the production
`GoRouter`, the production providers and the production theme. Only the network
and a few platform-facing providers are replaced.

```dart
void main() {
  configureTestEnvironment();

  testWidgets('guest can reach checkout', (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/products');
    expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);

    app.api.failOn('/orders', ApiException(message: 'Server error', statusCode: 500));
  });
}
```

What `pumpTestApp` does:

- Sets the surface to a 390×844 phone at DPR 1 unless a size is passed.
- Clears `SharedPreferences` and loads the real `Lora` / `PlusJakartaSans`
  fonts. Real fonts matter: the default Ahem test font is much wider and
  produces false `RenderFlex overflow` failures on app screens.
- Overrides `apiClientProvider`, `authProvider`, `onboardingProvider`,
  `storeSettingsProvider` and `appUpdateCheckProvider`.
- Returns a `TestApp` with `tester`, `container`, `router`, `api`, `auth`,
  `onboarding`, `location` and `go(route)`.

Options: `user`, `onboardingComplete`, `api`, `overrides`, `route` (pass
`/splash` to exercise real cold-start resolution), `size`, `devicePixelRatio`.

Use `settle(tester)` instead of `pumpAndSettle`. Shimmer and Lottie animations
loop forever, so `pumpAndSettle` can time out; `settle` pumps a fixed number of
frames.

### Mock notifiers

- `MockAuthNotifier` — starts signed-in (`user`) or signed-out (`null`), and
  records `loginCount` / `logoutCount`. `continueAsGuest()` creates an
  anonymous user.
- `MockOnboardingNotifier` — starts complete or incomplete.

Both extend the real notifier classes, so app logic is unchanged.

## The fake API client

`test/support/fake_api_client.dart` implements `ApiClient`. It understands the
app's resource shapes, so services and screens run for real against canned
data.

```dart
final api = FakeApiClient(
  routes: {
    'GET /products': [productJson()],
    '/cart': cartJson(items: []),
  },
  patternRoutes: {
    RegExp(r'^/orders/[^/]+$'): orderJson(),
    '/search': (call) => [productJson(name: call.query!['q'])],
  },
  handler: (call) => call.path == '/ping' ? {'ok': true} : null,
  delay: const Duration(milliseconds: 50),
);

api.failOn('POST /orders', ApiException(message: 'Out of stock', statusCode: 409));

// Assertions
expect(api.callsTo('/cart', method: 'PUT'), hasLength(1));
expect(api.calls.single.query?['search'], 'calm');
```

Resolution order: exact `"METHOD /path"` → exact path → `patternRoutes` →
`handler` → built-in defaults. Any response value may also be a function that
receives the `ApiCall`.

Defaults: `/settings` → `settingsJson()`, `/products` → `testProducts`,
`/orders` → `[orderJson()]`, `/consultations/<id>/messages` →
`{messages: [], canMessage: true}`, unknown GET → `[]`, mutations → `{}`.

Fixtures live in `test/support/fixtures.dart` (`userJson`, `productJson`,
`testProducts`, `cartJson`, `orderJson`, `settingsJson`, `testUser`, ...). Add
new fixtures there rather than inlining long JSON.

## Adding a route

`test/support/app_routes.dart` is the single table of every route, its expected
matched location, a golden filename slug and a gallery title. When you add a
route to `lib/core/router/app_router.dart`:

1. Add an `AppRoute(...)` entry to `appRoutes`.
2. Run `flutter test test/routes/route_coverage_test.dart`.
3. Run `flutter test test/visual --update-goldens` to create the new screenshot.
4. Run `dart run tool/visual_gallery.dart` and review the new screen.

The route test fails if the route lands somewhere unexpected (for example a
redirect to `/login`) or throws during the first frame. Redirect-only aliases
can set `snapshot: false` so the visual suite does not capture a duplicate, but
they are still exercised by route coverage.

## Adding a journey

Put multi-screen flows in `test/journeys/`. A journey should read like a user
story and assert on visible text plus `app.location`, not on internal state.

```dart
testWidgets('guest can search and open a result', (tester) async {
  final app = await pumpTestApp(tester, user: null);

  await app.go('/search');
  await tester.enterText(find.byType(TextField).first, 'calm');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await settle(tester);

  expect(app.location, '/products');
  expect(app.api.callsTo('/products').last.query?['search'], 'calm');
});
```

When a journey exposes a real bug, fix the app — do not weaken the assertion.

## Service contracts

`test/contracts/service_contract_test.dart` calls the real service classes and
asserts the exact method, path, query and body the API receives, plus the
parsed models and error handling. Add a contract whenever a service gains or
changes an endpoint.

## Visual regression & gallery

`test/visual/visual_screens_test.dart` renders **every screen state** with real
fonts and the production router/theme, then compares the pixels with the
committed PNGs in `test/visual/goldens/`. That is 48 snapshots: every route in
the router plus sign-in, forgot-password, forced-update, a tablet cart layout
and an unknown deep link. Redirect-only aliases (`/combos`, `/care-chat`,
`/health-concerns`, `/update`) are skipped visually because they land on a
screen captured elsewhere, but the route coverage test still exercises them.

```bash
flutter test test/visual                    # verify no pixel changed
flutter test test/visual --update-goldens   # accept an intentional UI change
dart run tool/visual_gallery.dart           # build the report
open build/visual-report/index.html
```

The generated `build/visual-report/index.html` is a filterable gallery of every
snapshot with its route and viewport size, plus a side-by-side
expected / actual / diff view for any failing test. It is the fastest way to
review a UI change without booting the app.

`tool/visual_gallery.dart` reads the manifest written by the visual test, so run
the visual tests before building the report.

Visual tests are tagged `visual` and excluded from the Linux CI run because
golden pixels depend on the host font rasterizer. Run and review them locally
whenever you touch UI, then commit the regenerated goldens alongside the code.
To capture visual state on a real screen too, the integration tests can be run
on a device, but the gallery comes from the deterministic widget goldens.

## On-device E2E

`integration_test/app_e2e_test.dart` reuses the harness with
`IntegrationTestWidgetsFlutterBinding`, so flows run with real rendering,
gestures and platform channels. It covers cold start, guest browse → PDP → cart
→ checkout, and the protected-route redirect.

CI runs these on an Android emulator only on `main` and on manual dispatch,
because emulators are slow. Locally they require a booted simulator/emulator:

```bash
flutter devices
flutter test integration_test -d emulator-5554
```

If no device is available, the widget journeys already cover the same flows.

## Continuous integration

`.github/workflows/flutter-ci.yml`:

1. `flutter analyze` — must be clean.
2. `flutter test --coverage --exclude-tags visual` — full suite. Visual goldens
   are host-rendering dependent, so they are reviewed locally instead.
3. `dart run tool/check_coverage.dart coverage/lcov.info 55` — coverage gate.
4. Uploads `coverage/lcov.info` as an artifact.
5. On `main` / manual dispatch, runs the Android emulator E2E job.

## Troubleshooting

- **`pumpAndSettle` times out** — use `settle(tester)`; looping shimmer or
  Lottie animations never settle.
- **`RenderFlex overflowed` only in tests** — make sure `loadAppFonts()` ran.
  `pumpTestApp` does this automatically; custom `pumpWidget` setups must call
  `configureTestEnvironment()` and `loadAppFonts()` first.
- **A route lands on `/login`** — it is a protected route. Pass
  `user: testUser()` or update the expected location in the route table.
- **Tests cannot find seeded data** — the fake API only knows fixture shapes.
  Add a route to `FakeApiClient.routes` instead of hitting the network.
- **Mixpanel `Track failed: DioException ... 400` logs** — expected noise in
  tests; analytics has no network access and the failure is swallowed.
- **Coverage drops** — run `dart run tool/check_coverage.dart coverage/lcov.info`
  to list the least-covered files, then add journeys or contracts there.
