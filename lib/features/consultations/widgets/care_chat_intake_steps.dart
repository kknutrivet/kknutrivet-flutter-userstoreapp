import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../models/pet.dart';

const List<(String code, String label)> careChatLanguages = [
  ('English', 'English'),
  ('Hindi', 'हिन्दी (Hindi)'),
  ('Kannada', 'ಕನ್ನಡ (Kannada)'),
  ('Odia', 'ଓଡ଼ିଆ (Odia)'),
  ('Bengali', 'বাংলা (Bengali)'),
  ('Telugu', 'తెలుగు (Telugu)'),
  ('Tamil', 'தமிழ் (Tamil)'),
  ('Marathi', 'मराठी (Marathi)'),
];

const List<(String name, IconData icon)> careChatAnimals = [
  ('Dog', Icons.pets_rounded),
  ('Cat', Icons.cruelty_free_rounded),
  ('Cattle', Icons.agriculture_rounded),
  ('Goat', Icons.grass_rounded),
  ('Poultry', Icons.egg_alt_rounded),
  ('Other', Icons.add_circle_outline_rounded),
];

class CareChatStep1Language extends StatelessWidget {
  const CareChatStep1Language({
    super.key,
    required this.selectedLanguage,
    required this.onSelectLanguage,
  });

  final String selectedLanguage;
  final ValueChanged<String> onSelectLanguage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Which language are you comfortable with?',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose your preferred language. We’ll remember it and share it with the care team.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: careChatLanguages.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
          ),
          itemBuilder: (context, index) {
            final (code, label) = careChatLanguages[index];
            final selected = selectedLanguage == code;
            return Material(
              color: selected ? AppColors.primaryWash : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  AppHaptics.selection();
                  onSelectLanguage(code);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.borderWarm,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class CareChatStep2Contact extends StatelessWidget {
  const CareChatStep2Contact({
    super.key,
    required this.isSignedIn,
    required this.nameController,
    required this.phoneController,
    required this.onBack,
    required this.onContinue,
    required this.onSignInTap,
  });

  final bool isSignedIn;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
      return CareChatSignInRequiredCard(onSignInTap: onSignInTap);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your contact details',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            hintText: 'What is your name?',
            counterText: '',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            labelText: '10-digit Mobile Number',
            hintText: '9876543210',
            prefixText: '+91 ',
            prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.primaryWashFaint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryWashDeep),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.sms_outlined,
                size: 17,
                color: AppColors.primaryDeep,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "We'll send an SMS alert to this number as soon as the vet replies.",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDeep,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(88, 48),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CareChatSignInRequiredCard extends StatelessWidget {
  const CareChatSignInRequiredCard({
    super.key,
    required this.onSignInTap,
  });

  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryWashFaint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryWashDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryWash,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  color: AppColors.primaryDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sign in to start your Care Chat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in with your mobile number or account so our veterinary team can save your chat history, prescriptions, and send SMS updates.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onSignInTap,
            icon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
            label: const Text('Sign in to Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: Colors.white,
              iconColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class CareChatStep3Animal extends StatelessWidget {
  const CareChatStep3Animal({
    super.key,
    required this.savedPets,
    required this.selectedPetProfileId,
    required this.selectedAnimal,
    required this.otherAnimalController,
    required this.onSelectPetProfile,
    required this.onSelectAnimal,
    required this.onBack,
    required this.onContinue,
  });

  final List<PetProfile> savedPets;
  final String? selectedPetProfileId;
  final String selectedAnimal;
  final TextEditingController otherAnimalController;
  final ValueChanged<PetProfile> onSelectPetProfile;
  final ValueChanged<String> onSelectAnimal;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Which animal needs help?',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (savedPets.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Saved Pet Profiles (optional):',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: savedPets.map((pet) {
              final isSelected = selectedPetProfileId == pet.id;
              return ChoiceChip(
                label: Text('${pet.name} (${capitalize(pet.animalType)})'),
                selected: isSelected,
                onSelected: (_) {
                  AppHaptics.selection();
                  onSelectPetProfile(pet);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: careChatAnimals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final (animal, icon) = careChatAnimals[index];
            final selected = selectedAnimal == animal;
            return Material(
              color: selected ? AppColors.primaryDeep : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  AppHaptics.selection();
                  onSelectAnimal(animal);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryDeep
                          : AppColors.borderWarm,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected ? Colors.white : AppColors.primaryDeep,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        animal,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (selectedAnimal == 'Other') ...[
          const SizedBox(height: 12),
          TextField(
            controller: otherAnimalController,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Enter animal name',
              hintText: 'e.g. Horse, Rabbit, Parrot',
              counterText: '',
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(88, 48),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CareChatStep4Concern extends StatelessWidget {
  const CareChatStep4Concern({
    super.key,
    required this.isSignedIn,
    required this.concernController,
    required this.submitting,
    required this.uploadingPhoto,
    required this.uploadedPhotoUrl,
    required this.uploadedPhotoName,
    required this.onConcernChanged,
    required this.onPickAndUploadPhoto,
    required this.onRemovePhoto,
    required this.onSignInTap,
  });

  final bool isSignedIn;
  final TextEditingController concernController;
  final bool submitting;
  final bool uploadingPhoto;
  final String? uploadedPhotoUrl;
  final String? uploadedPhotoName;
  final ValueChanged<String> onConcernChanged;
  final VoidCallback onPickAndUploadPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
      return CareChatSignInRequiredCard(onSignInTap: onSignInTap);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe the concern in your own words.',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tell us what you noticed and when it started. A short description is enough.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: concernController,
          maxLines: 4,
          maxLength: 1000,
          enabled: !submitting,
          onChanged: onConcernChanged,
          decoration: const InputDecoration(
            hintText: 'For example: My dog has not eaten since yesterday.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderWarm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a photo (optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: uploadingPhoto || submitting
                        ? null
                        : onPickAndUploadPhoto,
                    icon: uploadingPhoto
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_outlined, size: 17),
                    label: Text(
                      uploadingPhoto
                          ? 'Uploading…'
                          : (uploadedPhotoUrl != null
                                ? 'Change Photo'
                                : 'Attach Photo'),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(130, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                  if (uploadedPhotoName != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        uploadedPhotoName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: submitting ? null : onRemovePhoto,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Remove photo',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryWashFaint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryWashDeep),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: AppColors.primaryDeep,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Send up to 5 messages while waiting. Photos and videos count separately. You can send more after the team replies.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDeep,
                    height: 1.38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CareChatErrorBanner extends StatelessWidget {
  const CareChatErrorBanner({super.key, required this.errorText});

  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CareChatStickySubmitBar extends StatelessWidget {
  const CareChatStickySubmitBar({
    super.key,
    required this.submitting,
    required this.uploadingPhoto,
    required this.onBack,
    required this.onSubmit,
  });

  final bool submitting;
  final bool uploadingPhoto;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderWarm)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Row(
          children: [
            OutlinedButton(
              onPressed: submitting ? null : onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(88, 48),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: submitting || uploadingPhoto ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                label: Text(submitting ? 'Starting…' : 'Start consultation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: Colors.white,
                  iconColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class CareChatIntakeWorkspaceCard extends StatelessWidget {
  const CareChatIntakeWorkspaceCard({
    super.key,
    required this.step,
    required this.header,
    required this.isSignedIn,
    required this.selectedLanguage,
    required this.nameController,
    required this.phoneController,
    required this.savedPets,
    required this.selectedPetProfileId,
    required this.selectedAnimal,
    required this.otherAnimalController,
    required this.concernController,
    required this.submitting,
    required this.uploadingPhoto,
    required this.uploadedPhotoUrl,
    required this.uploadedPhotoName,
    required this.onSelectLanguage,
    required this.onContinueContact,
    required this.onSelectPetProfile,
    required this.onSelectAnimal,
    required this.onContinueAnimal,
    required this.onConcernChanged,
    required this.onPickAndUploadPhoto,
    required this.onRemovePhoto,
    required this.onStepBack,
    required this.onSignInTap,
    this.errorText,
  });

  final int step;
  final Widget header;
  final bool isSignedIn;
  final String selectedLanguage;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final List<PetProfile> savedPets;
  final String? selectedPetProfileId;
  final String selectedAnimal;
  final TextEditingController otherAnimalController;
  final TextEditingController concernController;
  final bool submitting;
  final bool uploadingPhoto;
  final String? uploadedPhotoUrl;
  final String? uploadedPhotoName;
  final ValueChanged<String> onSelectLanguage;
  final VoidCallback onContinueContact;
  final ValueChanged<PetProfile> onSelectPetProfile;
  final ValueChanged<String> onSelectAnimal;
  final VoidCallback onContinueAnimal;
  final ValueChanged<String> onConcernChanged;
  final VoidCallback onPickAndUploadPhoto;
  final VoidCallback onRemovePhoto;
  final ValueChanged<int> onStepBack;
  final VoidCallback onSignInTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final Widget stepContent = switch (step) {
      0 => CareChatStep1Language(
        selectedLanguage: selectedLanguage,
        onSelectLanguage: onSelectLanguage,
      ),
      1 => CareChatStep2Contact(
        isSignedIn: isSignedIn,
        nameController: nameController,
        phoneController: phoneController,
        onBack: () => onStepBack(0),
        onContinue: onContinueContact,
        onSignInTap: onSignInTap,
      ),
      2 => CareChatStep3Animal(
        savedPets: savedPets,
        selectedPetProfileId: selectedPetProfileId,
        selectedAnimal: selectedAnimal,
        otherAnimalController: otherAnimalController,
        onSelectPetProfile: onSelectPetProfile,
        onSelectAnimal: onSelectAnimal,
        onBack: () => onStepBack(1),
        onContinue: onContinueAnimal,
      ),
      _ => CareChatStep4Concern(
        isSignedIn: isSignedIn,
        concernController: concernController,
        submitting: submitting,
        uploadingPhoto: uploadingPhoto,
        uploadedPhotoUrl: uploadedPhotoUrl,
        uploadedPhotoName: uploadedPhotoName,
        onConcernChanged: onConcernChanged,
        onPickAndUploadPhoto: onPickAndUploadPhoto,
        onRemovePhoto: onRemovePhoto,
        onSignInTap: onSignInTap,
      ),
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              if (errorText != null) ...[
                const SizedBox(height: 14),
                CareChatErrorBanner(errorText: errorText!),
              ],
              const SizedBox(height: 18),
              stepContent,
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'Your language preference is shared with the care team. For emergencies, contact your nearest veterinary hospital immediately.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
