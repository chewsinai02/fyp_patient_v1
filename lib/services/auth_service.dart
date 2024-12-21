import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  Map<String, dynamic>? _currentUser;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static AuthService get instance => _instance;

  static const String baseUrl = 'your_laravel_api_url';

  void setCurrentUser(Map<String, dynamic> userData) {
    print('Setting current user: $userData');
    _currentUser = userData;
    print('Current user after setting: $_currentUser');
  }

  Map<String, dynamic>? getCurrentUser() {
    print('Getting current user: $_currentUser');
    if (_currentUser == null) {
      print('WARNING: No user is currently logged in!');
    }
    return _currentUser;
  }

  Future<int?> getCurrentUserId() async {
    return _currentUser?['id'];
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print('Attempting login for email: $email');

      final mockUserData = {
        'id': 1,
        'name': 'Test User',
        'email': email,
        // Add other necessary user data
      };

      print('Login successful, setting user data');
      setCurrentUser(mockUserData);

      final currentUser = getCurrentUser();
      print('Verifying current user after login: $currentUser');

      return mockUserData;

      /* Uncomment this for actual API call
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        _currentUser = json.decode(response.body);
        return _currentUser;
      } else {
        print('Login failed: ${response.body}');
        return null;
      }
      */
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  bool verifyPassword(String plainPassword, String hashedPassword) {
    return BCrypt.checkpw(plainPassword, hashedPassword);
  }

  void logout() {
    print('Logging out user: $_currentUser');
    _currentUser = null;
    print('User after logout: $_currentUser');
  }
}
