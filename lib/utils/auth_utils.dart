import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthUtils {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserData = 'userData';

  // Save user login state
  static Future<void> saveLoginState({
    required bool isLoggedIn,
    required String userId,
    required String userEmail,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserEmail, userEmail);
    await prefs.setString(_keyUserData, userData.toString());
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get stored user data
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_keyUserData);
    if (userDataString == null) return {};

    // Convert string back to Map
    final userDataMap = Map<String, dynamic>.from(
        // Parse the string representation of the map
        jsonDecode(userDataString) as Map);
    return userDataMap;
  }

  // Clear stored credentials
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
