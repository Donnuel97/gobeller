import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/const/const_api.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/utils/navigator_key.dart';

class ApiService {
  static const String baseUrl = ConstApi.baseUrl;
  static const String basePath = ConstApi.basePath;

  // Helper method to construct full URL
  static String _buildUrl(String endpoint) {
    return '$baseUrl$basePath$endpoint';
  }

  // ✅ Generic GET request
  static Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final defaultHeaders = await ConstApi.getHeaders(); // ✅ Fetch headers dynamically

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'GET request error: $e'};
    }
  }

  // ✅ Generic POST request
  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final defaultHeaders = await ConstApi.getHeaders(); // ✅ Fetch headers dynamically

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,
        },
        body: jsonEncode(formData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'POST request error: $e'};
    }
  }

  // ✅ Generic PATCH request
  static Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final defaultHeaders = await ConstApi.getHeaders(); // ✅ Fetch headers dynamically

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          ...defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,
        },
        body: jsonEncode(formData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'PATCH request error: $e'};
    }
  }

  // Handle API responses and authentication failures
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseData = json.decode(response.body);

      if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
        return {'status': false, 'message': '⚠️ Session expired. Please log in again.'};
      }

      // Return the actual response regardless of statusCode
      if (responseData is Map<String, dynamic>) {
        return responseData;
      } else {
        return {'status': false, 'message': '⚠️ Unexpected response format.'};
      }
    } catch (e) {
      return {'status': false, 'message': '❌ Failed to parse response: $e'};
    }
  }
}
