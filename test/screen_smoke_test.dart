import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/theme/app_theme.dart';
import 'package:nvit_app/features/home/screens/home_screen.dart';
import 'package:nvit_app/features/cart/screens/cart_screen.dart';
import 'package:nvit_app/features/prescriptions/screens/prescriptions_screen.dart';
import 'package:nvit_app/features/consultations/screens/consultations_home_screen.dart';
import 'package:nvit_app/features/health/screens/diseases_screen.dart';
import 'package:nvit_app/features/profile/screens/profile_screen.dart';
import 'package:nvit_app/providers/app_providers.dart';

class FakeApiClient implements ApiClient {
  @override
  void updateBaseUrl(String newBaseUrl) {}

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => [];

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async => {};

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async => {};

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async => {};

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async =>
      {};

  @override
  Future<dynamic> upload(
    String path,
    String filePath, {
    String fileField = 'file',
    Map<String, dynamic>? fields,
  }) async => {};
}

Widget buildTestScreen(Widget screen) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
    child: MaterialApp(home: Scaffold(body: screen)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Design System & Theme Tokens Parity', () {
    test('AppColors aligns with website tokens', () {
      expect(AppColors.brandPrimary, const Color(0xFF126B50));
      expect(AppColors.primaryDeep, const Color(0xFF07583F));
      expect(AppColors.textPrimary, const Color(0xFF17322B));
      expect(AppColors.textSecondary, const Color(0xFF5A615F));
      expect(AppColors.background, const Color(0xFFF3F6F5));
      expect(AppColors.homeCanvas, const Color(0xFFF6F8F7));
      expect(AppColors.accentCoral, const Color(0xFFB9412E));
    });

    test('AppRadius aligns with website CSS tokens', () {
      expect(AppRadius.sm, 8.0); // --radius-chip
      expect(AppRadius.md, 10.0); // --radius-control
      expect(AppRadius.card, 14.0); // --radius-card
      expect(AppRadius.modal, 18.0); // --radius-modal
    });

    test('AppSpacing aligns with website CSS tokens', () {
      expect(AppSpacing.stack, 12.0); // --spacing-stack
      expect(AppSpacing.gutter, 16.0); // --spacing-gutter
      expect(AppSpacing.gutterLg, 20.0); // --spacing-gutter-lg
      expect(AppSpacing.section, 32.0); // --spacing-section
    });

    testWidgets('AppTheme.light builds valid Material 3 theme', (tester) async {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.brandPrimary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });
  });

  group('Core Screens Instantiation', () {
    testWidgets('HomeScreen instantiates without error', (tester) async {
      await tester.pumpWidget(buildTestScreen(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('CartScreen instantiates without error', (tester) async {
      await tester.pumpWidget(buildTestScreen(const CartScreen()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('PrescriptionsScreen instantiates without error', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen(const PrescriptionsScreen()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(PrescriptionsScreen), findsOneWidget);
    });

    testWidgets('ConsultationsHomeScreen instantiates without error', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen(const ConsultationsHomeScreen()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ConsultationsHomeScreen), findsOneWidget);
    });

    testWidgets('DiseasesScreen instantiates without error', (tester) async {
      await tester.pumpWidget(buildTestScreen(const DiseasesScreen()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(DiseasesScreen), findsOneWidget);
    });

    testWidgets('ProfileScreen instantiates without error', (tester) async {
      await tester.pumpWidget(buildTestScreen(const ProfileScreen()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
