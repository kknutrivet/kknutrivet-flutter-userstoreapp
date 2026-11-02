import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mirrors the website's "1 Cart — 2 Delivery — 3 Payment/Confirmation"
/// progress breadcrumb shown on both the cart and checkout pages.
class CheckoutBreadcrumb extends StatelessWidget {
  const CheckoutBreadcrumb({super.key, required this.currentStep, this.lastLabel = 'Confirmation'});

  /// 0 = Cart, 1 = Delivery, 2 = Confirmation/Payment.
  final int currentStep;
  final String lastLabel;

  @override
  Widget build(BuildContext context) {
    final steps = ['Cart', 'Delivery', lastLabel];
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final segmentIndex = i ~/ 2;
            final done = segmentIndex < currentStep;
            return Container(
              width: 28,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: done ? AppColors.primary : AppColors.border,
            );
          }
          final index = i ~/ 2;
          final active = index == currentStep;
          final done = index < currentStep;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active || done ? AppColors.primary : AppColors.border,
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : Text('${index + 1}',
                        style: TextStyle(
                            color: active ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Text(steps[index],
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? AppColors.primary : AppColors.textSecondary)),
            ],
          );
        }),
      ),
    );
  }
}
