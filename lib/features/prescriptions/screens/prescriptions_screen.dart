import '../../../core/widgets/app_network_image.dart';
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
import '../widgets/rx_upload_sheet.dart';

final prescriptionsProvider = FutureProvider.autoDispose<List<Prescription>>((
  ref,
) {
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
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.push('/cart'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: _uploading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  minHeight: 3.0,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryDeep,
                  ),
                ),
              )
            : null,
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
              if (ref.watch(authProvider).value != null &&
                  prescriptionsAsync.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: LoadingView(),
                  ),
                ),
              if (ref.watch(authProvider).value != null &&
                  prescriptionsAsync.hasError)
                SliverToBoxAdapter(
                  child: ErrorView(
                    message:
                        'Could not load your prescriptions. Your submissions are saved.',
                    onRetry: () => ref.invalidate(prescriptionsProvider),
                  ),
                ),
              if (ref.watch(authProvider).value != null &&
                  !prescriptionsAsync.isLoading &&
                  !prescriptionsAsync.hasError &&
                  prescriptions.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No prescriptions submitted yet.'),
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
      builder: (ctx) => RxUploadSheet(
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

      await ref
          .read(prescriptionServiceProvider)
          .uploadPrescription(
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
                    'Choose prescription photos',
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
      _ => ('Review in Progress', AppBadgeTone.amber, Icons.schedule_rounded),
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
          if (prescription.notes != null && prescription.notes!.isNotEmpty) ...[
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
                  const Icon(
                    Icons.notes_rounded,
                    size: 15,
                    color: AppColors.primaryDeep,
                  ),
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
                    child: AppNetworkImage(
                      imageUrl: images[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.description_outlined,
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
