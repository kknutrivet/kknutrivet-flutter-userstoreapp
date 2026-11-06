# nvit_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Testing

The app has unit/widget tests, app-wide route coverage, user journey tests,
service contract tests and on-device E2E tests. See
[docs/TESTING.md](docs/TESTING.md) for the architecture, commands and
troubleshooting.

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart coverage/lcov.info 55

# Visual regression + browsable screenshot gallery
flutter test test/visual
dart run tool/visual_gallery.dart
open build/visual-report/index.html
```
