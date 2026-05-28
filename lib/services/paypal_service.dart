import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/paypal_config.dart';

class OrdenPaypal {
  final String orderId;
  final String approvalUrl;
  const OrdenPaypal({required this.orderId, required this.approvalUrl});
}

class PaypalService {
  // obtiene token OAuth2 con las credenciales sandbox
  Future<String?> _obtenerAccessToken() async {
    final credenciales = base64Encode(
      utf8.encode('${PaypalConfig.clientId}:${PaypalConfig.clientSecret}'),
    );
    try {
      final respuesta = await http.post(
        Uri.parse('${PaypalConfig.apiBase}/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $credenciales',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      ).timeout(const Duration(seconds: 15));
      if (respuesta.statusCode != 200) return null;
      final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
      return json['access_token'] as String?;
    } catch (_) {
      return null;
    }
  }

  // crea una orden y devuelve el orderId y la URL de aprobación del comprador
  Future<OrdenPaypal?> crearOrden({
    required String importe,
    required String descripcion,
  }) async {
    final token = await _obtenerAccessToken();
    if (token == null) return null;
    try {
      final respuesta = await http.post(
        Uri.parse('${PaypalConfig.apiBase}/v2/checkout/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'amount': {'currency_code': 'EUR', 'value': importe},
              'description': descripcion,
            }
          ],
          'application_context': {
            'brand_name': 'CoachOS',
            'landing_page': 'LOGIN',
            'user_action': 'PAY_NOW',
            'return_url': PaypalConfig.returnUrl,
            'cancel_url': PaypalConfig.cancelUrl,
          },
        }),
      ).timeout(const Duration(seconds: 15));
      if (respuesta.statusCode != 201) return null;
      final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
      final orderId = json['id'] as String;
      final links = (json['links'] as List).cast<Map<String, dynamic>>();
      final approveLink = links.firstWhere(
        (l) => l['rel'] == 'approve',
        orElse: () => {},
      );
      final approvalUrl = approveLink['href'] as String?;
      if (approvalUrl == null) return null;
      return OrdenPaypal(orderId: orderId, approvalUrl: approvalUrl);
    } catch (_) {
      return null;
    }
  }

  // devuelve el estado actual de la orden: CREATED | APPROVED | COMPLETED | etc.
  Future<String?> consultarEstadoOrden(String orderId) async {
    final token = await _obtenerAccessToken();
    if (token == null) return null;
    try {
      final respuesta = await http.get(
        Uri.parse('${PaypalConfig.apiBase}/v2/checkout/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (respuesta.statusCode != 200) return null;
      final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
      return json['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  // captura el pago tras la aprobación del usuario en el WebView
  Future<bool> capturarOrden(String orderId) async {
    final token = await _obtenerAccessToken();
    if (token == null) return false;
    try {
      final respuesta = await http.post(
        Uri.parse('${PaypalConfig.apiBase}/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      return respuesta.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
