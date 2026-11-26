import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/common.dart';

/// Wraps Cashfree's hosted checkout page (powered by @cashfreepayments/cashfree-js
/// on /checkout/cashfree-session) in a WebView. The backend configures the return
/// URL as `{siteUrl}/orders/{orderId}/payment-return?order_id=...`; once the
/// WebView navigates there we intercept it, close, and let the caller verify
/// the final payment status via /api/payments/cashfree/verify.
class CashfreeCheckoutScreen extends StatefulWidget {
  const CashfreeCheckoutScreen({
    super.key,
    required this.paymentSessionId,
    required this.orderId,
    required this.mode,
    this.returnUrlContains,
  });

  final String paymentSessionId;
  final String orderId;
  final String mode; // "production" | "sandbox"
  final String? returnUrlContains;

  @override
  State<CashfreeCheckoutScreen> createState() => _CashfreeCheckoutScreenState();
}

class _CashfreeCheckoutScreenState extends State<CashfreeCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  bool _resolved = false;

  static const String _hideWebChromeJs = '''
(function() {
  if (document.getElementById('kk-app-hide-chrome')) return;
  var style = document.createElement('style');
  style.id = 'kk-app-hide-chrome';
  style.textContent = 'header, [data-site-header], .site-header, .mobile-app-header, nav, footer, [aria-label="Mobile navigation"], [aria-label="Bottom navigation"] { display: none !important; } body, main { padding-top: 0 !important; padding-bottom: 0 !important; }';
  (document.head || document.documentElement).appendChild(style);
})();
''';

  void _hideWebChromeIfOwnHost(String url) {
    if (url.contains('/checkout/cashfree-session')) {
      _controller.runJavaScript(_hideWebChromeJs).catchError((_) {});
    }
  }

  @override
  void initState() {
    super.initState();
    final cleanMode = widget.mode.toLowerCase().contains('sandbox') ? 'sandbox' : 'production';
    final sessionUrl =
        '${AppConfig.apiBaseUrl}/checkout/cashfree-session?sessionId=${Uri.encodeQueryComponent(widget.paymentSessionId)}&mode=$cleanMode&orderId=${Uri.encodeQueryComponent(widget.orderId)}&app=1';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) setState(() { _loading = false; _error = 'Could not load secure payment. Retry or return to your saved order.'; });
          },
          onPageStarted: (url) {
            _hideWebChromeIfOwnHost(url);
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            _hideWebChromeIfOwnHost(url);
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) async {
            final returnTarget =
                widget.returnUrlContains ?? '/orders/${widget.orderId}';
            if (request.url.contains(returnTarget)) {
              _finish();
              return NavigationDecision.prevent;
            }

            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                !uri.scheme.startsWith('http') &&
                !uri.scheme.startsWith('about')) {
              try {
                if (await canLaunchUrl(uri)) {
                  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!opened) throw StateError('unavailable');
                } else { throw StateError('unavailable'); }
              } catch (_) {
                if (mounted) {
                  showToast(
                    'Could not open this payment app. Choose another payment method.',
                    isError: true,
                    context: context,
                  );
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _controller.loadRequest(Uri.parse(sessionUrl));
  }

  void _finish() {
    if (_resolved) return;
    _resolved = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_resolved) {
          _resolved = true;
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07583F),
        body: SafeArea(
          child: ColoredBox(
            color: Colors.white,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_error != null) Positioned.fill(child: ColoredBox(color: Colors.white, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), TextButton(onPressed: () { setState(() { _error = null; _loading = true; }); _controller.reload(); }, child: const Text('Retry')), TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Return to order'))]))))),
                if (_loading)
                  const Center(
                    child: AppLoader(size: 32, strokeWidth: 3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
