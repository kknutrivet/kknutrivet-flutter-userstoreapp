import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/prescription.dart';
import '../../../providers/app_providers.dart';

final prescriptionsProvider =
    FutureProvider.autoDispose<List<Prescription>>((ref) {
  return ref.read(prescriptionServiceProvider).fetchPrescriptions();
});

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() =>
      _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final prescriptionsAsync = ref.watch(prescriptionsProvider);
    final prescriptions =
        prescriptionsAsync.valueOrNull ?? const <Prescription>[];

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
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
          errorBuilder: (context, error, stackTrace) => Text(
            'KK Nutrivet',
            style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined,
                color: AppColors.textPrimary),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        onPressed: _uploading ? null : _openUploadSheet,
        icon: _uploading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(
          _uploading ? 'Uploading...' : 'Upload Rx',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(prescriptionsProvider);
            await ref.read(prescriptionsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _PublicPageHero()),
              SliverToBoxAdapter(
                child: _InlinePrescriptionUploadCard(
                  onPickImages: _openUploadSheet,
                  uploading: _uploading,
                ),
              ),
              if (prescriptions.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          'Your Submitted Prescriptions',
                          style: AppTheme.serif(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        const Spacer(),
                        AppBadge(
                          label: '${prescriptions.length} total',
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
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PrescriptionCard(
                          prescription: prescriptions[i],
                        ),
                      ),
                      childCount: prescriptions.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUploadSheet() async {
    AppHaptics.light();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PrescriptionUploadSheet(
        onSubmit: (files, petType, petName, notes) async {
          Navigator.of(ctx).pop();
          await _processUpload(files, petType, petName, notes);
        },
      ),
    );
  }

  Future<void> _processUpload(
    List<XFile> files,
    String petType,
    String petName,
    String notes,
  ) async {
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final urls = <String>[];
      for (final image in files) {
        final url = await ref
            .read(uploadServiceProvider)
            .uploadImage(image.path, purpose: 'prescription');
        urls.add(url);
      }

      final combinedNotes = [
        if (petType.isNotEmpty) 'Animal: $petType',
        if (petName.isNotEmpty) 'Pet Name: $petName',
        if (notes.isNotEmpty) notes,
      ].join(' · ');

      await ref.read(prescriptionServiceProvider).uploadPrescription(
            imageUrls: urls,
            notes: combinedNotes.isNotEmpty ? combinedNotes : null,
          );

      showToast('Prescription uploaded for veterinary review!');
      ref.invalidate(prescriptionsProvider);
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _PublicPageHero extends StatelessWidget {
  const _PublicPageHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF7F2),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PRESCRIPTION SUPPORT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primaryDeep,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  '+5% KK Coins',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload Veterinary\nPrescription',
            style: AppTheme.serif(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your pet’s prescription for quick verification and same-composition medicine matching by registered pharmacists.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('1', 'Upload photo'),
              _chip('2', 'Pharmacist matches medicines'),
              _chip('3', 'Direct cart dispatch'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String num, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFF075B43),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202B26),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlinePrescriptionUploadCard extends StatelessWidget {
  const _InlinePrescriptionUploadCard({
    required this.onPickImages,
    required this.uploading,
  });
  final VoidCallback onPickImages;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'STEP 1 OF 2',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.primaryDeep,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F5EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1. Images',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF075B43),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '2. Details',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload Prescription Images',
            style: AppTheme.serif(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: uploading ? null : onPickImages,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFCFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFB8D8C7),
                  style: BorderStyle.solid,
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F5EF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      uploading
                          ? Icons.hourglass_top_rounded
                          : Icons.file_upload_outlined,
                      size: 26,
                      color: const Color(0xFF075B43),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Drop prescription photos here, or browse',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to select from your camera or photo gallery.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Supports JPG, PNG, WEBP · up to 5 pages · max 8MB per file',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: uploading ? null : onPickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075B43),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(
                uploading ? 'Uploading...' : 'Choose Images',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.prescription});
  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    final images = prescription.imageUrls.isNotEmpty
        ? prescription.imageUrls
        : (prescription.imageUrl != null
            ? [prescription.imageUrl!]
            : <String>[]);

    final status = prescription.status.toUpperCase();
    final (statusLabel, statusTone, statusIcon) = switch (status) {
      'APPROVED' => (
          'Verified & Approved',
          AppBadgeTone.emerald,
          Icons.check_circle_rounded,
        ),
      'REJECTED' => (
          'Needs Attention',
          AppBadgeTone.coral,
          Icons.error_outline_rounded,
        ),
      _ => (
          'Review in Progress',
          AppBadgeTone.amber,
          Icons.schedule_rounded,
        ),
    };

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rxBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Rx',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.rxText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDate(prescription.createdAt),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (prescription.vetName != null &&
                        prescription.vetName!.isNotEmpty)
                      Text(
                        'Verified by Dr. ${prescription.vetName}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              AppBadge(
                label: statusLabel,
                icon: Icon(statusIcon, size: 12),
                tone: statusTone,
              ),
            ],
          ),
          if (prescription.notes != null &&
              prescription.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryWashFaint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryWash),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 15, color: AppColors.primaryDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prescription.notes!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderWarm),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.primaryWash,
                        child: const Icon(Icons.broken_image,
                            size: 20, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrescriptionUploadSheet extends StatefulWidget {
  const _PrescriptionUploadSheet({required this.onSubmit});
  final void Function(
    List<XFile> files,
    String petType,
    String petName,
    String notes,
  ) onSubmit;

  @override
  State<_PrescriptionUploadSheet> createState() =>
      _PrescriptionUploadSheetState();
}

class _PrescriptionUploadSheetState extends State<_PrescriptionUploadSheet> {
  final List<XFile> _selectedFiles = [];
  String _selectedAnimal = 'Dog';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _animalOptions = [
    'Dog',
    'Cat',
    'Cattle',
    'Goat',
    'Poultry',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    AppHaptics.light();
    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final shot = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 85, maxWidth: 1600);
      if (shot != null) {
        setState(() => _selectedFiles.add(shot));
      }
    } else {
      final images =
          await picker.pickMultiImage(imageQuality: 85, maxWidth: 1600);
      if (images.isNotEmpty) {
        setState(() {
          for (final img in images) {
            if (_selectedFiles.length < 5) _selectedFiles.add(img);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderWarmSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Upload Prescription',
                  style: AppTheme.serif(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              'Add clear photos of the paper prescription (up to 5 photos).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Pickers row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImages(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDeep,
                      side: const BorderSide(color: AppColors.primaryDeep),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImages(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined,
                        size: 18, color: Colors.white),
                    label: const Text('From Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: Colors.white,
                      iconColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Thumbnails preview
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_selectedFiles[i].path),
                            width: 74,
                            height: 74,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedFiles.removeAt(i));
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Animal Type',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _animalOptions.map((a) {
                  final sel = _selectedAnimal == a;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: sel,
                      label: Text(a),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel
                            ? AppColors.primaryDeep
                            : AppColors.textSecondary,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primaryWash,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              sel ? AppColors.primary : AppColors.borderWarm,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedAnimal = a);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Pet Name / Identifier (optional)',
                labelStyle: const TextStyle(fontSize: 12.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Specific medicine or notes (optional)',
                labelStyle: const TextStyle(fontSize: 12.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 16),
            AppButton(
              label: 'Submit Prescription',
              icon: const Icon(Icons.send_rounded, size: 16),
              variant: AppButtonVariant.primary,
              size: AppButtonSize.md,
              fullWidth: true,
              onPressed: _selectedFiles.isEmpty
                  ? null
                  : () {
                      widget.onSubmit(
                        _selectedFiles,
                        _selectedAnimal,
                        _nameController.text.trim(),
                        _notesController.text.trim(),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
