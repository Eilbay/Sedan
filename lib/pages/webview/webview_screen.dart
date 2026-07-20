import 'package:flutter/material.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class WebViewScreen extends StatefulWidget {
  final String url;
  final VoidCallback? onPmtSuccess;

  const WebViewScreen({
    super.key,
    required this.url,
    this.onPmtSuccess,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _canLeave = false;

  void _finish(bool result) {
    if (!mounted) return;
    setState(() => _canLeave = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.router.maybePop(result);
    });
  }

  bool _isSuccessUrl(Uri u) {
    final path = u.path.toLowerCase();
    final q = u.queryParameters
        .map((k, v) => MapEntry(k.toLowerCase(), v.toLowerCase()));

    return path.contains('/success') ||
        q['status'] == 'success' ||
        q['pg_status'] == 'ok' ||
        q['payment'] == 'paid';
  }

  bool _isFailUrl(Uri u) {
    final path = u.path.toLowerCase();
    final q = u.queryParameters
        .map((k, v) => MapEntry(k.toLowerCase(), v.toLowerCase()));

    return path.contains('/fail') ||
        path.contains('/cancel') ||
        q['status'] == 'failed' ||
        q['status'] == 'canceled' ||
        q['pg_status'] == 'error';
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final u = Uri.parse(req.url);
            if (_isSuccessUrl(u)) {
              widget.onPmtSuccess?.call();
              _finish(true);
              return NavigationDecision.prevent;
            }
            if (_isFailUrl(u)) {
              _finish(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            final u = Uri.parse(url);
            if (_isSuccessUrl(u)) {
              _finish(true);
            } else if (_isFailUrl(u)) {
              _finish(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _confirmExit() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TextTranslated('Выйти из оплаты?'),
        content: const TextTranslated(
            'Если выйти сейчас, премиум может не активироваться.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const TextTranslated('Продолжить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const TextTranslated('Выйти'),
          ),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _confirmExit();
        if (ok && mounted) _finish(false);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const TextTranslated('Оплата'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final ok = await _confirmExit();
                if (ok) _finish(false);
              },
            ),
          ],
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
