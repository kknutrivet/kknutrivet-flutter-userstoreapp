import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared visual identity for arrival, guidance and service status screens.
class WelcomeArt extends StatelessWidget {
  const WelcomeArt({super.key, required this.icon, this.label = 'KK NUTRIVET'});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppColors.primaryDeep,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
      const SizedBox(height: 28),
      Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFFE5EAC0), size: 64)),
      const SizedBox(height: 28),
      const Text('Care for every animal.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
    ]),
  );
}
