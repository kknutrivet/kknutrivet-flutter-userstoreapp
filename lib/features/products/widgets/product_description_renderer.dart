import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';

class ProductDetailSection {
  const ProductDetailSection({
    required this.id,
    required this.title,
    required this.content,
    this.isComposition = false,
  });

  final String id;
  final String title;
  final String content;
  final bool isComposition;
}

const List<String> kProductDetailSectionOrder = [
  'Product Details',
  'Key Features',
  'Composition',
  'Recommended Use',
  'Benefits',
  'Dosage',
  'How to use',
  'Safety Information',
  'Storage',
  'Packaging',
  'Notes',
];

const Map<String, String> kSectionAliases = {
  'short description': 'Product Details',
  'about this product': 'Product Details',
  'overview': 'Product Details',
  'product details': 'Product Details',
  'features': 'Key Features',
  'key features': 'Key Features',
  'key benefits': 'Benefits',
  'benefits': 'Benefits',
  'ingredients / composition': 'Composition',
  'ingredients': 'Composition',
  'composition': 'Composition',
  'active ingredients': 'Composition',
  'composition & active ingredients': 'Composition',
  'suitable for': 'Recommended Use',
  'suitable animals': 'Recommended Use',
  'ideal during': 'Recommended Use',
  'when to use': 'Recommended Use',
  'why to use': 'Recommended Use',
  'why use': 'Recommended Use',
  'recommended use': 'Recommended Use',
  'directions for use': 'How to use',
  'directions': 'How to use',
  'how to use': 'How to use',
  'directions & dosage': 'Dosage',
  'administration': 'Dosage',
  'dosage': 'Dosage',
  'precautions': 'Safety Information',
  'safety': 'Safety Information',
  'warnings': 'Safety Information',
  'safety information': 'Safety Information',
  'storage & safety': 'Storage',
  'storage': 'Storage',
  'pack size': 'Packaging',
  'packaging': 'Packaging',
  'notes': 'Notes',
};

String _sectionId(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}

String? _headingFromLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;

  final markdown = RegExp(r'^#{1,2}\s+(.+)$').firstMatch(trimmed);
  if (markdown != null) {
    return markdown.group(1)?.trim();
  }

  // Subheadings (###) stay as in-content section subheadings
  if (RegExp(r'^#{3,}\s').hasMatch(trimmed)) return null;

  final plain = trimmed
      .replaceAll(RegExp(r'^\*\*(.+?)\*\*:?$'), r'$1')
      .replaceAll(RegExp(r':$'), '')
      .trim();

  if (plain.length > 64) return null;
  if (kSectionAliases.containsKey(plain.toLowerCase())) {
    return plain;
  }
  return null;
}

/// Splits a raw product description into clean structured sections.
/// Mirrors `splitProductDescription` in web's `src/lib/product-description-sections.ts`.
List<({String id, String title, String content})> splitProductDescription(
  String description, {
  String defaultTitle = 'Product Details',
}) {
  if (description.trim().isEmpty) return [];

  final lines = description.replaceAll('\r\n', '\n').split('\n');
  final sections = <({String id, String title, String content})>[];
  var title = defaultTitle;
  var id = 'product-details';
  final buffer = <String>[];

  void flush() {
    final content = buffer.join('\n').trim();
    buffer.clear();
    if (content.isEmpty) return;
    sections.add((id: id, title: title, content: content));
  }

  for (final line in lines) {
    final heading = _headingFromLine(line);
    if (heading != null) {
      flush();
      title = heading;
      id = _sectionId(heading);
      if (id.isEmpty) id = 'section';
      continue;
    }
    buffer.add(line);
  }
  flush();

  return sections;
}

/// Builds PDP accordion sections mirroring web's `buildProductDetailSections`
/// (`src/lib/product-description-sections.ts`).
List<ProductDetailSection> buildProductDetailSections(Product product) {
  final rawDesc = product.description?.trim() ?? '';
  final rawComp = product.composition?.trim() ?? '';

  final grouped = <String, List<String>>{};
  final titles = {
    for (final t in kProductDetailSectionOrder) t.toLowerCase(): t,
  };

  for (final section in splitProductDescription(rawDesc)) {
    final canonical = kSectionAliases[section.title.toLowerCase()] ??
        titles[section.title.toLowerCase()];
    final title = canonical ?? 'Notes';
    final content = canonical != null
        ? section.content
        : '### ${section.title}\n${section.content}';
    grouped.putIfAbsent(title, () => []).add(content);
  }

  // The dedicated composition field is authoritative and replaces composition aliases
  if (rawComp.isNotEmpty) {
    grouped['Composition'] = [rawComp];
  }

  if (!grouped.containsKey('Product Details') && product.name.isNotEmpty) {
    grouped['Product Details'] = [product.name];
  }

  final animalLabel = product.animalTypes.isNotEmpty
      ? product.animalTypes.join(', ')
      : 'your pet or livestock';

  // Fallbacks if not already specified in the description
  if (!grouped.containsKey('Dosage') && !grouped.containsKey('How to use')) {
    grouped['Dosage'] = [
      'Administer as directed on the product label or as prescribed by a registered veterinarian for $animalLabel. Adjust dosage according to body weight and clinical condition.',
    ];
  }

  if (!grouped.containsKey('Storage') &&
      !grouped.containsKey('Safety Information')) {
    grouped['Storage'] = [
      'Store in a cool, dry place away from direct sunlight. Keep out of reach of children and animals. For veterinary use only.',
    ];
  }

  final result = <ProductDetailSection>[];
  for (final title in kProductDetailSectionOrder) {
    final blocks = grouped[title];
    if (blocks != null && blocks.isNotEmpty) {
      final content = blocks.join('\n\n').trim();
      if (content.isNotEmpty) {
        result.add(ProductDetailSection(
          id: _sectionId(title),
          title: title == 'Composition'
              ? 'Composition & Active Ingredients'
              : (title == 'Dosage' ? 'Directions & Dosage' : title),
          content: content,
          isComposition: title == 'Composition',
        ));
      }
    }
  }

  return result;
}

/// Returns an icon matching the section content (mirrors web's `detailSectionIcon`).
IconData detailSectionIcon(String id) {
  if (id.contains('composition') || id.contains('ingredient')) {
    return Icons.science_outlined;
  }
  if (id.contains('product-details') || id.contains('detail')) {
    return Icons.description_outlined;
  }
  if (id.contains('feature') || id.contains('benefit')) {
    return Icons.auto_awesome_outlined;
  }
  if (id.contains('when') ||
      id.contains('used') ||
      id.contains('ideal') ||
      id.contains('suitable') ||
      id.contains('recommend')) {
    return Icons.pets_outlined;
  }
  if (id.contains('storage')) {
    return Icons.inventory_2_outlined;
  }
  if (id.contains('safety') ||
      id.contains('precaution') ||
      id.contains('warning')) {
    return Icons.shield_outlined;
  }
  if (id.contains('how') ||
      id.endsWith('use') ||
      id.contains('direction') ||
      id.contains('dosage')) {
    return Icons.medication_liquid_outlined;
  }
  return Icons.info_outline_rounded;
}

List<InlineSpan> parseInlineSpans(String text, {required TextStyle defaultStyle}) {
  final spans = <InlineSpan>[];
  final regex = RegExp(r'(\*\*(.+?)\*\*|\*(.+?)\*)');
  var last = 0;

  for (final m in regex.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(
        text: text.substring(last, m.start),
        style: defaultStyle,
      ));
    }
    final boldText = m.group(2);
    final italicText = m.group(3);
    if (boldText != null) {
      spans.add(TextSpan(
        text: boldText,
        style: defaultStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ));
    } else if (italicText != null) {
      spans.add(TextSpan(
        text: italicText,
        style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
      ));
    }
    last = m.end;
  }

  if (last < text.length) {
    spans.add(TextSpan(
      text: text.substring(last),
      style: defaultStyle,
    ));
  }

  return spans;
}

/// Renders formatted markdown/section text matching web's `DescriptionRenderer`
/// (`src/app/products/[id]/ProductDetailClient.tsx`).
class ProductDescriptionRenderer extends StatelessWidget {
  const ProductDescriptionRenderer({
    super.key,
    required this.text,
    this.isComposition = false,
  });

  final String text;
  final bool isComposition;

  @override
  Widget build(BuildContext context) {
    if (isComposition) {
      final ingredients = text
          .replaceAll('\r\n', '\n')
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ingredients.map((line) {
          final cleanLine = line.replaceFirst(
            RegExp(r'^(?:[✔✓•\-\*]\s*|\d+\.\s*)'),
            '',
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: parseInlineSpans(
                        cleanLine,
                        defaultStyle: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // H3 subheading: ### Title
      if (line.startsWith('### ')) {
        final headingText = line.replaceFirst(RegExp(r'^###\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    headingText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Bullets starting with ✔, ✓, •, -, *
      if (RegExp(r'^[✔✓•\-\*]\s*').hasMatch(line)) {
        final itemText = line.replaceFirst(RegExp(r'^[✔✓•\-\*]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3, right: 7),
                  child: Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: parseInlineSpans(
                        itemText,
                        defaultStyle: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered list items (e.g. "1. Something")
      final numberMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(line);
      if (numberMatch != null) {
        final num = numberMatch.group(1)!;
        final itemText = numberMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 1, right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    num,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: parseInlineSpans(
                        itemText,
                        defaultStyle: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Normal paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text.rich(
            TextSpan(
              children: parseInlineSpans(
                line,
                defaultStyle: const TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
