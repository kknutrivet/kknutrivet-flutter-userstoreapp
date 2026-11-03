import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import 'static_page_screen.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});
  static const helpEmail = 'kknutrivet@gmail.com';
  static const helpPhone = '917846932453';
  static const helpAddress =
      'Bapuji Nagar 5th Lane, Tower Lane,\nBrahmapur, Odisha 760004';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          // Header hero banner
          AppCard(
            variant: AppCardVariant.tinted,
            backgroundColor: AppColors.primaryDeep,
            borderColor: AppColors.primaryDeepest,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'CUSTOMER CARE & STORE ASSISTANCE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'How can we assist you?',
                  style: AppTheme.serif(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Our certified care team responds promptly on WhatsApp and email during store hours (9 AM – 8 PM IST).',
                  style: TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _sectionLabel('DIRECT CONTACT CHANNELS'),
          const SizedBox(height: 8),

          AppCard(
            variant: AppCardVariant.elevated,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF25D366),
                  iconBg: const Color(0xFFE8F5E9),
                  title: 'Chat on WhatsApp',
                  subtitle: '+91 78469 32453 · Quick response',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.textTertiary),
                  onTap: () {
                    AppHaptics.light();
                    _launch('https://wa.me/$helpPhone');
                  },
                ),
                AppTile(
                  icon: Icons.email_outlined,
                  iconColor: AppColors.primaryDeep,
                  title: 'Email Care Team',
                  subtitle: helpEmail,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.textTertiary),
                  onTap: () {
                    AppHaptics.light();
                    _launch('mailto:$helpEmail');
                  },
                ),
                const AppTile(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.primaryDeep,
                  title: 'Flagship Medicine Store',
                  subtitle: helpAddress,
                ),
                AppTile(
                  icon: Icons.local_shipping_outlined,
                  iconColor: AppColors.primaryDeep,
                  title: 'Pincode Delivery Speed',
                  subtitle: 'Check dispatch speed and COD for your area',
                  isLast: true,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.textTertiary),
                  onTap: () {
                    AppHaptics.light();
                    context.push('/pincode');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          _sectionLabel('FREQUENTLY ASKED QUESTIONS'),
          const SizedBox(height: 8),

          _faqCard(
            'How fast is veterinary delivery?',
            'Orders placed before our cutoff time are dispatched on the same day. Standard delivery in Odisha takes 1–2 days; national delivery takes 3–5 days with live tracking.',
          ),
          _faqCard(
            'Can I return a medicine or supplement?',
            StaticPageScreen.returns.first.body,
          ),
          _faqCard(
            'How does the Prescription Concierge work?',
            'Upload a clear picture of your vet prescription. Our verified veterinary team matches every medication or equivalent certified generic composition and prepares a ready cart for you.',
          ),
          _faqCard(
            'What payment methods are supported?',
            'We support all UPI apps (GPay, PhonePe, Paytm), Visa, Mastercard, RuPay cards, Net Banking, and Cash on Delivery (COD).',
          ),
          const SizedBox(height: 36),
        ],
      ),
    ),
  );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _faqCard(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        variant: AppCardVariant.elevated,
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
