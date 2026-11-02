import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/pet.dart';
import '../../../providers/app_providers.dart';

final petsListProvider =
    FutureProvider.autoDispose<List<PetProfile>>((ref) {
  return ref.read(petServiceProvider).fetchPets();
});

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsListProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Pet Profiles',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        onPressed: () async {
          AppHaptics.light();
          await context.push('/pets/new');
          ref.invalidate(petsListProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Pet',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      body: SafeArea(
        top: false,
        child: petsAsync.when(
          data: (pets) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(petsListProvider);
              await ref.read(petsListProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: _PetsHeroBanner(
                      count: pets.length,
                      onAddPet: () async {
                        AppHaptics.light();
                        await context.push('/pets/new');
                        ref.invalidate(petsListProvider);
                      },
                    ),
                  ),
                ),

                if (pets.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 24),
                      child: AppEmptyState(
                        icon: Icons.pets_rounded,
                        title: 'No pet profiles yet',
                        description:
                            'Create a personalized profile to track vaccinations, deworming cycles, weight records, and tailored veterinary nutrition.',
                        actionLabel: 'Create First Pet Profile',
                        onAction: () async {
                          AppHaptics.light();
                          await context.push('/pets/new');
                          ref.invalidate(petsListProvider);
                        },
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: Row(
                        children: [
                          Text(
                            'Your Animals & Pets',
                            style: AppTheme.serif(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                          const Spacer(),
                          AppBadge(
                            label: '${pets.length} ${pets.length == 1 ? 'profile' : 'profiles'}',
                            tone: AppBadgeTone.neutral,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final pet = pets[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PetCard(
                              pet: pet,
                              onTap: () async {
                                AppHaptics.light();
                                await context.push('/pets/${pet.id}');
                                ref.invalidate(petsListProvider);
                              },
                            ),
                          );
                        },
                        childCount: pets.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: AppLoader.large()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load pet profiles',
              description: e.toString(),
              actionLabel: 'Try Again',
              onAction: () => ref.invalidate(petsListProvider),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _PetsHeroBanner extends StatelessWidget {
  const _PetsHeroBanner({required this.count, required this.onAddPet});
  final int count;
  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.tinted,
      backgroundColor: const Color(0xFFF0F7F4),
      borderColor: const Color(0xFFCDE4D8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBadge(
                label: 'PET WELLNESS PASSPORT',
                icon: Icon(Icons.verified_rounded,
                    size: 11, color: AppColors.primaryDeep),
                tone: AppBadgeTone.emerald,
              ),
              const Spacer(),
              AppBadge(
                label: '$count registered',
                tone: AppBadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Keep your animal healthy & protected',
            style: AppTheme.serif(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track scheduled vaccinations, preventive deworming dates, daily food grams, and medical history in one unified place.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF38594C),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Add Another Pet',
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            onPressed: onAddPet,
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.onTap});
  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String? nextCareLabel;
    AppBadgeTone nextCareTone = AppBadgeTone.amber;

    if (pet.nextVaccinationAt != null) {
      nextCareLabel = 'Vaccine: ${formatDate(pet.nextVaccinationAt!)}';
      nextCareTone = AppBadgeTone.emerald;
    } else if (pet.nextDewormingAt != null) {
      nextCareLabel = 'Deworm: ${formatDate(pet.nextDewormingAt!)}';
      nextCareTone = AppBadgeTone.peach;
    }

    final animalIcon = switch (pet.animalType.toLowerCase()) {
      'cat' => '🐱',
      'cattle' || 'cow' => '🐮',
      'poultry' || 'chicken' => '🐔',
      'goat' || 'sheep' => '🐐',
      _ => '🐶',
    };

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64,
              height: 64,
              color: AppColors.primaryWash,
              child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: pet.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _fallbackEmoji(animalIcon),
                    )
                  : _fallbackEmoji(animalIcon),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pet.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const AppBadge(
                      label: 'Profile ›',
                      tone: AppBadgeTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  pet.breed != null && pet.breed!.isNotEmpty
                      ? pet.breed!
                      : '${capitalize(pet.animalType)} Companion',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (pet.weightKg != null)
                      AppBadge(
                        label: '${pet.weightKg} kg',
                        tone: AppBadgeTone.neutral,
                      ),
                    if (nextCareLabel != null)
                      AppBadge(
                        label: nextCareLabel,
                        tone: nextCareTone,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackEmoji(String emoji) {
    return Center(
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 28),
      ),
    );
  }
}
