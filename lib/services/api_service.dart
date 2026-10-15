import 'dart:convert';
import 'dart:html' as html;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
}

String errorText(dynamic body) {
  if (body is Map) {
    final message = body['message'];
    if (message != null) return message.toString();
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
  }
  return 'No se pudo completar la operación.';
}

class Api {
  const Api(this.token);
  final String token;

  Future<dynamic> call(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    try {
      final response = await html.HttpRequest.request(
        '$apiBaseUrl$path',
        method: method,
        requestHeaders: {
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        sendData: body == null ? null : jsonEncode(body),
      );
      final decoded = response.responseText == null || response.responseText!.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.responseText!);
      final status = response.status ?? 0;
      if (status < 200 || status >= 300) throw ApiException(errorText(decoded));
      return decoded;
    } on html.ProgressEvent {
      throw const ApiException('No se pudo conectar con Laravel en el puerto 8000.');
    }
  }
}
