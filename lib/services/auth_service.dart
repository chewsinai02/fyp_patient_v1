import 'package:bcrypt/bcrypt.dart';

class AuthService {
  static AuthService? _instance;
  Map<String, dynamic>? _currentUser;

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  Map<String, dynamic>? get currentUser => _currentUser;

  void setCurrentUser(Map<String, dynamic> userData) {
    _currentUser = userData;
  }

  static const String baseUrl = 'your_laravel_api_url';

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

      final currentUser = getCurrentUserId();
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
