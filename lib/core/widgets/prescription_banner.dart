import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Full-width "Have a Prescription?" banner used across product surfaces.
class PrescriptionBanner extends StatelessWidget {
  const PrescriptionBanner({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 4),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Semantics(
        button: true,
        label: 'Have a prescription? Upload for a care-team review',
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.push('/prescriptions'),
            child: Image.asset(
              'assets/marketing_image/have-prescription-banner.webp',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
