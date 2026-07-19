import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class ActiveDefenseService {
  /// Check if a phone number has been reported as a scam.
  static Future<Map<String, dynamic>> checkNumber(String phoneNumber) async {
    try {
      final response = await ApiService.get('/api/active-defense/check/$phoneNumber');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed: $e'};
    }
  }

  /// Report a phone number as fraudulent.
  static Future<Map<String, dynamic>> reportNumber({
    required String phoneNumber,
    required String scamCategory,
    String? details,
  }) async {
    try {
      final response = await ApiService.post('/api/active-defense/report', body: {
        'phone_number': phoneNumber,
        'scam_category': scamCategory,
        if (details != null && details.isNotEmpty) 'details': details,
      });
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection failed: $e'};
    }
  }
}
