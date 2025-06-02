import 'dart:convert';
import 'package:gobeller/utils/secure_storage_helper.dart';
import 'package:gobeller/utils/static_secure_storage_helper.dart';
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

  static Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    StaticSecureStorageHelper _storageHelper = StaticSecureStorageHelper();

    final token = await StaticSecureStorageHelper.retrieveItem(key: 'auth_token');
    final defaultHeaders = await ConstApi.getHeaders();

    print("777777777777777777777777777777777");
    print(token);
    print(extraHeaders);

    Future<http.Response> makeRequest() {
      return http.get(
        Uri.parse(url),
        headers: {
          ...defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,
        },
      );
    }

    try {
      http.Response response = await makeRequest();

      print("88888888888888888888888888888888888888888888888");
      print(response.body.toString());


      if (response.statusCode == 401) {
        response = await makeRequest(); // Retry once
        return _handleResponse(response, retryAttempted: true);
      }
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'GET request error: $e'};
    }
  }

  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    StaticSecureStorageHelper _storageHelper = StaticSecureStorageHelper();

    final token = await StaticSecureStorageHelper.retrieveItem(key: 'auth_token');
    final defaultHeaders = await ConstApi.getHeaders();

    Future<http.Response> makeRequest() {
      return http.post(
        Uri.parse(url),
        headers: {
          ...defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,
        },
        body: jsonEncode(formData),
      );
    }

    try {
      http.Response response = await makeRequest();
      if (response.statusCode == 401) {
        response = await makeRequest(); // Retry once
        return _handleResponse(response, retryAttempted: true);
      }
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'POST request error: $e'};
    }
  }



  static Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    StaticSecureStorageHelper _storageHelper = StaticSecureStorageHelper();

    final token = await StaticSecureStorageHelper.retrieveItem(key: 'auth_token');
    final defaultHeaders = await ConstApi.getHeaders();

    Future<http.Response> makeRequest() {
      return http.patch(
        Uri.parse(url),
        headers: {
          ...defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,
        },
        body: jsonEncode(formData),
      );
    }

    try {
      http.Response response = await makeRequest();
      if (response.statusCode == 401) {
        response = await makeRequest(); // Retry once
        return _handleResponse(response, retryAttempted: true);
      }
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'PATCH request error: $e'};
    }
  }


  static Map<String, dynamic> _handleResponse(http.Response response, {bool retryAttempted = false}) {
    try {
      final responseData = json.decode(response.body);

      // Keep debug prints
      print("88888888888888888888888888888888888888888888888");
      print(response.body.toString());

      // Remove automatic navigation to login on 401
      final isUnauthenticated = response.statusCode == 401 &&
          responseData is Map<String, dynamic> &&
          responseData['message'] == 'Unauthenticated.';

      // Return response data without redirecting to login
      if (responseData is Map<String, dynamic>) {
        return {
          ...responseData,
          'status': response.statusCode >= 200 && response.statusCode < 300,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'status': false,
          'message': 'Unexpected response format.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to parse response: $e',
        'statusCode': response.statusCode,
      };
    }
  }

}
