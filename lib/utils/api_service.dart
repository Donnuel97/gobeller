import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gobeller/const/const_api.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:gobeller/utils/navigator_key.dart';

class ApiService {
  static const String baseUrl = ConstApi.baseUrl;
  static const String basePath = ConstApi.basePath;

  static String _buildUrl(String endpoint) {
    return '$baseUrl$basePath$endpoint';
  }

  // ✅ Modified GET request to return statusCode
  static Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final defaultHeaders = await ConstApi.getHeaders();

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
      return {
        'status': false,
        'message': 'GET request error: $e',
        'statusCode': 500
      };
    }
  }

  // ✅ Same for POST and PATCH (optional if you want statusCode from those too)
  static Future<Map<String, dynamic>> postRequest(
      String endpoint,
      Map<String, dynamic> body, {
        Map<String, String>? extraHeaders,
      }) async {
    final uri = Uri.parse('https://app.gobeller.com/api/v1$endpoint');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (extraHeaders != null) ...extraHeaders,
    };

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body)); // Removed timeout here

      return _handleResponse(response); // ✅ General response handling

    } on SocketException {
      return {
        'status': false,
        'message': '📡 No internet connection. Please check your network.',
        'statusCode': 503,
      };
    } on http.ClientException {
      return {
        'status': false,
        'message': '🌐 Cannot reach the server. Try again shortly.',
        'statusCode': 503,
      };
    } catch (e) {
      return {
        'status': false,
        'message': '❌ Unexpected error: $e',
        'statusCode': 500,
      };
    }
  }


  static Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final defaultHeaders = await ConstApi.getHeaders();

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
      return {
        'status': false,
        'message': 'PATCH request error: $e',
        'statusCode': 500
      };
    }
  }

  // ✅ Modified to always include statusCode in return
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseData = json.decode(response.body);

      // Don't auto-navigate — just return the 401 info
      if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
        return {
          'status': false,
          'message': '⚠️ Unauthorized (401): Session might have expired.',
          'statusCode': response.statusCode
        };
      }

      if (responseData is Map<String, dynamic>) {
        return {
          ...responseData,
          'statusCode': response.statusCode
        };
      } else {
        return {
          'status': false,
          'message': '⚠️ Unexpected response format.',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': '❌ Failed to parse response: $e',
        'statusCode': response.statusCode
      };
    }
  }

}
