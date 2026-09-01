import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode = 200,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {int statusCode = 200}) {
    return ApiResponse(
      success: json['success'] as bool? ?? (statusCode >= 200 && statusCode < 300),
      message: json['message'] as String? ?? json['error'] as String? ?? (statusCode >= 200 && statusCode < 300 ? 'Success' : 'API Request Failed ($statusCode)'),
      data: json['data'] ?? json,
      statusCode: statusCode,
    );
  }
}

class ApiClient {
  static Map<String, String> _buildHeaders({String? token}) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final client = http.Client();
    try {
      final headers = _buildHeaders(token: token);
      final bodyStr = body != null ? jsonEncode(body) : null;
      debugPrint('➡️ [API POST] $url');
      debugPrint('   Headers: $headers');
      debugPrint('   Payload: $bodyStr');

      final response = await client
          .post(
            Uri.parse(url),
            headers: headers,
            body: bodyStr,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('⬅️ [API RESPONSE ${response.statusCode}] $url');
      debugPrint('   Body: ${response.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = {'message': response.body};
      }

      if (parsed is Map<String, dynamic>) {
        return ApiResponse.fromJson(parsed, statusCode: response.statusCode);
      } else {
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : response.body,
          data: parsed,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ [API ERROR] $url: $e');
      debugPrint('   Stack: $stack');
      return ApiResponse(
        success: false,
        message: 'Network connection error: ${e.toString()}',
        statusCode: 500,
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> patch(
    String url, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final client = http.Client();
    try {
      final headers = _buildHeaders(token: token);
      final bodyStr = body != null ? jsonEncode(body) : null;
      debugPrint('➡️ [API PATCH] $url');
      debugPrint('   Headers: $headers');
      debugPrint('   Payload: $bodyStr');

      final response = await client
          .patch(
            Uri.parse(url),
            headers: headers,
            body: bodyStr,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('⬅️ [API RESPONSE ${response.statusCode}] $url');
      debugPrint('   Body: ${response.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = {'message': response.body};
      }

      if (parsed is Map<String, dynamic>) {
        return ApiResponse.fromJson(parsed, statusCode: response.statusCode);
      } else {
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : response.body,
          data: parsed,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ [API ERROR] $url: $e');
      debugPrint('   Stack: $stack');
      return ApiResponse(
        success: false,
        message: 'Network connection error: ${e.toString()}',
        statusCode: 500,
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> put(
    String url, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final client = http.Client();
    try {
      final headers = _buildHeaders(token: token);
      final bodyStr = body != null ? jsonEncode(body) : null;
      debugPrint('➡️ [API PUT] $url');
      debugPrint('   Headers: $headers');
      debugPrint('   Payload: $bodyStr');

      final response = await client
          .put(
            Uri.parse(url),
            headers: headers,
            body: bodyStr,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('⬅️ [API RESPONSE ${response.statusCode}] $url');
      debugPrint('   Body: ${response.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = {'message': response.body};
      }

      if (parsed is Map<String, dynamic>) {
        return ApiResponse.fromJson(parsed, statusCode: response.statusCode);
      } else {
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : response.body,
          data: parsed,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ [API ERROR] $url: $e');
      debugPrint('   Stack: $stack');
      return ApiResponse(
        success: false,
        message: 'Network connection error: ${e.toString()}',
        statusCode: 500,
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> get(
    String url, {
    String? token,
  }) async {
    final client = http.Client();
    try {
      final headers = _buildHeaders(token: token);
      debugPrint('➡️ [API GET] $url');
      final response = await client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('⬅️ [API RESPONSE ${response.statusCode}] $url');
      debugPrint('   Body: ${response.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = {'message': response.body};
      }

      if (parsed is Map<String, dynamic>) {
        return ApiResponse.fromJson(parsed, statusCode: response.statusCode);
      } else {
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : response.body,
          data: parsed,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('❌ [API ERROR] $url: $e');
      return ApiResponse(
        success: false,
        message: 'Network connection error: ${e.toString()}',
        statusCode: 500,
      );
    } finally {
      client.close();
    }
  }

  static Future<ApiResponse> delete(
    String url, {
    String? token,
  }) async {
    final client = http.Client();
    try {
      final headers = _buildHeaders(token: token);
      debugPrint('➡️ [API DELETE] $url');
      final response = await client
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('⬅️ [API RESPONSE ${response.statusCode}] $url');
      debugPrint('   Body: ${response.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = {'message': response.body};
      }

      if (parsed is Map<String, dynamic>) {
        return ApiResponse.fromJson(parsed, statusCode: response.statusCode);
      } else {
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: response.statusCode >= 200 && response.statusCode < 300 ? 'Success' : response.body,
          data: parsed,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('❌ [API ERROR] $url: $e');
      return ApiResponse(
        success: false,
        message: 'Network connection error: ${e.toString()}',
        statusCode: 500,
      );
    } finally {
      client.close();
    }
  }
}
