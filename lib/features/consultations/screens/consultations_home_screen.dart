import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/consultation.dart';
import '../../../models/pet.dart';
import '../../../providers/app_providers.dart';
import '../widgets/care_chat_intake_steps.dart';
import '../widgets/care_chat_workspace_header.dart';
import '../widgets/past_consultations_list.dart';

final myConsultationsProvider =
    FutureProvider.autoDispose<List<ConsultationBooking>>((ref) {
      return ref.read(consultationServiceProvider).fetchMyConsultations();
    });

final _careChatPetsProvider = FutureProvider.autoDispose<List<PetProfile>>((
  ref,
) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null || user.isAnonymous) return Future.value(const []);
  return ref.read(petServiceProvider).fetchPets();
});

class ConsultationsHomeScreen extends ConsumerStatefulWidget {
  const ConsultationsHomeScreen({super.key});

  @override
  ConsumerState<ConsultationsHomeScreen> createState() =>
      _ConsultationsHomeScreenState();
}

class _ConsultationsHomeScreenState
    extends ConsumerState<ConsultationsHomeScreen> {
  bool _showPastConsultations = false;
  int _step = 0; // 0: Language, 1: Contact, 2: Animal, 3: Concern

  String _selectedLanguage = 'English';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otherAnimalController = TextEditingController();
  final TextEditingController _concernController = TextEditingController();

  String _selectedAnimal = '';
  String? _selectedPetProfileId;
  String? _uploadedPhotoUrl;
  String? _uploadedPhotoName;
  bool _uploadingPhoto = false;
  bool _submitting = false;
  String? _errorText;
  late String _requestId;
  bool _prefilledFromUser = false;

  @override
  void initState() {
    super.initState();
    _requestId = _generateRequestId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otherAnimalController.dispose();
    _concernController.dispose();
    super.dispose();
  }

  String _generateRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  void _syncUserPrefill() {
    if (_prefilledFromUser) return;
    final user = ref.read(authProvider).valueOrNull;
    if (user != null && !user.isAnonymous) {
      if (_nameController.text.trim().isEmpty &&
          (user.name?.trim().isNotEmpty ?? false)) {
        _nameController.text = user.name!.trim();
      }
      if (_phoneController.text.trim().isEmpty &&
          (user.phone?.trim().isNotEmpty ?? false)) {
        final digits = user.phone!.replaceAll(RegExp(r'\D'), '');
        _phoneController.text = digits.length >= 10
            ? digits.substring(digits.length - 10)
            : digits;
      }
      _prefilledFromUser = true;
    }
  }

  void _startNewChat() {
    AppHaptics.light();
    setState(() {
      _showPastConsultations = false;
      _step = 0;
      _selectedAnimal = '';
      _selectedPetProfileId = null;
      _otherAnimalController.clear();
      _concernController.clear();
      _uploadedPhotoUrl = null;
      _uploadedPhotoName = null;
      _errorText = null;
      _requestId = _generateRequestId();
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto || _submitting) return;
    AppHaptics.selection();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() {
      _uploadingPhoto = true;
      _errorText = null;
    });
    try {
      final url = await ref
          .read(uploadServiceProvider)
          .uploadImage(picked.path, purpose: 'care-chat');
      if (!mounted) return;
      setState(() {
        _uploadedPhotoUrl = url;
        _uploadedPhotoName = picked.name;
      });
      showToast('Photo attached');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      showToast(msg, isError: true);
      setState(() => _errorText = msg);
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  void _continueFromContact() {
    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phone = rawPhone.length == 12 && rawPhone.startsWith('91')
        ? rawPhone.substring(2)
        : rawPhone;

    if (name.isEmpty) {
      const msg = 'Please enter your name.';
      showToast(msg, isError: true);
      setState(() => _errorText = msg);
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      const msg = 'Please enter a valid 10-digit mobile number.';
      showToast(msg, isError: true);
      setState(() => _errorText = msg);
      return;
    }
    AppHaptics.light();
    setState(() {
      _phoneController.text = phone;
      _errorText = null;
      _step = 2;
    });
  }

  void _continueFromAnimal() {
    if (_selectedAnimal.isEmpty) {
      const msg = 'Please select which animal needs care.';
      showToast(msg, isError: true);
      setState(() => _errorText = msg);
      return;
    }
    if (_selectedAnimal == 'Other' &&
        _otherAnimalController.text.trim().isEmpty) {
      const msg = 'Please enter the animal name.';
      showToast(msg, isError: true);
      setState(() => _errorText = msg);
      return;
    }
    AppHaptics.light();
    setState(() {
      _errorText = null;
      _step = 3;
    });
  }

  Future<void> _submitCareChat() async {
    if (_submitting || _uploadingPhoto) return;
    final concern = _concernController.text.trim();
    if (concern.isEmpty) {
      const msg = 'Describe your concern before starting the consultation.';
      showToast(msg, isError: true);
      setState(() => _errorText = msg);
      return;
    }

    AppHaptics.light();
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final booking = await ref
          .read(consultationServiceProvider)
          .startCareChat(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            animalType: _selectedAnimal,
            otherAnimalName: _selectedAnimal == 'Other'
                ? _otherAnimalController.text.trim()
                : null,
            concern: concern,
            language: _selectedLanguage,
            mediaUrl: _uploadedPhotoUrl,
            mediaType: _uploadedPhotoUrl != null ? 'IMAGE' : null,
            requestId: _requestId,
            petProfileId: _selectedPetProfileId,
          );
      if (!mounted) return;
      ref.invalidate(myConsultationsProvider);
      _requestId = _generateRequestId();
      context.push('/consultations/${booking.id}');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      showToast(msg, isError: true);
      setState(() => _errorText = msg);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _goToSignIn() {
    AppHaptics.light();
    ref.read(pendingAuthRedirectProvider.notifier).state = '/consultations';
    context.push('/login');
  }

  void _handleSelectPetProfile(PetProfile pet) {
    setState(() {
      if (_selectedPetProfileId == pet.id) {
        _selectedPetProfileId = null;
      } else {
        _selectedPetProfileId = pet.id;
        final match = careChatAnimals.any(
          (a) => a.$1.toLowerCase() == pet.animalType.toLowerCase(),
        );
        if (match) {
          _selectedAnimal = careChatAnimals
              .firstWhere(
                (a) => a.$1.toLowerCase() == pet.animalType.toLowerCase(),
              )
              .$1;
        } else {
          _selectedAnimal = 'Other';
          _otherAnimalController.text = pet.animalType;
        }
      }
    });
  }

  void _goToStep(int targetStep) {
    setState(() {
      _errorText = null;
      _step = targetStep;
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncUserPrefill();
    final consultationsAsync = ref.watch(myConsultationsProvider);
    final bookings = consultationsAsync.valueOrNull ?? const [];
    final user = ref.watch(authProvider).valueOrNull;
    final isSignedIn = user != null && !user.isAnonymous;
    final savedPets = ref.watch(_careChatPetsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: !isSignedIn
          ? AppBar(
              toolbarHeight: 54,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Image.asset(
                'assets/images/logo.png',
                height: 32,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, _, _) => const Text(
                  'KK NUTRIVET',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
              actions: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2ECE6)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.videocam_outlined,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.push('/consultations'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2ECE6)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () =>
                        setState(() => _showPastConsultations = true),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            )
          : CareChatWorkspaceAppBar(
              showPastConsultations: _showPastConsultations,
              pastCount: bookings.length,
              onStartNewChat: _startNewChat,
              onSelectCurrent: () {
                AppHaptics.selection();
                setState(() => _showPastConsultations = false);
              },
              onSelectPast: () {
                AppHaptics.selection();
                setState(() => _showPastConsultations = true);
              },
            ),
      body: _showPastConsultations
          ? PastConsultationsListView(
              consultationsAsync: consultationsAsync,
              onRefresh: () async {
                ref.invalidate(myConsultationsProvider);
                await ref.read(myConsultationsProvider.future);
              },
              onRetry: () => ref.invalidate(myConsultationsProvider),
              onOpenChat: (booking) {
                AppHaptics.light();
                context.push('/consultations/${booking.id}');
              },
            )
          : (!isSignedIn
              ? _buildCareChatSignIn(context)
              : _buildIntakeWorkspace(isSignedIn, savedPets)),
      bottomNavigationBar: _showPastConsultations
          ? PastConsultationsStickyNewBar(onStartNewChat: _startNewChat)
          : (_step == 3 && isSignedIn
                ? CareChatStickySubmitBar(
                    submitting: _submitting,
                    uploadingPhoto: _uploadingPhoto,
                    onBack: () => _goToStep(2),
                    onSubmit: _submitCareChat,
                  )
                : null),
    );
  }

  Widget _buildCareChatSignIn(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCEEE3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E075B43),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F5EF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCDE4D8)),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 20,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'KK Nutrivet care team',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'A caring conversation starts here.',
                      style: AppTheme.serif(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Have a concern about your animal? Sign in, share what’s happening, and talk to our care team.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          AppHaptics.light();
                          context.push('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeep,
                          foregroundColor: Colors.white,
                          iconColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 13, color: AppColors.textTertiary),
                          SizedBox(width: 4),
                          Text(
                            'Your conversation stays private.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6FAF7),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: Color(0xFFE8F1EC))),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your care chat, in one place',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.chat_bubble_outline_rounded,
                      'Tell us your concern',
                      'A few details help the team understand.',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureItem(
                      Icons.camera_alt_outlined,
                      'Show what you’ve noticed',
                      'Add a photo or video if it helps.',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureItem(
                      Icons.favorite_outline_rounded,
                      'Stay connected',
                      'Return here for replies and your chat history.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDCEEE3)),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryDeep),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntakeWorkspace(bool isSignedIn, List<PetProfile> savedPets) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        CareChatSummaryChipsBar(
          step: _step,
          selectedLanguage: _selectedLanguage,
          contactName: _nameController.text,
          contactPhone: _phoneController.text,
          selectedAnimal: _selectedAnimal,
          otherAnimalName: _otherAnimalController.text,
          onStepTap: _goToStep,
        ),
        CareChatIntakeWorkspaceCard(
          step: _step,
          header: CareChatIntakeCardHeader(step: _step),
          isSignedIn: isSignedIn,
          selectedLanguage: _selectedLanguage,
          nameController: _nameController,
          phoneController: _phoneController,
          savedPets: savedPets,
          selectedPetProfileId: _selectedPetProfileId,
          selectedAnimal: _selectedAnimal,
          otherAnimalController: _otherAnimalController,
          concernController: _concernController,
          submitting: _submitting,
          uploadingPhoto: _uploadingPhoto,
          uploadedPhotoUrl: _uploadedPhotoUrl,
          uploadedPhotoName: _uploadedPhotoName,
          onSelectLanguage: (code) => setState(() {
            _selectedLanguage = code;
            _errorText = null;
            _step = 1;
          }),
          onContinueContact: _continueFromContact,
          onSelectPetProfile: _handleSelectPetProfile,
          onSelectAnimal: (animal) => setState(() {
            _selectedAnimal = animal;
            _errorText = null;
          }),
          onContinueAnimal: _continueFromAnimal,
          onConcernChanged: (_) => setState(() {
            if (_errorText != null) _errorText = null;
          }),
          onPickAndUploadPhoto: _pickAndUploadPhoto,
          onRemovePhoto: () => setState(() {
            _uploadedPhotoUrl = null;
            _uploadedPhotoName = null;
          }),
          onStepBack: _goToStep,
          onSignInTap: _goToSignIn,
          errorText: _errorText,
        ),
      ],
    );
  }
}
