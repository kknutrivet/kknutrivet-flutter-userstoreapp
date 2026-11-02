import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key});

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _weight = TextEditingController();
  final _notes = TextEditingController();

  String? _animalType = 'Dog';
  String? _sex = 'Male';
  DateTime? _dob;
  String? _photoUrl;
  String? _localPhotoPath;
  bool _saving = false;

  static const _animalTypes = ['Dog', 'Cat', 'Cattle', 'Poultry', 'Goat/Sheep'];

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Add Pet Profile',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _photoPicker()),
                const SizedBox(height: 20),
                AppCard(
                  variant: AppCardVariant.elevated,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Pet name *',
                          hintText: 'e.g. Bruno, Bella, Shanti',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Animal Type *',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _animalTypes.map((a) {
                          final selected = _animalType == a;
                          return ChoiceChip(
                            label: Text(a),
                            selected: selected,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primaryDeep
                                  : AppColors.textSecondary,
                            ),
                            selectedColor: AppColors.primaryWash,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.borderWarm,
                              ),
                            ),
                            onSelected: (_) {
                              AppHaptics.selection();
                              setState(() => _animalType = a);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _breed,
                        decoration: const InputDecoration(
                          labelText: 'Breed (optional)',
                          hintText: 'e.g. Golden Retriever, Indie, Persian',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weight,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                hintText: 'e.g. 12.5',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDob,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of birth',
                                  suffixIcon: Icon(Icons.cake_outlined, size: 18),
                                ),
                                child: Text(
                                  _dob == null
                                      ? 'Select date'
                                      : formatDate(_dob!),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _dob == null
                                        ? AppColors.textTertiary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sex',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Male', 'Female'].map((s) {
                          final selected = _sex == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(s),
                              selected: selected,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primaryDeep
                                    : AppColors.textSecondary,
                              ),
                              selectedColor: AppColors.primaryWash,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.borderWarm,
                                ),
                              ),
                              onSelected: (_) {
                                AppHaptics.selection();
                                setState(() => _sex = s);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText:
                              'Allergies, chronic conditions, behavioural notes...',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Save Pet Profile',
                  icon: const Icon(Icons.check_rounded, size: 16),
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.lg,
                  fullWidth: true,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPicker() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primaryWash,
            backgroundImage: _localPhotoPath != null
                ? FileImage(File(_localPhotoPath!))
                : (_photoUrl != null ? NetworkImage(_photoUrl!) : null)
                    as ImageProvider?,
            child: _localPhotoPath == null && _photoUrl == null
                ? const Icon(Icons.pets_rounded,
                    size: 40, color: AppColors.primaryDeep)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.primaryDeep,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 82,
    );
    if (picked != null) {
      setState(() => _localPhotoPath = picked.path);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_animalType == null) {
      showToast('Please select animal type', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      String? uploadedUrl;
      if (_localPhotoPath != null) {
        uploadedUrl = await ref
            .read(uploadServiceProvider)
            .uploadImage(_localPhotoPath!, purpose: 'pet-photo');
      }

      final weightKg = double.tryParse(_weight.text.trim());
      final dob = _dob;
      final sex = _sex;
      final photo = uploadedUrl ?? _photoUrl;
      final notes = _notes.text.trim();
      final breed = _breed.text.trim();

      final payload = <String, dynamic>{
        'name': _name.text.trim(),
        'animalType': _animalType!.toLowerCase(),
      };
      if (breed.isNotEmpty) payload['breed'] = breed;
      if (weightKg != null) payload['weightKg'] = weightKg;
      if (sex != null) payload['sex'] = sex;
      if (dob != null) payload['dateOfBirth'] = dob.toIso8601String();
      if (photo != null) payload['photoUrl'] = photo;
      if (notes.isNotEmpty) payload['notes'] = notes;

      await ref.read(petServiceProvider).createPet(payload);

      AnalyticsService.instance.logPetCreated(
        animalType: _animalType!.toLowerCase(),
        breed: breed.isNotEmpty ? breed : null,
      );

      showToast('Pet profile created successfully!');
      if (mounted) context.pop();
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
