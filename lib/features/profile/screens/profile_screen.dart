import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/user.dart';
import '../../../providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    if (authState.isLoading) {
      return const Scaffold(body: LoadingView());
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.homeCanvas,
        appBar: AppBar(
          title: Text(
            'My Account',
            style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GuestWelcomeCard(
                  onLogin: () {
                    AppHaptics.light();
                    ref.read(pendingAuthRedirectProvider.notifier).state =
                        '/profile';
                    context.push('/login');
                  },
                ),
                const SizedBox(height: 16),
                if (kDebugMode &&
                    const bool.fromEnvironment('SHOW_DEVELOPER_SETTINGS'))
                  TextButton.icon(
                    onPressed: _showEnvironmentDialog,
                    icon: Icon(
                      AppConfig.isTest
                          ? Icons.science_outlined
                          : Icons.cloud_done_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(
                      'Server: ${AppConfig.environment.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'My Account',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(authProvider.notifier).refreshProfile(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
          children: [
            _UserHeaderCard(
              user: user,
              onEdit: () => _editProfile(user.name, user.phone, user.email),
            ),
            const SizedBox(height: 14),
            _sectionLabel('SHOPPING & ORDERS'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppTile(
                    icon: Icons.local_shipping_outlined,
                    iconBg: AppColors.primaryWash,
                    iconColor: AppColors.primaryDeep,
                    title: 'My Orders',
                    subtitle: 'Track packages, view invoices & order history',
                    onTap: () => context.push('/orders'),
                  ),
                  AppTile(
                    icon: Icons.location_on_outlined,
                    iconBg: AppColors.dogRailBg,
                    iconColor: AppColors.dogRailHeading,
                    title: 'Saved Addresses',
                    subtitle: 'Manage delivery addresses & pincodes',
                    onTap: () => context.push('/addresses'),
                  ),
                  AppTile(
                    icon: Icons.receipt_long_outlined,
                    iconBg: AppColors.rxBg,
                    iconColor: AppColors.rxText,
                    title: 'Prescriptions',
                    subtitle: 'Upload and view veterinary prescriptions',
                    onTap: () => context.push('/prescriptions'),
                  ),
                  AppTile(
                    icon: Icons.favorite_border_rounded,
                    iconBg: AppColors.homePeach,
                    iconColor: AppColors.favoriteRed,
                    title: 'My Wishlist',
                    subtitle: 'Saved items, supplements & medicines',
                    onTap: () => context.push('/wishlist'),
                  ),
                  AppTile(
                    icon: Icons.monetization_on_outlined,
                    iconBg: AppColors.coinsBg,
                    iconColor: AppColors.coinsIcon,
                    title: 'Rewards & KK Coins',
                    subtitle: 'Earn coins, invite friends & save on orders',
                    onTap: () => context.push('/referral'),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel('PET CARE & VETERINARY'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppTile(
                    icon: Icons.pets_outlined,
                    iconBg: AppColors.primaryWash,
                    iconColor: AppColors.primaryDeep,
                    title: 'My Pets',
                    subtitle: 'Care profiles, vaccinations & reminders',
                    onTap: () => context.push('/pets'),
                  ),
                  AppTile(
                    icon: Icons.auto_awesome_outlined,
                    iconBg: AppColors.homeLavender,
                    iconColor: AppColors.accentViolet,
                    title: 'Dr. Paw (AI)',
                    subtitle: '24/7 intelligent symptom checker & advice',
                    badgeText: 'AI',
                    onTap: () => context.push('/vet'),
                  ),
                  AppTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconBg: AppColors.primaryWashFaint,
                    iconColor: AppColors.primary,
                    title: 'Care team chat',
                    subtitle:
                        'Chat with certified vets & get digital prescriptions',
                    onTap: () => context.push('/consultations'),
                  ),
                  AppTile(
                    icon: Icons.calculate_outlined,
                    iconBg: AppColors.homeSoftYellow,
                    iconColor: AppColors.homeYellowInk,
                    title: 'Nutrition Calculator',
                    subtitle: 'Calculate customized daily feeding rations',
                    onTap: () => context.push('/calculator'),
                  ),
                  AppTile(
                    icon: Icons.favorite_border_rounded,
                    iconBg: AppColors.homePeach,
                    iconColor: AppColors.homePeachInk,
                    title: 'Pet Care Guide',
                    subtitle: 'Daily routine, safety & health guidelines',
                    onTap: () => context.push('/pet-care'),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel('DISCOVER & LEARN'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppTile(
                    icon: Icons.health_and_safety_outlined,
                    iconBg: AppColors.primaryWash,
                    iconColor: AppColors.primaryDeep,
                    title: 'Health Library',
                    subtitle: 'Explore conditions, symptoms & remedies',
                    onTap: () => context.push('/diseases'),
                  ),
                  AppTile(
                    icon: Icons.article_outlined,
                    iconBg: AppColors.dogRailBg,
                    iconColor: AppColors.dogRailHeading,
                    title: 'Insights & Blog',
                    subtitle: 'Veterinary articles, care tips & guides',
                    onTap: () => context.push('/blog'),
                  ),
                  AppTile(
                    icon: Icons.camera_alt_outlined,
                    iconBg: AppColors.homeLavender,
                    iconColor: AppColors.accentViolet,
                    title: 'Find product by photo',
                    subtitle: 'Choose a product photo or search by name',
                    onTap: () => context.push('/scan'),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel('SUPPORT & SETTINGS'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (kDebugMode &&
                      const bool.fromEnvironment('SHOW_DEVELOPER_SETTINGS'))
                    AppTile(
                      icon: Icons.dns_outlined,
                      iconBg: AppConfig.isTest
                          ? const Color(0xFFFFF3CD)
                          : AppColors.primaryWash,
                      iconColor: AppConfig.isTest
                          ? const Color(0xFF856404)
                          : AppColors.primaryDeep,
                      title: 'Server Environment',
                      subtitle:
                          '${AppConfig.environment.name} (${AppConfig.apiBaseUrl})',
                      onTap: _showEnvironmentDialog,
                    ),
                  AppTile(
                    icon: Icons.help_outline_rounded,
                    iconBg: AppColors.primaryWashFaint,
                    iconColor: AppColors.textPrimary,
                    title: 'Help & Policies',
                    subtitle: 'Shipping, returns, refunds & privacy policy',
                    onTap: () => context.push('/help'),
                  ),
                  AppTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconBg: AppColors.primaryWash,
                    iconColor: AppColors.whatsAppGreen,
                    title: 'WhatsApp Customer Support',
                    subtitle: 'Chat directly with our care team on WhatsApp',
                    onTap: _openWhatsApp,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Log out',
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 18,
              ),
              variant: AppButtonVariant.danger,
              fullWidth: true,
              onPressed: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Future<void> _showEnvironmentDialog() async {
    final selected = await showDialog<AppEnvironment>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Server Environment',
            style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppEnvironment.values.map((env) {
              final isCurrent = AppConfig.environment == env;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCurrent
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  tileColor: isCurrent
                      ? AppColors.primaryWashFaint
                      : Colors.white,
                  leading: Icon(
                    env == AppEnvironment.prod
                        ? Icons.cloud_done_outlined
                        : Icons.science_outlined,
                    color: isCurrent
                        ? AppColors.primaryDeep
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    env.name,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    env.baseUrl,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryDeep,
                        )
                      : null,
                  onTap: () => Navigator.of(ctx).pop(env),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected != null && selected != AppConfig.environment) {
      await AppConfig.setEnvironment(selected);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${selected.name} (${selected.baseUrl})'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editProfile(String? name, String? phone, String? email) async {
    final nameController = TextEditingController(text: name ?? '');
    final phoneController = TextEditingController(text: phone ?? '');
    final emailController = TextEditingController(text: email ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit profile', style: AppTheme.serif(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    try {
      await ref
          .read(authServiceProvider)
          .updateProfile(
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            email: emailController.text.trim(),
          );
      await ref.read(authProvider.notifier).refreshProfile();
      showToast('Profile updated');
    } catch (e) {
      showToast(e.toString(), isError: true);
    }
  }

  void _openWhatsApp() {
    AppHaptics.light();
    const url =
        'https://wa.me/917846932453?text=Hi%20KK%20Nutrivet%2C%20I%20need%20help%20with%20my%20order%20or%20animal.';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmLogout() async {
    AppHaptics.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log out?', style: AppTheme.serif(fontSize: 18)),
        content: const Text(
          'You will need to sign in again to access your saved cart, orders and pet profiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/home');
    }
  }
}

class _UserHeaderCard extends StatelessWidget {
  const _UserHeaderCard({required this.user, required this.onEdit});
  final AppUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final displayName = user.name?.isNotEmpty == true
        ? user.name!
        : 'Pet Parent';
    final initial = displayName.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowLifted,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.catalogueGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.serif(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Member',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                if (user.phone != null && user.phone!.isNotEmpty)
                  Text(
                    user.phone!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestWelcomeCard extends StatelessWidget {
  const _GuestWelcomeCard({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowLifted,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryWash,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.pets_rounded,
                size: 36,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to KK Nutrivet',
            style: AppTheme.serif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to manage veterinary prescriptions, track order deliveries, record pet vaccine schedules, and chat with certified doctors.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Login / Sign Up',
            fullWidth: true,
            size: AppButtonSize.lg,
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}
