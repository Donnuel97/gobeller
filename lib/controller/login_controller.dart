import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gobeller/utils/api_service.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String appId = prefs.getString('appId') ?? '';
      if (appId.isEmpty) {
        return {
          'success': false,
          'message': '⚙️ App configuration missing. Please restart the app.'
        };
      }

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

      // ⚡ Add timeout to request
      final response = await ApiService.postRequest(endpoint, body, extraHeaders: headers)
          .timeout(const Duration(seconds: 10));

      final bool status = response['status'] == true;
      final String message = (response['message'] ?? '').toString().trim();

      if (status && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        final String? token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          return {
            'success': false,
            'message': 'Login succeeded but no token was returned.'
          };
        }
        await prefs.setString('auth_token', token);

        final profile = data['profile'];
        if (profile != null) {
          await prefs.setString('user_profile', jsonEncode(profile));

          final String? firstName = profile['first_name'];
          final String? fullName = profile['full_name'];
          if (firstName != null) {
            await prefs.setString('first_name', firstName);
          }
          if (fullName != null) {
            await prefs.setString('full_name', fullName);
          }
        }

        return {'success': true, 'message': '✅ Login successful!'};
      } else {
        String friendly = '❌ Login failed. Please try again.';
        if (message.toLowerCase().contains('invalid credentials')) {
          friendly = '⚠️ Incorrect username or password.';
        } else if (message.isNotEmpty) {
          friendly = message;
        }
        return {'success': false, 'message': friendly};
      }

    } on SocketException {
      return {
        'success': false,
        'message': '📶 No internet connection. Please check your network and try again.'
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': '⏱️ Login request timed out. Please try again shortly.'
      };
    } on ClientException {
      return {
        'success': false,
        'message': '🌐 Unable to connect to server. Please try again later.'
      };
    } catch (e) {
      final error = e.toString().toLowerCase();
      if (error.contains("socketexception") || error.contains("failed host lookup")) {
        return {
          'success': false,
          'message': '📡 Network error. Please check your internet connection.'
        };
      }

      return {
        'success': false,
        'message': '❌ Something went wrong. Please try again shortly.'
      };
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

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
