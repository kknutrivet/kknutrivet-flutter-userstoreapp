import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../models/pet.dart';
import '../../../providers/app_providers.dart';
import 'care_chat_intake_steps.dart';

class _CareIntakeCopy {
  const _CareIntakeCopy({
    required this.animalLabel,
    required this.concernLabel,
    required this.hint,
    required this.placeholder,
    required this.submit,
    required this.starting,
    required this.optionalMedia,
    required this.afterHoursTitle,
    required this.afterHoursBody,
  });

  final String animalLabel;
  final String concernLabel;
  final String hint;
  final String placeholder;
  final String submit;
  final String starting;
  final String optionalMedia;
  final String afterHoursTitle;
  final String afterHoursBody;
}

const Map<String, _CareIntakeCopy> _kCopyByLanguage = {
  'English': _CareIntakeCopy(
    animalLabel: 'Which animal needs help?',
    concernLabel: 'Describe the concern',
    hint: 'Tell us what you noticed and when it started.',
    placeholder: 'e.g., My dog has not eaten since yesterday.',
    submit: 'Start Free Vet Chat',
    starting: 'Starting…',
    optionalMedia: 'Optional: attach photo or short video',
    afterHoursTitle: 'Consultation hours: 10 AM – 10 PM IST',
    afterHoursBody:
        'You can still share your concern now — our veterinary team will review it and update you here & via SMS after 10 AM.',
  ),
  'Hindi': _CareIntakeCopy(
    animalLabel: 'किस जानवर को मदद चाहिए?',
    concernLabel: 'समस्या और लक्षण बताएं',
    hint: 'संक्षेप में बताएं क्या दिक्कत है और कब से शुरू हुई है।',
    placeholder: 'उदाहरण: मेरा डॉग कल से खाना नहीं खा रहा है।',
    submit: 'मुफ़्त डॉक्टर चैट शुरू करें',
    starting: 'शुरू हो रहा है…',
    optionalMedia: 'वैकल्पिक: फोटो या छोटा वीडियो जोड़ें',
    afterHoursTitle: 'परामर्श समय: सुबह 10 बजे – रात 10 बजे',
    afterHoursBody:
        'आप अभी अपनी समस्या भेज सकते हैं — हमारी डॉक्टर टीम सुबह 10 बजे के बाद जांच कर यहीं चैट और SMS पर जवाब देगी।',
  ),
  'Odia': _CareIntakeCopy(
    animalLabel: 'କେଉଁ ପ୍ରାଣୀକୁ ସାହାଯ୍ୟ ଦରକାର?',
    concernLabel: 'ସମସ୍ୟା ଓ ଲକ୍ଷଣ କୁହନ୍ତୁ',
    hint: 'କ’ଣ ଅସୁବିଧା ହେଉଛି ଏବଂ କେବେଠାରୁ ଆରମ୍ଭ ହୋଇଛି ସଂକ୍ଷେପରେ ଲେଖନ୍ତୁ।',
    placeholder: 'ଉଦାହରଣ: ମୋ କୁକୁର ଗତକାଲିଠାରୁ ଖାଉନାହିଁ।',
    submit: 'ମାଗଣା ଡାକ୍ତର ଚାଟ୍ ଆରମ୍ଭ କରନ୍ତୁ',
    starting: 'ଆରମ୍ଭ ହେଉଛି…',
    optionalMedia: 'ଐଚ୍ଛିକ: ଫଟୋ କିମ୍ବା ଭିଡିଓ ଯୋଡନ୍ତୁ',
    afterHoursTitle: 'ପରାମର୍ଶ ସମୟ: ସକାଳ 10 ଟା – ରାତି 10 ଟା',
    afterHoursBody:
        'ଆପଣ ଏବେ ସମସ୍ୟା ପଠାଇପାରିବେ — ସକାଳ 10 ଟା ପରେ ଆମ ଡାକ୍ତର ଦଳ ଦେଖି ଏହି ଚାଟ୍ ଓ SMS ରେ ଉତ୍ତର ଦେବେ।',
  ),
  'Telugu': _CareIntakeCopy(
    animalLabel: 'ఏ జంతువుకు సహాయం కావాలి?',
    concernLabel: 'సమస్యను వివరించండి',
    hint: 'ఏమి సమస్య కనిపించింది మరియు ఎప్పుడు మొదలైందో సంక్షిప్తంగా రాయండి.',
    placeholder: 'ఉదాహరణ: నా కుక్క నిన్నటి నుండి ఆహారం తినడం లేదు.',
    submit: 'ఉచిత డాక్టర్ చాట్ ప్రారంభించండి',
    starting: 'ప్రారంభమవుతోంది…',
    optionalMedia: 'ఐచ్ఛికం: ఫోటో లేదా వీడియో జత చేయండి',
    afterHoursTitle: 'సంప్రదింపు సమయం: ఉదయం 10 – రాత్రి 10',
    afterHoursBody:
        'మీరు ఇప్పుడే మీ సమస్యను పంచుకోవచ్చు — ఉదయం 10 తర్వాత మా డాక్టర్ బృందం సమీక్షించి ఇక్కడ & SMS ద్వారా అప్‌డేట్ ఇస్తుంది.',
  ),
  'Tamil': _CareIntakeCopy(
    animalLabel: 'எந்த விலங்கிற்கு உதவி தேவை?',
    concernLabel: 'பிரச்சினையை விவரிக்கவும்',
    hint: 'என்ன பிரச்சினை மற்றும் எப்போது தொடங்கியது என்பதை சுருக்கமாக எழுதுங்கள்.',
    placeholder: 'உதாரணம்: என் நாய் நேற்று முதல் சாப்பிடவில்லை.',
    submit: 'இலவச மருத்துவர் அரட்டையைத் தொடங்கு',
    starting: 'தொடங்குகிறது…',
    optionalMedia: 'விருப்பம்: புகைப்படம் அல்லது வீடியோ சேர்க்கவும்',
    afterHoursTitle: 'ஆலோசனை நேரம்: காலை 10 – இரவு 10',
    afterHoursBody:
        'இப்போதே உங்கள் பிரச்சினையைப் பகிரலாம் — காலை 10 மணிக்குப் பிறகு எங்கள் மருத்துவக் குழு பரிசீலித்து இங்கும் SMS மூலமும் பதிலளிக்கும்.',
  ),
};

bool isIstConsultationHours([DateTime? now]) {
  final utc = (now ?? DateTime.now()).toUtc();
  final ist = utc.add(const Duration(hours: 5, minutes: 30));
  return ist.hour >= 10 && ist.hour < 22;
}

String careLanguageForLocale(AppLocale locale) {
  switch (locale) {
    case AppLocale.hi:
      return 'Hindi';
    case AppLocale.or_:
      return 'Odia';
    case AppLocale.te:
      return 'Telugu';
    case AppLocale.ta:
      return 'Tamil';
    case AppLocale.en:
      return 'English';
  }
}

/// Single-screen Care Chat intake matching `CareChatIntakeBot.tsx` on mobile web:
/// Inline language pills + `Free Chat · 10 AM–10 PM` badge + IST after-hours notice +
/// Verified SMS mobile pill (with inline Change) + 1-tap animal chips +
/// symptoms textarea + full-width Submit CTA directly below + optional photo/video.
class CareChatSingleScreenIntake extends ConsumerStatefulWidget {
  const CareChatSingleScreenIntake({
    super.key,
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
    required this.onSelectPetProfile,
    required this.onSelectAnimal,
    required this.onConcernChanged,
    required this.onPickAndUploadPhoto,
    required this.onRemovePhoto,
    required this.onSubmit,
    this.errorText,
  });

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
  final ValueChanged<PetProfile> onSelectPetProfile;
  final ValueChanged<String> onSelectAnimal;
  final ValueChanged<String> onConcernChanged;
  final VoidCallback onPickAndUploadPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onSubmit;
  final String? errorText;

  @override
  ConsumerState<CareChatSingleScreenIntake> createState() =>
      _CareChatSingleScreenIntakeState();
}

class _CareChatSingleScreenIntakeState
    extends ConsumerState<CareChatSingleScreenIntake> {
  bool _editingPhone = false;

  @override
  Widget build(BuildContext context) {
    final languages =
        ref.watch(careIntakeLanguagesProvider).valueOrNull ??
        const ['English', 'Hindi', 'Odia', 'Telugu', 'Tamil'];
    final copy =
        _kCopyByLanguage[widget.selectedLanguage] ??
        _kCopyByLanguage['English']!;
    final afterHours = !isIstConsultationHours();
    final phoneDigits = widget.phoneController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );
    final hasValidPhone = phoneDigits.length >= 10;
    final displayPhone = hasValidPhone
        ? phoneDigits.substring(phoneDigits.length - 10)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Inline language pills + Free Chat · 10 AM–10 PM badge
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  for (final lang in languages)
                    _pillChip(
                      label: kCareLanguageDisplayNames[lang]?.split(' ').first ??
                          lang,
                      selected: widget.selectedLanguage == lang,
                      onTap: () {
                        AppHaptics.selection();
                        widget.onSelectLanguage(lang);
                      },
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Free Chat · 10 AM–10 PM',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. IST After-hours notice
              if (afterHours) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.afterHoursTitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        copy.afterHoursBody,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF78350F),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 3. Verified SMS mobile pill (with inline Change)
              const SizedBox(height: 10),
              if (hasValidPhone && !_editingPhone)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SMS updates: +91 $displayPhone ✓',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _editingPhone = true),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDeep,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: '10-digit mobile for SMS updates',
                              prefixText: '+91 ',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (_editingPhone) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () =>
                                setState(() => _editingPhone = false),
                            child: const Text('Done'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

              // 4. Saved pets quick-fill (if user has pets)
              if (widget.savedPets.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final pet in widget.savedPets)
                      _pillChip(
                        label: '${pet.name} (${pet.animalType})',
                        selected: widget.selectedPetProfileId == pet.id,
                        onTap: () {
                          AppHaptics.selection();
                          widget.onSelectPetProfile(pet);
                        },
                      ),
                  ],
                ),
              ],

              // 5. 1-tap Animal selector
              const SizedBox(height: 12),
              Text(
                copy.animalLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in careChatAnimals)
                    _pillChip(
                      label: entry.$1,
                      selected: widget.selectedAnimal == entry.$1,
                      onTap: () {
                        AppHaptics.selection();
                        widget.onSelectAnimal(entry.$1);
                      },
                    ),
                ],
              ),
              if (widget.selectedAnimal == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: widget.otherAnimalController,
                  decoration: InputDecoration(
                    hintText: 'Enter animal name',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],

              // 6. Symptoms textarea + Submit directly underneath
              const SizedBox(height: 14),
              Text(
                copy.concernLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                copy.hint,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: widget.concernController,
                enabled: !widget.submitting,
                maxLines: 3,
                maxLength: 1000,
                onChanged: widget.onConcernChanged,
                decoration: InputDecoration(
                  hintText: copy.placeholder,
                  counterText: '',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderWarm),
                  ),
                ),
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),

              if (widget.errorText != null &&
                  widget.errorText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: widget.submitting ? null : widget.onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF07583F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: widget.submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    widget.submitting ? copy.starting : copy.submit,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // 7. Optional photo/video attachment neatly below CTA
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderWarm),
              const SizedBox(height: 10),
              Text(
                copy.optionalMedia,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.uploadedPhotoUrl != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWashFaint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryWashDeep),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attachment_rounded,
                        size: 16,
                        color: AppColors.primaryDeep,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.uploadedPhotoName ?? 'Attached media',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: widget.onRemovePhoto,
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: widget.uploadingPhoto
                      ? null
                      : widget.onPickAndUploadPhoto,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDeep,
                    side: const BorderSide(color: AppColors.borderWarm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: widget.uploadingPhoto
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: Text(
                    widget.uploadingPhoto
                        ? 'Uploading…'
                        : 'Attach photo or video',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'For emergencies, contact your nearest veterinary hospital immediately.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _pillChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFF07583F) : const Color(0xFFFAFBF9),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? const Color(0xFF07583F) : AppColors.borderWarm,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.primaryDeep,
            ),
          ),
        ),
      ),
    );
  }
}
