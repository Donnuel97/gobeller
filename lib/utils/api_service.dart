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

  // Generic GET request
  // Generic GET request with additional headers
  static Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...ConstApi.headers,  // Default headers
          if (token != null) 'Authorization': 'Bearer $token',  // Include token if available
          if (extraHeaders != null) ...extraHeaders,  // Include any extra headers passed to the method
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'GET request error: $e'};
    }
  }


  // Generic POST request
  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ...ConstApi.headers,
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,  // ✅ Allow extra headers
        },
        body: jsonEncode(formData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'POST request error: $e'};
    }
  }

  // Handle API responses and authentication failures
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseData = json.decode(response.body);

      // Handle authentication error (401)
      if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
        return {'status': 'error', 'message': 'User unauthenticated. Redirecting to login.'};
      }

      // Handle other status codes (e.g., 500, 404)
      if (response.statusCode != 200) {
        return {'status': 'error', 'message': 'Request failed with status: ${response.statusCode}'};
      }

      return responseData;
    } catch (e) {
      return {'status': 'error', 'message': 'Response parsing error: $e'};
    }
  }
}
