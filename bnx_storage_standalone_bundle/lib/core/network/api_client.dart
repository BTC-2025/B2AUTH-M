import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'token_service.dart';

/// Central HTTP client for the Storage module APIs with per-account routing.
class ApiClient {
  static String _customBaseUrl = 'https://api.bnxmail.com';

  static String get baseUrl => _customBaseUrl;

  /// Override the API base URL if needed (e.g., custom environment or testing).
  static void setBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static const Duration _timeout = Duration(seconds: 25);

  static Future<Map<String, String>> _headers({
    bool auth = true,
    String? accountEmail,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await TokenService.getAccessToken(accountEmail);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _parseBody(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List) return {'data': decoded};
      return {'data': decoded};
    } catch (_) {
      return {'message': response.body};
    }
  }

  static ApiException _toException(http.Response r) {
    final body = _parseBody(r);
    final msg = body is Map
        ? (body['message']?.toString() ??
            body['error']?.toString() ??
            'Request failed (${r.statusCode})')
        : 'Request failed (${r.statusCode})';
    return ApiException(statusCode: r.statusCode, message: msg);
  }

  static void _assertOk(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw _toException(r);
    }
  }

  static Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse('$baseUrl$cleanPath');
    if (queryParams == null || queryParams.isEmpty) return baseUri;

    final stringParams = queryParams.map(
      (k, v) => MapEntry(k, v?.toString() ?? ''),
    )..removeWhere((k, v) => v.isEmpty);

    return baseUri.replace(queryParameters: {
      ...baseUri.queryParameters,
      ...stringParams,
    });
  }

  // ── GET ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool auth = true,
    String? accountEmail,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _headers(auth: auth, accountEmail: accountEmail);
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    _assertOk(response);
    final body = _parseBody(response);
    return body is Map<String, dynamic> ? body : {'data': body};
  }

  // ── POST ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String path, {
    dynamic body,
    bool auth = true,
    String? accountEmail,
  }) async {
    final uri = _buildUri(path);
    final headers = await _headers(auth: auth, accountEmail: accountEmail);
    final payload = body != null ? json.encode(body) : null;
    final response = await http.post(uri, headers: headers, body: payload).timeout(_timeout);
    _assertOk(response);
    final resBody = _parseBody(response);
    return resBody is Map<String, dynamic> ? resBody : {'data': resBody};
  }

  // ── DELETE ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParams,
    bool auth = true,
    String? accountEmail,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = await _headers(auth: auth, accountEmail: accountEmail);
    final response = await http.delete(uri, headers: headers).timeout(_timeout);
    _assertOk(response);
    final body = _parseBody(response);
    return body is Map<String, dynamic> ? body : {'data': body};
  }

  // ── MULTIPART UPLOAD ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> upload(
    String path,
    String filePath, {
    String fieldName = 'file',
    String? accountEmail,
  }) async {
    final uri = _buildUri(path);
    final token = await TokenService.getAccessToken(accountEmail);

    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamedResponse);
    _assertOk(response);
    final body = _parseBody(response);
    return body is Map<String, dynamic> ? body : {'data': body};
  }
}
