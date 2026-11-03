import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});
  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _searchController = TextEditingController();
  List<Product>? _results;
  bool _loading = false;
  String? _error;
  bool _usedImage = false;
  String? _localImagePath;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _loading) return;
    AppHaptics.selection();
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
      _usedImage = false;
    });
    try {
      final results = await ref
          .read(aiServiceProvider)
          .findAlternativesByText(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error =
            'Could not load matches. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    AppHaptics.light();
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
      _usedImage = true;
      _localImagePath = image.path;
    });
    try {
      final url = await ref
          .read(uploadServiceProvider)
          .uploadImage(image.path, purpose: 'scan');
      final results = await ref
          .read(aiServiceProvider)
          .findAlternativesByImage(url);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error =
            'Could not load matches. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Find Alternatives & Generic Matches',
          style: AppTheme.serif(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search brand medicine or supplement...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textTertiary,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primaryDeep,
                        ),
                        onPressed: _search,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Choose product photo',
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.md,
                          isLoading: _loading && _usedImage,
                          onPressed: _loading ? null : _pickImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Photograph the front label or composition clearly. We match certified generic alternatives and exact formulas.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderWarmSoft),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: _usedImage ? _pickImage : _search,
      );
    }
    if (_loading) {
      return const Center(child: AppLoader.large());
    }
    if (_localImagePath != null && _results == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(_localImagePath!),
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const AppLoader.small(),
              const SizedBox(height: 8),
              const Text(
                'Matching clinical composition...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_results == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AppEmptyState(
            icon: Icons.compare_arrows_rounded,
            title: 'Find Matching Medicines',
            description:
                'Search a brand name or photograph a bottle to match certified veterinary alternatives and compositions.',
          ),
        ),
      );
    }
    if (_results!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No Direct Matches Found',
            description: _usedImage
                ? 'Could not match this photo.\nTry a clearer shot of the composition or search by brand name.'
                : 'No alternatives found for this search.\nCheck spelling or consult our vet team.',
            actionLabel: 'Consult a Vet',
            onAction: () => context.push('/consultations'),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _results!.length,
      itemBuilder: (context, i) {
        final p = _results![i];
        return ProductCard(
          product: p,
          onTap: () =>
              context.push('/product/${p.slug.isNotEmpty ? p.slug : p.id}'),
          onAdd: () => showToast('Added to cart'),
        );
      },
    );
  }
}
