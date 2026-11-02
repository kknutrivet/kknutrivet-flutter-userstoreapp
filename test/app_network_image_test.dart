import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/widgets/app_network_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppNetworkImage URL Resolution Tests', () {
    test('resolveUrl handles null and empty inputs safely', () {
      expect(AppNetworkImage.resolveUrl(null), isNull);
      expect(AppNetworkImage.resolveUrl(''), isNull);
      expect(AppNetworkImage.resolveUrl('   '), isNull);
    });

    test('resolveUrl preserves absolute http and https URLs', () {
      const httpsUrl = 'https://kknutrivet-s3.amazonaws.com/uploads/product.png';
      expect(AppNetworkImage.resolveUrl(httpsUrl), equals(httpsUrl));

      const httpUrl = 'http://example.com/image.jpg';
      expect(AppNetworkImage.resolveUrl(httpUrl), equals(httpUrl));
    });

    test('resolveUrl resolves relative paths with leading slash', () {
      final resolved = AppNetworkImage.resolveUrl('/uploads/test.png');
      expect(resolved, isNotNull);
      expect(resolved, startsWith('https://'));
      expect(resolved, endsWith('/uploads/test.png'));
    });

    test('resolveUrl resolves relative paths without leading slash', () {
      final resolved = AppNetworkImage.resolveUrl('uploads/test.png');
      expect(resolved, isNotNull);
      expect(resolved, startsWith('https://'));
      expect(resolved, endsWith('/uploads/test.png'));
    });

    test('resolveUrl encodes spaces properly', () {
      final resolved = AppNetworkImage.resolveUrl('https://example.com/my image.png');
      expect(resolved, isNotNull);
      expect(resolved, contains('%20'));
    });
  });

  group('AppNetworkImage Widget Rendering Tests', () {
    testWidgets('renders fallback icon when imageUrl is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppNetworkImage(
              imageUrl: null,
              fallbackIcon: Icons.pets,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('renders custom fallback icon when specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppNetworkImage(
              imageUrl: '',
              fallbackIcon: Icons.article_outlined,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });
  });
}
