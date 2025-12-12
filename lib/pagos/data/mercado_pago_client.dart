import 'dart:convert';

import 'package:http/http.dart' as http;

class MercadoPagoClient {
  // Access Token de prueba
  static const String _accessToken =
      'APP_USR-7458694639833894-121122-f7fdc1e1303df1d70d9009f02ad81ec2-3058705343';
  static const String _baseUrl = 'https://api.mercadopago.com';

  /// Crea una preferencia de pago en Mercado Pago para una expensa
  /// externalReference: id del pago en tu tabla pagos_expensa
  Future<MpPreferenceResult> createPreference({
    required String externalReference,
    required String title,
    required double amount,
  }) async {
    final url = Uri.parse('$_baseUrl/checkout/preferences');

    final body = {
      'items': [
        {
          'title': title,
          'quantity': 1,
          'unit_price': amount,
          'currency_id': 'ARS',
        },
      ],
      'external_reference': externalReference,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error MP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final initPoint =
        (data['sandbox_init_point'] ?? data['init_point']) as String;

    return MpPreferenceResult(
      preferenceId: data['id'] as String,
      initPoint: initPoint,
    );
  }

  /// Consulta pagos de MP por external_reference (el id del pago en tu BD)
  Future<MpPaymentStatusResult> getPaymentStatusByExternalReference(
    String externalReference,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/v1/payments/search?external_reference=$externalReference',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error MP search ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? [];

    if (results.isEmpty) {
      // No hay pago todavía
      return MpPaymentStatusResult(status: 'PENDIENTE', paymentId: null);
    }

    final payment = results.first as Map<String, dynamic>;
    final status = (payment['status'] ?? 'pending') as String;
    final paymentId = payment['id']?.toString();

    String mappedStatus = 'PENDIENTE';
    switch (status) {
      case 'approved':
        mappedStatus = 'APROBADO';
        break;
      case 'rejected':
        mappedStatus = 'RECHAZADO';
        break;
      case 'cancelled':
        mappedStatus = 'CANCELADO';
        break;
      default:
        mappedStatus = 'PENDIENTE';
    }

    return MpPaymentStatusResult(status: mappedStatus, paymentId: paymentId);
  }
}

class MpPreferenceResult {
  final String preferenceId;
  final String initPoint;

  MpPreferenceResult({required this.preferenceId, required this.initPoint});
}

class MpPaymentStatusResult {
  final String status; // PENDIENTE / APROBADO / RECHAZADO / CANCELADO
  final String? paymentId;

  MpPaymentStatusResult({required this.status, required this.paymentId});

  bool get isApproved => status == 'APROBADO';
}
