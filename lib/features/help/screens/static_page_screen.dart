import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';

class StaticPageSection {
  const StaticPageSection(this.heading, this.body);
  final String? heading;
  final String body;
}

class StaticPageScreen extends StatelessWidget {
  const StaticPageScreen(
      {super.key, required this.title, required this.sections});
  final String title;
  final List<StaticPageSection> sections;

  static const about = <StaticPageSection>[
    StaticPageSection('Who we are',
        'KK Nutrivet is a Brahmapur-based store dedicated to keeping your animals healthy. We stock quality feeds, supplements, medicines and pet care products for dogs, cats and livestock.'),
    StaticPageSection('What we offer',
        'Beyond products, we provide Dr. Paw - an AI assistant for animal health questions, consultations, prescriptions, a health library and a find-alternatives tool to help you compare and choose products.'),
    StaticPageSection('Our promise',
        'Accurate product information, helpful guidance and a team that understands both companion and farm animals. For emergencies, always contact a vet immediately.'),
  ];

  static const shipping = <StaticPageSection>[
    StaticPageSection('Dispatch',
        'Orders placed before our daily cut-off are dispatched the same day. You will receive a confirmation with tracking details once your order ships.'),
    StaticPageSection('Delivery time',
        'Most orders are delivered within 2-5 business days. Delivery timelines depend on your pincode.'),
    StaticPageSection('Charges',
        'Delivery charges are calculated at checkout based on your pincode and order value. Free delivery applies above the threshold shown for your pincode.'),
    StaticPageSection('Damaged or incorrect items',
        'If your order arrives damaged or with incorrect items, contact us on WhatsApp within 48 hours with your order number and a photo of the product and we will resolve it.'),
  ];

  static const privacy = <StaticPageSection>[
    StaticPageSection('What we collect',
        'We collect information you provide such as your name, mobile number, address and pet details, along with your order and referral history.'),
    StaticPageSection('How we use it',
        'We use your information to process orders, deliver products, personalise Dr. Paw answers, send order updates and improve our services. We do not sell your personal data.'),
    StaticPageSection('Photos',
        'Photos you upload (pet profiles, prescriptions) are used only to provide the relevant service.'),
    StaticPageSection('Contact',
        'For any privacy questions, email kknutrivet@gmail.com.'),
  ];

  static const terms = <StaticPageSection>[
    StaticPageSection('Acceptance',
        'By using KK Nutrivet you agree to these terms of service.'),
    StaticPageSection('Guidance is not medical advice',
        'Dr. Paw answers and health library content are informational only and are not a substitute for a professional veterinary diagnosis.'),
    StaticPageSection('Prescriptions',
        'Prescription-required products are fulfilled only against a valid veterinary prescription.'),
    StaticPageSection('Changes',
        'We may update these terms from time to time. Continued use of the app after changes means you accept the updated terms.'),
  ];

  static const returns = <StaticPageSection>[
    StaticPageSection('Returns & replacements',
        'Products can be returned or replaced within 7 days of delivery if they are damaged, defective, or incorrect. Items must be in original condition with original packaging intact.'),
    StaticPageSection('Non-returnable items',
        'Opened medicines, temperature-sensitive vaccines, and used healthcare products cannot be returned for safety reasons.'),
    StaticPageSection('Cancellations',
        'Orders can be cancelled before dispatch directly through the app or by messaging support on WhatsApp. Once dispatched, standard return guidelines apply.'),
    StaticPageSection('Refunds',
        'Approved refunds are credited to the original payment method within 5-7 business days.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          title,
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
          for (final s in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                variant: AppCardVariant.elevated,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.heading != null) ...[
                      Text(
                        s.heading!,
                        style: AppTheme.serif(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      s.body,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 36),
        ],
      ),
    ),
  );
  }
}
