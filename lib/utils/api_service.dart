// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:gobeller/const/const_api.dart';
// import 'package:gobeller/utils/routes.dart';
// import 'package:gobeller/utils/navigator_key.dart';
//
// class ApiService {
//   static const String baseUrl = ConstApi.baseUrl;
//   static const String basePath = ConstApi.basePath;
//
//   static String _buildUrl(String endpoint) {
//     return '$baseUrl$basePath$endpoint';
//   }
//
//   // ✅ Modified GET request to return statusCode
//   static Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, String>? extraHeaders}) async {
//     final url = _buildUrl(endpoint);
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');
//     final defaultHeaders = await ConstApi.getHeaders();
//
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           ...defaultHeaders,
//           if (token != null) 'Authorization': 'Bearer $token',
//           if (extraHeaders != null) ...extraHeaders,
//         },
//       );
//       return _handleResponse(response);
//     } catch (e) {
//       return {
//         'status': false,
//         'message': 'GET request error: $e',
//         'statusCode': 500
//       };
//     }
//   }
//
//   // ✅ Same for POST and PATCH (optional if you want statusCode from those too)
//   static Future<Map<String, dynamic>> postRequest(
//       String endpoint,
//       Map<String, dynamic> body, {
//         Map<String, String>? extraHeaders,
//       }) async {
//     final uri = Uri.parse('https://app.gobeller.com/api/v1$endpoint');
//     final headers = {
//       'Accept': 'application/json',
//       'Content-Type': 'application/json',
//       if (extraHeaders != null) ...extraHeaders,
//     };
//
//     try {
//       final response = await http
//           .post(uri, headers: headers, body: jsonEncode(body)); // Removed timeout here
//
//       return _handleResponse(response); // ✅ General response handling
//
//     } on SocketException {
//       return {
//         'status': false,
//         'message': '📡 No internet connection. Please check your network.',
//         'statusCode': 503,
//       };
//     } on http.ClientException {
//       return {
//         'status': false,
//         'message': '🌐 Cannot reach the server. Try again shortly.',
//         'statusCode': 503,
//       };
//     } catch (e) {
//       return {
//         'status': false,
//         'message': '❌ Unexpected error: $e',
//         'statusCode': 500,
//       };
//     }
//   }
//
//
//   static Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
//     final url = _buildUrl(endpoint);
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');
//     final defaultHeaders = await ConstApi.getHeaders();
//
//     try {
//       final response = await http.patch(
//         Uri.parse(url),
//         headers: {
//           ...defaultHeaders,
//           if (token != null) 'Authorization': 'Bearer $token',
//           if (extraHeaders != null) ...extraHeaders,
//         },
//         body: jsonEncode(formData),
//       );
//       return _handleResponse(response);
//     } catch (e) {
//       return {
//         'status': false,
//         'message': 'PATCH request error: $e',
//         'statusCode': 500
//       };
//     }
//   }
//
//   // ✅ Modified to always include statusCode in return
//   // static Map<String, dynamic> _handleResponse(http.Response response) {
//   //   try {
//   //     final responseData = json.decode(response.body);
//   //
//   //     // Don't auto-navigate — just return the 401 info
//   //     if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
//   //       return {
//   //         'status': false,
//   //         'message': '⚠️ Unauthorized (401): Session might have expired.',
//   //         'statusCode': response.statusCode
//   //       };
//   //     }
//   //
//   //     if (responseData is Map<String, dynamic>) {
//   //       return {
//   //         ...responseData,
//   //         'statusCode': response.statusCode
//   //       };
//   //     } else {
//   //       return {
//   //         'status': false,
//   //         'message': '⚠️ Unexpected response format.',
//   //         'statusCode': response.statusCode
//   //       };
//   //     }
//   //   } catch (e) {
//   //     return {
//   //       'status': false,
//   //       'message': '❌ Failed to parse response: $e',
//   //       'statusCode': response.statusCode
//   //     };
//   //   }
//   // }
//
//   static Map<String, dynamic> _handleResponse(http.Response response) {
//     try {
//       final responseData = json.decode(response.body);
//
//       // Special handling: If 401, just return empty or a special code — do not pass an error message for UI
//       if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
//         return {
//           'status': false,
//           'statusCode': response.statusCode,
//           // No "message" here — keep it silent
//         };
//       }
//
//       if (responseData is Map<String, dynamic>) {
//         return {
//           ...responseData,
//           'statusCode': response.statusCode
//         };
//       } else {
//         return {
//           'status': false,
//           'message': '⚠️ Unexpected response format.',
//           'statusCode': response.statusCode
//         };
//       }
//     } catch (e) {
//       return {
//         'status': false,
//         'message': '❌ Failed to parse response: $e',
//         'statusCode': response.statusCode
//       };
//     }
//   }
//   // static Map<String, dynamic> _handleResponse(http.Response response) {
//   //   try {
//   //     final responseData = json.decode(response.body);
//   //
//   //     // Check if the response is a 401 (Unauthorized)
//   //     // In case of 401, we return only the status and code, not additional messages.
//   //     if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
//   //       return {
//   //         'status': false,
//   //         'statusCode': response.statusCode,
//   //       };
//   //     }
//   //
//   //     // If the response from the backend is in expected format (Map)
//   //     if (responseData is Map<String, dynamic>) {
//   //       // Only return data directly from the backend (including the statusCode)
//   //       return {
//   //         ...responseData,
//   //         'statusCode': response.statusCode
//   //       };
//   //     } else {
//   //       // If the format is not expected, return minimal information, without custom messages.
//   //       return {
//   //         'status': false,
//   //         'statusCode': response.statusCode,
//   //       };
//   //     }
//   //   } catch (e) {
//   //     // In case of any exception during parsing, just return the statusCode and minimal error info
//   //     return {
//   //       'status': false,
//   //       'message': '❌ Failed to parse response: $e',
//   //       'statusCode': response.statusCode
//   //     };
//   //   }
//   // }
//
//
// }
//
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:gobeller/const/const_api.dart';
// import 'package:gobeller/utils/routes.dart';
// import 'package:gobeller/utils/navigator_key.dart';
//
// class ApiService {
//   static const String baseUrl = ConstApi.baseUrl;
//   static const String basePath = ConstApi.basePath;
//
//   // Helper method to construct full URL
//   static String _buildUrl(String endpoint) {
//     return '$baseUrl$basePath$endpoint';
//   }
//
//   // ✅ Generic GET request
//   static Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, String>? extraHeaders}) async {
//     final url = _buildUrl(endpoint);
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');
//     final defaultHeaders = await ConstApi.getHeaders(); // ✅ Fetch headers dynamically
//
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           ...defaultHeaders,
//           if (token != null) 'Authorization': 'Bearer $token',
//           if (extraHeaders != null) ...extraHeaders,
//         },
//       );
//       return _handleResponse(response);
//     } catch (e) {
//       return {'status': 'error', 'message': 'GET request error: $e'};
//     }
//   }
//
//   // ✅ Generic POST request
//   static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
//     final url = _buildUrl(endpoint);
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');
//     final defaultHeaders = await ConstApi.getHeaders(); // ✅ Fetch headers dynamically
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           ...defaultHeaders,
//           if (token != null) 'Authorization': 'Bearer $token',
//           if (extraHeaders != null) ...extraHeaders,
//         },
//         body: jsonEncode(formData),
//       );
//       return _handleResponse(response);
//     } catch (e) {
//       return {'status': 'error', 'message': 'POST request error: $e'};
//     }
//   }
//
//   // ✅ Generic PATCH request
//   static Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
//     final url = _buildUrl(endpoint);
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');
//     final defaultHeaders = await ConstApi.getHeaders(); // ✅ Fetch headers dynamically
//
//     try {
//       final response = await http.patch(
//         Uri.parse(url),
//         headers: {
//           ...defaultHeaders,
//           if (token != null) 'Authorization': 'Bearer $token',
//           if (extraHeaders != null) ...extraHeaders,
//         },
//         body: jsonEncode(formData),
//       );
//       return _handleResponse(response);
//     } catch (e) {
//       return {'status': 'error', 'message': 'PATCH request error: $e'};
//     }
//   }
//
//   // Handle API responses and authentication failures
//   static Map<String, dynamic> _handleResponse(http.Response response) {
//     try {
//       final responseData = json.decode(response.body);
//
//       if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
//         navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
//
//         // Return the actual responseData but force status = false
//         if (responseData is Map<String, dynamic>) {
//           return {
//             ...responseData,
//             'status': false,
//             'statusCode': response.statusCode,
//           };
//         } else {
//           return {
//             'status': false,
//             'message': 'Unexpected response format.',
//             'statusCode': response.statusCode,
//           };
//         }
//       }
//
//       // ✅ For all other responses (including other errors or success), return responseData
//       if (responseData is Map<String, dynamic>) {
//         return {
//           ...responseData,
//           'statusCode': response.statusCode,
//         };
//       } else {
//         return {
//           'status': false,
//           'message': 'Unexpected response format.',
//           'statusCode': response.statusCode,
//         };
//       }
//     } catch (e) {
//       return {
//         'status': false,
//         'message': 'Failed to parse response: $e',
//         'statusCode': response.statusCode,
//       };
//     }
//   }
//
// }


import 'dart:convert';
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
    final token = prefs.getString('access_token');
    final defaultHeaders = await ConstApi.getHeaders();

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
      if (response.statusCode == 401) {
        response = await makeRequest(); // Retry once
        if (response.statusCode == 401) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
        }
      }
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'GET request error: $e'};
    }
  }

  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
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
        if (response.statusCode == 401) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
        }
      }
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'POST request error: $e'};
    }
  }

  static Future<Map<String, dynamic>> patchRequest(String endpoint, Map<String, dynamic> formData, {Map<String, String>? extraHeaders}) async {
    final url = _buildUrl(endpoint);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
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
        if (response.statusCode == 401) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
        }
      }
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'PATCH request error: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseData = json.decode(response.body);

      if (response.statusCode == 401 || responseData['message'] == 'Unauthenticated.') {
        // Already handled retry outside this method
        if (responseData is Map<String, dynamic>) {
          return {
            ...responseData,
            'status': false,
            'statusCode': response.statusCode,
          };
        } else {
          return {
            'status': false,
            'message': 'Unexpected response format.',
            'statusCode': response.statusCode,
          };
        }
      }

      if (responseData is Map<String, dynamic>) {
        return {
          ...responseData,
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
