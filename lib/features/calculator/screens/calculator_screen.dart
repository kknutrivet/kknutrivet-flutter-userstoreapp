import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _weightController = TextEditingController(text: '12');
  String _species = 'Dog';
  String _activity = 'Normal';
  String _condition = 'Ideal';
  String _dietType = 'Dry Food (Kibble)';
  int _mealsPerDay = 2;

  double? _dailyCalories;
  int? _dailyGrams;

  static const _activities = [
    ('Low / Inactive', 1.2),
    ('Normal', 1.6),
    ('Active / Playful', 1.8),
    ('Working / High Energy', 2.2),
  ];

  static const _conditions = [
    ('Underweight', 1.15),
    ('Ideal', 1.0),
    ('Overweight', 0.85),
  ];

  static const _dietEnergyDensities = {
    'Dry Food (Kibble)': 375.0, // kcal per 100g
    'Wet Food / Gravy': 95.0, // kcal per 100g
    'Home Cooked': 140.0, // kcal per 100g
  };

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      setState(() {
        _dailyCalories = null;
        _dailyGrams = null;
      });
      return;
    }

    // RER formula: 70 * (weight in kg)^0.75
    final rer = 70.0 * math.pow(weight, 0.75);

    // Activity multiplier
    final activityMultiplier = _activities
        .firstWhere((a) => a.$1 == _activity, orElse: () => _activities[1])
        .$2;

    // Body condition factor
    final conditionMultiplier = _conditions
        .firstWhere((c) => c.$1 == _condition, orElse: () => _conditions[1])
        .$2;

    final catFactor = _species == 'Cat' ? 0.9 : 1.0;
    final totalCalories =
        rer * activityMultiplier * conditionMultiplier * catFactor;

    // Grams based on diet energy density
    final density = _dietEnergyDensities[_dietType] ?? 375.0;
    final totalGrams = (totalCalories / density) * 100.0;

    setState(() {
      _dailyCalories = totalCalories;
      _dailyGrams = totalGrams.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Nutrition Calculator',
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
            // Header info banner
            AppCard(
              variant: AppCardVariant.tinted,
              backgroundColor: const Color(0xFFF0F7F4),
              borderColor: const Color(0xFFCDE4D8),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: AppColors.primaryDeep,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Veterinary Energy Requirement (MER)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Estimates daily calories (kcal) and feeding portions based on species, weight, condition and diet density.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF38594C),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Inputs card
            AppCard(
              variant: AppCardVariant.elevated,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Species Toggle
                  const Text(
                    'Species',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Dog', 'Cat'].map((s) {
                      final sel = _species == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            s == 'Dog'
                                ? Icons.pets_rounded
                                : Icons.cruelty_free_rounded,
                            size: 15,
                            color: sel
                                ? AppColors.primaryDeep
                                : AppColors.textSecondary,
                          ),
                          label: Text(s),
                          selected: sel,
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? AppColors.primaryDeep
                                : AppColors.textSecondary,
                          ),
                          selectedColor: AppColors.primaryWash,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.borderWarm,
                            ),
                          ),
                          onSelected: (_) {
                            AppHaptics.selection();
                            setState(() => _species = s);
                            _calculate();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Weight input
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Weight (kg)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => _calculate(),
                              decoration: InputDecoration(
                                suffixText: 'kg',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Activity level
                  const Text(
                    'Daily Activity Level',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activities.map((a) {
                      final sel = _activity == a.$1;
                      return ChoiceChip(
                        label: Text(a.$1),
                        selected: sel,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel
                              ? AppColors.primaryDeep
                              : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.primaryWash,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: sel
                                ? AppColors.primary
                                : AppColors.borderWarm,
                          ),
                        ),
                        onSelected: (_) {
                          AppHaptics.selection();
                          setState(() => _activity = a.$1);
                          _calculate();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Body Condition
                  const Text(
                    'Body Condition',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    runSpacing: 8,
                    children: _conditions.map((c) {
                      final sel = _condition == c.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.$1),
                          selected: sel,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? AppColors.primaryDeep
                                : AppColors.textSecondary,
                          ),
                          selectedColor: AppColors.primaryWash,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.borderWarm,
                            ),
                          ),
                          onSelected: (_) {
                            AppHaptics.selection();
                            setState(() => _condition = c.$1);
                            _calculate();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Diet Type
                  const Text(
                    'Food Type / Diet',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietEnergyDensities.keys.map((d) {
                      final sel = _dietType == d;
                      return ChoiceChip(
                        label: Text(d),
                        selected: sel,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel
                              ? AppColors.primaryDeep
                              : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.primaryWash,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: sel
                                ? AppColors.primary
                                : AppColors.borderWarm,
                          ),
                        ),
                        onSelected: (_) {
                          AppHaptics.selection();
                          setState(() => _dietType = d);
                          _calculate();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Meals per day
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Meals Per Day:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      for (int m = 1; m <= 3; m++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$m ${m == 1 ? 'meal' : 'meals'}'),
                            selected: _mealsPerDay == m,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _mealsPerDay == m
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _mealsPerDay == m
                                  ? AppColors.primaryDeep
                                  : AppColors.textSecondary,
                            ),
                            selectedColor: AppColors.primaryWash,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: _mealsPerDay == m
                                    ? AppColors.primary
                                    : AppColors.borderWarm,
                              ),
                            ),
                            onSelected: (_) {
                              AppHaptics.selection();
                              setState(() => _mealsPerDay = m);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Output Result Card
            if (_dailyCalories != null && _dailyGrams != null) ...[
              AppCard(
                variant: AppCardVariant.tinted,
                backgroundColor: AppColors.primaryDeep,
                borderColor: AppColors.primaryDeepest,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily nutrition estimate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_species · ${_weightController.text} kg',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Energy Need',
                                style: TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_dailyCalories!.round()} kcal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 50, color: Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Food',
                                style: TextStyle(
                                  color: Color(0xFFD1FAE5),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_dailyGrams g / day',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restaurant_rounded,
                            size: 15,
                            color: Color(0xFFD1FAE5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Portion per serving: ${(_dailyGrams! / _mealsPerDay).round()} g ($_mealsPerDay meals daily)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bottom actions
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Browse Food',
                      icon: const Icon(Icons.shopping_bag_outlined, size: 15),
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      onPressed: () {
                        AppHaptics.light();
                        context.push('/shop');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Care team chat',
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                      ),
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.md,
                      onPressed: () {
                        AppHaptics.light();
                        context.push('/consultations');
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
