import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Attempt to log in with [username] and [password].
  /// Returns a map with `success` and `message`.
  Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    _setLoading(true);

    try {
      // 1. Grab the existing AppID from prefs
      final prefs = await SharedPreferences.getInstance();
      final String appId = prefs.getString('appId') ?? '';
      if (appId.isEmpty) {
        return {
          'success': false,
          'message': 'App configuration missing. Please restart the app.'
        };
      }

      // 2. Prepare request
      const String endpoint = '/login';
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'AppID': appId,
      };
      final body = {
        'username': username,
        'password': password,
      };

      // 3. Call the API
      final response =
      await ApiService.postRequest(endpoint, body, extraHeaders: headers);

      final bool status = response['status'] == true;
      final String message = (response['message'] ?? '').toString().trim();

      if (status && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        // 4. Extract and persist token
        final String? token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          return {
            'success': false,
            'message': 'Login succeeded but no token was returned.'
          };
        }
        await prefs.setString('auth_token', token);

        // 5. (Optional) Persist profile JSON for later use
        final profile = data['profile'];
        if (profile != null) {
          await prefs.setString('user_profile', jsonEncode(profile));
        }

        return {'success': true, 'message': 'Login successful!'};
      } else {
        // 6. Friendly error mapping
        String friendly = '❌ Login failed. Please try again.';
        if (message.toLowerCase().contains('invalid credentials')) {
          friendly = '⚠️ Incorrect username or password.';
        } else if (message.isNotEmpty) {
          friendly = message;
        }
        return {'success': false, 'message': friendly};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.'
      };
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /// Utility to show an alert dialog if you need it
  void showMessage(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
