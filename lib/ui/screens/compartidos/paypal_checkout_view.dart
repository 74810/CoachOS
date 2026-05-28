import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/paypal_config.dart';

enum ResultadoPaypal { exito, cancelado, error }

class PaypalCheckoutView extends StatefulWidget {
  final String approvalUrl;
  final String orderId;

  const PaypalCheckoutView({
    super.key,
    required this.approvalUrl,
    required this.orderId,
  });

  @override
  State<PaypalCheckoutView> createState() => _PaypalCheckoutViewState();
}

class _PaypalCheckoutViewState extends State<PaypalCheckoutView> {
  late final WebViewController _controller;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // PayPal bloquea el user-agent de Flutter; fingimos ser Chrome en Android
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _cargando = true),
          onPageFinished: (_) => setState(() => _cargando = false),
          onWebResourceError: (_) {
            // Ignorar errores de recursos secundarios (scripts, imágenes, etc.)
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // PayPal redirige a return_url con ?token=ORDER_ID&PayerID=...
            if (url.startsWith(PaypalConfig.returnUrl)) {
              if (mounted) Navigator.pop(context, ResultadoPaypal.exito);
              return NavigationDecision.prevent;
            }

            // PayPal redirige a cancel_url cuando el usuario cancela
            if (url.startsWith(PaypalConfig.cancelUrl)) {
              if (mounted) Navigator.pop(context, ResultadoPaypal.cancelado);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo PayPal (colores oficiales)
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Pay', style: TextStyle(color: Color(0xFF003087))),
                  TextSpan(text: 'Pal', style: TextStyle(color: Color(0xFF009CDE))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SANDBOX',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.xmark, color: Colors.grey),
          onPressed: () => Navigator.pop(context, ResultadoPaypal.cancelado),
        ),
        // Indicador de conexión segura
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(CupertinoIcons.lock_fill, color: Colors.green, size: 18),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_cargando)
            const Center(child: CupertinoActivityIndicator(radius: 16)),
        ],
      ),
    );
  }
}
