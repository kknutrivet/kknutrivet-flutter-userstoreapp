import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';

/// Wraps Cashfree's hosted checkout page (the same "Web Checkout" redirect
/// flow nvit-frontend's own Cashfree JS SDK uses) in a WebView. The backend
/// configures the return URL as `{siteUrl}/orders/{orderId}?payment=...`;
/// once the WebView navigates there we intercept it, close, and let the
/// caller verify the final payment status via /api/payments/cashfree/verify
/// instead of rendering the website page in-app.
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
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    final host = widget.mode == 'production'
        ? 'payments.cashfree.com'
        : 'payments-test.cashfree.com';
    final url = 'https://$host/order/#${widget.paymentSessionId}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            final returnTarget =
                widget.returnUrlContains ?? '/orders/${widget.orderId}';
            if (request.url.contains(returnTarget)) {
              _finish();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
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
        appBar: AppBar(
          title: const Text('Complete payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _resolved = true;
              Navigator.of(context).pop(false);
            },
          ),
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
