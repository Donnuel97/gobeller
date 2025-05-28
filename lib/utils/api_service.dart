import 'dart:async';
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
  static const String TOKEN_KEY = 'auth_token'; // Standardized token key
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 30);
  static const int MAX_RETRIES = 2;

  static String _buildUrl(String endpoint) {
    return '$baseUrl$basePath$endpoint';
  }

  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  // Prepare headers with token and app ID
  static Future<Map<String, String>> _prepareHeaders({Map<String, String>? extraHeaders}) async {
    final defaultHeaders = await ConstApi.getHeaders();
    final token = await _getToken();

    return {
          ...defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          if (extraHeaders != null) ...extraHeaders,
    };
  }

  // Generic request handler with retry logic
  static Future<Map<String, dynamic>> _makeRequest(
    Future<http.Response> Function(Map<String, String> headers) requestFn,
    {Map<String, String>? extraHeaders}
  ) async {
    int attempts = 0;
    late http.Response response;
    
    while (attempts < MAX_RETRIES) {
      try {
        final headers = await _prepareHeaders(extraHeaders: extraHeaders);
        response = await requestFn(headers).timeout(REQUEST_TIMEOUT);
        
        // If response is successful, return immediately
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _handleResponse(response);
        }
        
        // Handle 401 specifically
      if (response.statusCode == 401) {
          // On first 401, try to refresh token (if implemented) or retry once
          if (attempts == 0) {
            attempts++;
            continue;
          }
          // On second 401, clear token and redirect to login
          else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(TOKEN_KEY);
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              Routes.login, (route) => false);
            return _handleResponse(response, forceLogout: true);
          }
        }
        
        // For other error codes, return the response
        return _handleResponse(response);
        
      } on TimeoutException {
        attempts++;
        if (attempts == MAX_RETRIES) {
          return {
            'status': false,
            'message': '⌛ Request timed out. Please try again.',
            'statusCode': 408
          };
        }
      } catch (e) {
        return {
          'status': false,
          'message': 'Request error: $e',
          'statusCode': 500
        };
      }
    }
    
    // This should never be reached due to the return statements above
    return {
      'status': false,
      'message': '❌ Maximum retry attempts reached',
      'statusCode': 500
    };
  }

  static Future<Map<String, dynamic>> getRequest(
    String endpoint, 
    {Map<String, String>? extraHeaders}
  ) async {
    return _makeRequest(
      (headers) => http.get(Uri.parse(_buildUrl(endpoint)), headers: headers),
      extraHeaders: extraHeaders
    );
  }

  static Future<Map<String, dynamic>> postRequest(
    String endpoint,
    Map<String, dynamic> body,
    {Map<String, String>? extraHeaders}
  ) async {
    return _makeRequest(
      (headers) => http.post(
        Uri.parse(_buildUrl(endpoint)),
        headers: headers,
        body: jsonEncode(body)
      ),
      extraHeaders: extraHeaders
    );
  }

  static Future<Map<String, dynamic>> patchRequest(
    String endpoint,
    Map<String, dynamic> body,
    {Map<String, String>? extraHeaders}
  ) async {
    return _makeRequest(
      (headers) => http.patch(
        Uri.parse(_buildUrl(endpoint)),
        headers: headers,
        body: jsonEncode(body)
      ),
      extraHeaders: extraHeaders
    );
  }

  static Map<String, dynamic> _handleResponse(
    http.Response response, 
    {bool forceLogout = false}
  ) {
    try {
      final responseData = json.decode(response.body);

      // For successful responses
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          ...responseData is Map ? responseData : {'data': responseData},
          'status': true,
          'statusCode': response.statusCode,
        };
      }
      
      // For 401 responses
      if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
        return {
          'status': false,
          'statusCode': response.statusCode,
          'message': forceLogout 
            ? '🔒 Your session has expired. Please log in again.'
            : responseData['message'] ?? 'Authentication failed',
        };
      }
      
      // For all other responses
      return {
        ...responseData is Map ? responseData : {'data': responseData},
        'status': false,
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'Request failed',
      };
      
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to parse response: $e',
        'statusCode': response.statusCode,
      };
    }
  }
}
