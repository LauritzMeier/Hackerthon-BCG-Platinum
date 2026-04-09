import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    if (AppConfig.apiBaseUrl.endsWith('/')) {
      return AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1);
    }
    return AppConfig.apiBaseUrl;
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final response = await _client.get(_uri(path));
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_decodeError(response));
    }

    final dynamic json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw ApiException('Unexpected API response format.');
    }
    return json;
  }

  String _decodeError(http.Response response) {
    try {
      final dynamic json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json['detail'] != null) {
        return json['detail'].toString();
      }
    } catch (_) {
      // Fall back to a generic message below.
    }
    return 'API request failed with status ${response.statusCode}.';
  }

  void dispose() {
    _client.close();
  }
}
