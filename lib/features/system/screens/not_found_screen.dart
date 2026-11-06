import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loader.dart';

/// Friendly fallback for broken or unknown deep links.
///
/// Without this, GoRouter renders its raw `GoException` message, which exposes
/// internal routing details to customers.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(title: const Text('Page not found')),
      body: AppEmptyState(
        icon: Icons.explore_off_outlined,
        title: 'We couldn’t find that page',
        description:
            'The link may be broken or the page may have moved. '
            'Let’s get you back to shopping for your pets.',
        actionLabel: 'Go to home',
        onAction: () => context.go('/home'),
      ),
    );
  }
}
