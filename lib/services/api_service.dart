import 'dart:convert';
import 'package:http/http.dart' as http;

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
      final uri = Uri.parse('$apiBaseUrl$path');
      final headers = {
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        };
      final response = await switch (method) {
        'POST' => http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
        'PUT' => http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
        'PATCH' => http.patch(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.get(uri, headers: headers),
      };
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      final status = response.statusCode;
      if (status < 200 || status >= 300) throw ApiException(errorText(decoded));
      return decoded;
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con Laravel en el puerto 8000.');
    }
  }
}
