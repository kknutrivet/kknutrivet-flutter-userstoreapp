import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../utils/haptics.dart';
import '../widgets/common.dart';
import '../../models/product.dart';

/// Helper to trigger the Android & iOS system share sheet.
class AppShare {
  AppShare._();

  static Rect? _originRect(BuildContext? context) {
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final pos = box.localToGlobal(Offset.zero);
      return pos & box.size;
    }
    return null;
  }

  /// Summons the platform's native share sheet (Android Chooser / iOS Activity)
  /// for a product, sharing its name and web link.
  static Future<void> shareProduct(
    BuildContext context,
    Product product,
  ) async {
    Haptics.tap();
    final slugOrId = product.slug.isNotEmpty ? product.slug : product.id;
    final link = '${AppConfig.apiBaseUrl}/products/$slugOrId';
    final shareText = 'Check out ${product.name} on KK Nutrivet:\n$link';

    try {
      final rect = _originRect(context);
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          title: 'Share ${product.name}',
          subject: product.name,
          sharePositionOrigin: rect,
        ),
      );
    } catch (_) {
      // Fallback if platform share sheet is unavailable (e.g. desktop/test/driver)
      await Clipboard.setData(ClipboardData(text: link));
      showToast('Product link copied');
    }
  }

  /// Summons the platform's native share sheet with general text
  /// (e.g. referral link, article, or health tip).
  static Future<void> shareText(
    BuildContext context, {
    required String text,
    String? title,
    String? subject,
    String? fallbackCopyText,
  }) async {
    Haptics.tap();
    try {
      final rect = _originRect(context);
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: title,
          subject: subject,
          sharePositionOrigin: rect,
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: fallbackCopyText ?? text));
      showToast('Link copied to clipboard');
    }
  }
}
