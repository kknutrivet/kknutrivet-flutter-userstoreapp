import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/announcements/announcement_service.dart';
import 'package:nvit_app/core/widgets/in_app_announcement_dialog.dart';
import 'package:nvit_app/models/in_app_announcement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnnouncementService.instance.resetSessionForTest();
  });

  group('InAppAnnouncement Model & Parser Tests', () {
    test('fromJson parses full announcement data correctly', () {
      final json = {
        'id': 'ann_promo_1',
        'isActive': true,
        'type': 'OFFER',
        'layoutMode': 'IMAGE_AND_TEXT',
        'imageFit': 'COVER',
        'title': 'Monsoon Special Offer',
        'message': 'Keep your pets healthy during rainy days.\n• Anti-tick spray discounts\n🌱 Herbal ear cleansers\n✨ 24hr doctor assistance',
        'imageUrl': 'https://example.com/banner.webp',
        'ctaText': 'Shop Deals',
        'ctaLink': '/products?category=Monsoon',
        'target': 'HOMEPAGE_ONLY',
        'dismissButtonText': 'Maybe Later',
        'priority': 1,
        'version': 2,
      };

      final ann = InAppAnnouncement.fromJson(json);

      expect(ann.id, 'ann_promo_1');
      expect(ann.isActive, isTrue);
      expect(ann.type, 'OFFER');
      expect(ann.layoutMode, 'IMAGE_AND_TEXT');
      expect(ann.imageFit, 'COVER');
      expect(ann.title, 'Monsoon Special Offer');
      expect(ann.imageUrl, 'https://example.com/banner.webp');
      expect(ann.ctaText, 'Shop Deals');
      expect(ann.ctaLink, '/products?category=Monsoon');
      expect(ann.target, 'HOMEPAGE_ONLY');
      expect(ann.dismissButtonText, 'Maybe Later');
      expect(ann.priority, 1);
      expect(ann.version, 2);
      expect(ann.hasImage, isTrue);
      expect(ann.hasCta, isTrue);
    });

    test('parseMessageContent parses intro and bullet points correctly', () {
      const raw = '''
Urgent delivery notification for coastal areas:
• High rainfall reported in Balasore
🌱 All dispatched parcels are sealed in waterproof packs
🚨 Courier delivery may experience 24-48h delay
''';

      final parsed = parseMessageContent(raw);

      expect(parsed.intro, contains('Urgent delivery notification'));
      expect(parsed.bullets.length, 3);
      expect(parsed.bullets[0].icon, '🌱');
      expect(parsed.bullets[0].text, contains('High rainfall reported'));
      expect(parsed.bullets[1].icon, '🌱');
      expect(parsed.bullets[1].text, contains('All dispatched parcels'));
      expect(parsed.bullets[2].icon, '🚨');
      expect(parsed.bullets[2].text, contains('Courier delivery may experience'));
    });
  });

  group('AnnouncementService Eligibility & Dismissal Tests', () {
    final service = AnnouncementService.instance;

    test('isEligibleForRoute filters by target and blacklisted routes', () {
      const homeAnn = InAppAnnouncement(
        id: 'ann_home',
        isActive: true,
        title: 'Home Only',
        message: 'Info',
        target: 'HOMEPAGE_ONLY',
      );

      const checkoutAnn = InAppAnnouncement(
        id: 'ann_checkout',
        isActive: true,
        title: 'Checkout Only',
        message: 'Info',
        target: 'CHECKOUT_ONLY',
      );

      const allAnn = InAppAnnouncement(
        id: 'ann_all',
        isActive: true,
        title: 'All Pages',
        message: 'Info',
        target: 'ALL',
      );

      // Homepage only
      expect(service.isEligibleForRoute(homeAnn, '/home'), isTrue);
      expect(service.isEligibleForRoute(homeAnn, '/products'), isFalse);
      expect(service.isEligibleForRoute(homeAnn, '/checkout'), isFalse);

      // Checkout only
      expect(service.isEligibleForRoute(checkoutAnn, '/checkout'), isTrue);
      expect(service.isEligibleForRoute(checkoutAnn, '/cart'), isTrue);
      expect(service.isEligibleForRoute(checkoutAnn, '/home'), isFalse);

      // All pages
      expect(service.isEligibleForRoute(allAnn, '/home'), isTrue);
      expect(service.isEligibleForRoute(allAnn, '/products'), isTrue);

      // Excluded routes
      expect(service.isEligibleForRoute(allAnn, '/login'), isFalse);
      expect(service.isEligibleForRoute(allAnn, '/splash'), isFalse);
      expect(service.isEligibleForRoute(allAnn, '/onboarding'), isFalse);
      expect(service.isEligibleForRoute(allAnn, '/admin/orders'), isFalse);
    });

    test('recordDismissal stores versioned flag and prevents reshowing', () async {
      const ann = InAppAnnouncement(
        id: 'cyclone_alert_2026',
        isActive: true,
        title: 'Cyclone Alert',
        message: 'Deliveries delayed',
        version: 1,
      );

      expect(await service.isDismissed(ann), isFalse);

      await service.recordDismissal(ann);
      expect(await service.isDismissed(ann), isTrue);

      // If version increments, it is not dismissed for the new version
      const updatedAnn = InAppAnnouncement(
        id: 'cyclone_alert_2026',
        isActive: true,
        title: 'Cyclone Alert Updated',
        message: 'New road open',
        version: 2,
      );
      expect(await service.isDismissed(updatedAnn), isFalse);
    });

    test('Session memory limits display to once per session', () {
      expect(service.hasShownThisSession, isFalse);
      service.markShownThisSession();
      expect(service.hasShownThisSession, isTrue);
    });
  });

  group('InAppAnnouncementDialog Widget Tests', () {
    testWidgets('renders announcement header, title, bullets and CTA button',
        (tester) async {
      const announcement = InAppAnnouncement(
        id: 'ann_test_ui',
        isActive: true,
        type: 'ALERT',
        layoutMode: 'TEXT_ONLY',
        title: 'Important Health Update',
        message: 'Seasonal tips for your pets:\n🌱 Keep water bowls fresh\n🛡️ Deworm every 3 months',
        ctaText: 'View Care Guide',
        ctaLink: '/blog/pet-care',
        dismissButtonText: 'Maybe Later',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showInAppAnnouncementDialog(context, announcement),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('KK NUTRIVET'), findsOneWidget);
      expect(find.text('Delivery Notice'), findsOneWidget);
      expect(find.text('🚨'), findsOneWidget);
      expect(find.text('Important Health Update'), findsOneWidget);
      expect(find.text('Seasonal tips for your pets:'), findsOneWidget);
      expect(find.text('Keep water bowls fresh'), findsOneWidget);
      expect(find.text('Deworm every 3 months'), findsOneWidget);
      expect(find.text('View Care Guide'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);

      // Tapping Maybe Later closes dialog and records dismissal
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      expect(find.text('Important Health Update'), findsNothing);
      expect(await AnnouncementService.instance.isDismissed(announcement), isTrue);
    });

    testWidgets('showInAppAnnouncementDialog opens FullscreenFestiveHeroOverlay for FESTIVE campaigns', (tester) async {
      const festiveAnnouncement = InAppAnnouncement(
        id: 'ann_diwali_hero',
        isActive: true,
        type: 'FESTIVE',
        layoutMode: 'FULLSCREEN_HERO',
        eyebrow: 'A LITTLE LIGHT. A LOT OF LOVE.',
        title: 'Happy Diwali',
        message: 'For you, your family and every little paw.',
        highlightTitle: 'Celebrate bright. Keep pets safe.',
        highlightMessage: 'More lights, less noise. Keep your pets cosy and safe.',
        ctaText: 'Continue shopping',
        ctaLink: '/products',
        footerText: 'More light. Less noise. Love for every animal.',
      );

      expect(festiveAnnouncement.isFullscreenHero, isTrue);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showInAppAnnouncementDialog(context, festiveAnnouncement),
                  child: const Text('Show Festive'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open fullscreen overlay
      await tester.tap(find.text('Show Festive'));
      await tester.pumpAndSettle();

      // Verify Fullscreen elements
      expect(find.text('KK NUTRIVET'), findsOneWidget);
      expect(find.text('HEALTH · CARE · TRUST'), findsOneWidget);
      expect(find.text('A LITTLE LIGHT. A LOT OF LOVE.'), findsOneWidget);
      expect(find.text('Happy Diwali'), findsOneWidget);
      expect(find.text('For you, your family and every little paw.'), findsOneWidget);
      expect(find.text('Celebrate bright. Keep pets safe.'), findsOneWidget);
      expect(find.text('More lights, less noise. Keep your pets cosy and safe.'), findsOneWidget);
      expect(find.text('Continue shopping'), findsOneWidget);
      expect(find.text('More light. Less noise. Love for every animal.'), findsOneWidget);

      // Verify close button
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);

      // Tap close button
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Happy Diwali'), findsNothing);
      expect(await AnnouncementService.instance.isDismissed(festiveAnnouncement), isTrue);
    });
  });
}
