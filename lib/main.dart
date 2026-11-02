import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analytics/analytics_service.dart';
import 'core/analytics/mixpanel_service.dart';
import 'core/auth/firebase_auth_service.dart';
import 'core/config/app_config.dart';
import 'core/crashlytics/crashlytics_service.dart';
import 'core/device/device_info_service.dart';
import 'core/notifications/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';

/// True once the shared Firebase project initializes. False when the
/// native config files are missing — Google/phone auth then falls back
/// with a "not configured" message instead of crashing.
final firebaseAvailableProvider = StateProvider<bool>((ref) => false);

final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AppConfig.init();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  final firebaseReady =
      await FirebaseAuthService.instance.ensureInitialized();
  await CrashlyticsService.instance.init(firebaseAvailable: firebaseReady);
  await AnalyticsService.instance.init(firebaseAvailable: firebaseReady);
  await DeviceInfoService.instance.init();
  await MixpanelService.instance.init();
  runApp(
    ProviderScope(
      overrides: [
        firebaseAvailableProvider.overrideWith((ref) => firebaseReady),
      ],
      child: const KkNutrivetApp(),
    ),
  );
}

class KkNutrivetApp extends ConsumerStatefulWidget {
  const KkNutrivetApp({super.key});

  @override
  ConsumerState<KkNutrivetApp> createState() => _KkNutrivetAppState();
}

class _KkNutrivetAppState extends ConsumerState<KkNutrivetApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPush());
  }

  Future<void> _initPush() async {
    await PushService.instance.init(
      register: ({required String token, String? previousToken}) =>
          ref.read(notificationServiceProvider).registerPushToken(
                token: token,
                previousToken: previousToken,
                userAgent: PushService.userAgent,
              ),
      onTapRoute: (route) {
        try {
          ref.read(routerProvider).go(route);
        } catch (_) {}
      },
      onForeground: (title, body, route) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              body.isNotEmpty ? '$title\n$body' : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                try {
                  ref.read(routerProvider).go(route);
                } catch (_) {}
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'KK Nutrivet - Nutrition & Vet Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }
}
