import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

/// Reusable prescription upload sheet. Collects images and calls [onSubmit]
/// with the selected files and metadata. The caller is responsible for the
/// actual upload and for invalidating [prescriptionsProvider].
class RxUploadSheet extends StatefulWidget {
  const RxUploadSheet({super.key, required this.onSubmit});
  final void Function(
    List<XFile> files,
    String petType,
    String petName,
    String notes,
  )
  onSubmit;

  @override
  State<RxUploadSheet> createState() => _RxUploadSheetState();
}

class _RxUploadSheetState extends State<RxUploadSheet> {
  final List<XFile> _selectedFiles = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    AppHaptics.light();
    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (shot != null) {
        setState(() => _selectedFiles.add(shot));
      }
    } else {
      final images = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
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
    final bottomInset =
        MediaQuery.viewInsetsOf(context).bottom +
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
                Flexible(
                  child: Text(
                    'Upload Prescription',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.serif(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
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
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
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

            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: const TextStyle(fontSize: 12.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Submit Prescription',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.md,
              fullWidth: true,
              onPressed: _selectedFiles.isEmpty
                  ? null
                  : () {
                      widget.onSubmit(
                        _selectedFiles,
                        '',
                        '',
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

Future<bool> showRxUploadSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onUploaded,
}) async {
  bool uploaded = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => RxUploadSheet(
      onSubmit: (files, petType, petName, notes) async {
        Navigator.of(ctx).pop();
        uploaded = await _processRxUpload(ref, files, petType, petName, notes);
        if (uploaded) onUploaded?.call();
      },
    ),
  );
  return uploaded;
}

Future<bool> _processRxUpload(
  WidgetRef ref,
  List<XFile> files,
  String petType,
  String petName,
  String notes,
) async {
  if (files.isEmpty) return false;
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
    await ref
        .read(prescriptionServiceProvider)
        .uploadPrescription(
          imageUrls: urls,
          notes: combinedNotes.isNotEmpty ? combinedNotes : null,
        );
    showToast('Prescription uploaded for veterinary review!');
    return true;
  } catch (e) {
    showToast(e.toString(), isError: true);
    return false;
  }
}
