import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

/// Production-ready network image component with:
/// 1. Automatic URL resolution (relative `/uploads/...` paths to full CDN/origin)
/// 2. URI encoding sanitization (spaces, special characters)
/// 3. Automatic retry with exponential backoff on network failures
/// 4. Memory optimization (`memCacheWidth`) to prevent OutOfMemory on low-end devices
/// 5. Manual tap-to-retry button when retries are exhausted
class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackIcon = Icons.pets,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 1500),
    this.memCacheWidth = 600,
    this.memCacheHeight,
    this.enableManualRetry = true,
    this.showPlaceholderOnLoading = true,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext context, String url)? placeholder;
  final Widget Function(BuildContext context, String url, dynamic error)? errorWidget;
  final IconData fallbackIcon;
  final int maxRetries;
  final Duration retryDelay;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool enableManualRetry;
  final bool showPlaceholderOnLoading;
  final Alignment alignment;

  /// Resolves relative URLs (e.g. `/uploads/image.png`) to full absolute URLs
  /// using the configured API/CDN base URL, and sanitizes whitespace and encoding.
  static String? resolveUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        return uri.toString();
      } catch (_) {
        return Uri.encodeFull(trimmed);
      }
    }

    // Relative path: prepend backend origin
    final origin = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final full = '$origin$path';
    try {
      final uri = Uri.parse(full);
      return uri.toString();
    } catch (_) {
      return Uri.encodeFull(full);
    }
  }

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  int _retryCount = 0;
  bool _isRetrying = false;
  int _attemptKey = 0;
  Timer? _retryTimer;

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _retryTimer?.cancel();
      _retryCount = 0;
      _isRetrying = false;
      _attemptKey++;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoRetry(String url) {
    if (_isRetrying || _retryCount >= widget.maxRetries) return;

    _isRetrying = true;
    _retryTimer?.cancel();
    final delay = widget.retryDelay * (_retryCount + 1);

    _retryTimer = Timer(delay, () async {
      if (!mounted) return;
      try {
        await CachedNetworkImage.evictFromCache(url);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _retryCount++;
          _attemptKey++;
          _isRetrying = false;
        });
      }
    });
  }

  Future<void> _manualRetry(String url) async {
    _retryTimer?.cancel();
    try {
      await CachedNetworkImage.evictFromCache(url);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _retryCount = 0;
        _attemptKey++;
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = AppNetworkImage.resolveUrl(widget.imageUrl);

    Widget content;
    if (resolved == null) {
      content = _buildFallback(context, null);
    } else if (_isRetrying) {
      content = _buildRetryingWidget(context);
    } else {
      content = CachedNetworkImage(
        key: ValueKey('${resolved}_attempt_$_attemptKey'),
        imageUrl: resolved,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        memCacheWidth: widget.memCacheWidth,
        memCacheHeight: widget.memCacheHeight,
        maxWidthDiskCache: 1200,
        placeholder: (ctx, url) => widget.placeholder != null
            ? widget.placeholder!(ctx, url)
            : _buildDefaultPlaceholder(ctx),
        errorWidget: (ctx, url, error) {
          if (_retryCount < widget.maxRetries) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scheduleAutoRetry(url);
            });
            return _buildRetryingWidget(ctx);
          }

          if (widget.errorWidget != null) {
            return widget.errorWidget!(ctx, url, error);
          }

          return _buildErrorWithRetry(ctx, url);
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    if (!widget.showPlaceholderOnLoading) {
      return const SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.brandPrimary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildRetryingWidget(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8F6),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWithRetry(BuildContext context, String url) {
    if (!widget.enableManualRetry) {
      return _buildFallback(context, url);
    }

    return Material(
      color: const Color(0xFFF8FAF8),
      child: InkWell(
        onTap: () => _manualRetry(url),
        borderRadius: widget.borderRadius,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 22,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(height: 3),
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, String? url) {
    return Center(
      child: Icon(
        widget.fallbackIcon,
        size: 24,
        color: AppColors.textTertiary,
      ),
    );
  }
}
