import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Use the live Railway production backend
      return 'https://cybermfukoni-api-production.up.railway.app';
    }
    return 'http://127.0.0.1:8000';
  }

  static Future<http.Response> get(String endpoint) async {
    final token = await AuthService().getToken();
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 60));
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await AuthService().getToken();
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body != null ? json.encode(body) : null,
    ).timeout(const Duration(seconds: 60));
  }
}
