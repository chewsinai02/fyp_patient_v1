import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'dashboard.dart';
import 'widgets/main_layout.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/navigation_utils.dart';
import 'package:fyp_patient_v1/utils/auth_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:bcrypt/bcrypt.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Add loading state
  bool _isLoading = false;

  // Add error message state
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createPasswordResetsTable();
  }

  Future<void> _createPasswordResetsTable() async {
    try {
      await DatabaseService.instance.execute('''
        CREATE TABLE IF NOT EXISTS password_resets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL,
          otp TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          used INTEGER DEFAULT 0
        )
      ''');
      print('Password resets table created or already exists');
    } catch (e) {
      print('Error creating password_resets table: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Top gradient container with logo
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isKeyboardVisible
                      ? constraints.maxHeight * 0.15
                      : constraints.maxHeight * 0.4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.deepPurple.shade50,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isKeyboardVisible) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SUC Hospital',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'A Real-Time Communication and Management System for Families and Hospital in Patient Care System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Login form section
                Expanded(
                  child: ListView(
                    padding:
                        EdgeInsets.fromLTRB(24, 24, 24, keyboardHeight + 24),
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              final emailController = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    'Reset Password',
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Enter your email to reset password',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          hintText: 'Email',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final email =
                                            emailController.text.trim();
                                        if (email.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Please enter your email'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.pop(context); // Close dialog

                                        // Show loading indicator
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                                Text('Sending OTP...'),
                                              ],
                                            ),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );

                                        final success =
                                            await _sendPasswordResetEmail(
                                                email);

                                        if (mounted) {
                                          if (success) {
                                            _showOTPVerificationDialog(email);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Failed to send OTP. Please try again.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(120, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'For assistance, please contact:',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'SUC Hospital Help Desk',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () => _launchEmail(
                                                'chewsinai2002@gmail.com'),
                                            child: Text(
                                              'Email: chewsinai2002@gmail.com',
                                              style: TextStyle(
                                                color: Colors.deepPurple,
                                                fontSize: 14,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () =>
                                                _makePhoneCall('+60177423008'),
                                            child: Text(
                                              'Phone: +60-177423008',
                                              style: TextStyle(
                                                color: Colors.deepPurple,
                                                fontSize: 14,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Need Help?',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(120, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildLoginButton(),
                      const SizedBox(height: 16),
                      Center(
                        child: InkWell(
                          onTap: () => _makePhoneCall('+60177423008'),
                          child: Text(
                            'Please contact the hospital for assistance',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText ?? false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText! ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _handleLogin,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Add login handler method
  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      print('Login attempt started');
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('Email: $email');
      print('Attempting database authentication');
      final user =
          await DatabaseService.instance.authenticateUser(email, password);
      print('Authentication response: $user');

      if (user == null) {
        print('Authentication failed - invalid credentials');
        throw 'Invalid email or password';
      }

      // Set the user data in AuthService after successful authentication
      await AuthService.instance.setCurrentUser(user);
      print('User data set, ID: ${user['id']}');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainLayout(userData: user),
          ),
        );
      }

      // After successful login
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      print('Verified user ID in SharedPreferences: $userId');

      await AuthUtils.saveLoginState(
        isLoggedIn: true,
        userId: userId.toString(),
        userEmail: _emailController.text,
        userData: user,
      );
    } catch (e) {
      print('Login error: $e');
      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email app'),
          ),
        );
      }
    }
  }

  Future<String?> _storeOTP(String email) async {
    try {
      final otp = Random().nextInt(999999).toString().padLeft(6, '0');
      print('Generated OTP: $otp for email: $email');

      // Store in database with correct MySQL datetime syntax
      await DatabaseService.instance.execute(
        '''
        INSERT INTO password_resets (email, otp, created_at, used) 
        VALUES (?, ?, NOW(), 0)
        ''',
        [email, otp],
      );

      // Verify the insert
      final verification = await DatabaseService.instance.query(
        'SELECT * FROM password_resets WHERE email = ? AND otp = ?',
        [email, otp],
      );
      print('Verification result: $verification');

      if (verification.isEmpty) {
        print('OTP was not stored properly');
        return null;
      }

      print('OTP stored successfully');
      return otp;
    } catch (e) {
      print('Error storing OTP: $e');
      return null;
    }
  }

  Future<bool> _sendPasswordResetEmail(String email) async {
    try {
      final otp = await _storeOTP(email);
      if (otp == null) {
        print('Failed to generate and store OTP');
        return false;
      }

      print('Sending email with OTP: $otp');

      // Use Mailtrap API with template
      final response = await http.post(
        Uri.parse('https://sandbox.api.mailtrap.io/api/send/2525051'),
        headers: {
          'Authorization': 'Bearer 853a313e02fdef0a2731e2f94ca6e26a',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "from": {
            "email": "hello@suchospitalchew.infinityfreeapp.com",
            "name": "SUC Hospital"
          },
          "to": [
            {"email": email}
          ],
          "template_uuid": "9ccd37a7-c58a-4a77-b9ed-39dca8fac97d",
          "template_variables": {
            "email": email,
            "OTP": otp,
            "company_info_address": "123 Hospital Street",
            "company_info_city": "Kuching",
            "company_info_zip_code": "93350",
            "company_info_country": "Malaysia"
          }
        }),
      );

      print('API Response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  void _showOTPVerificationDialog(String email) {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Enter OTP',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter the 6-digit code sent to your email',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid 6-digit OTP'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final isValid = await _verifyOTP(email, otp);
              if (isValid) {
                // Mark OTP as used
                await DatabaseService.instance.execute(
                  'UPDATE password_resets SET used = 1 WHERE email = ? AND otp = ?',
                  [email, otp],
                );

                if (mounted) {
                  Navigator.pop(context);
                  _showResetPasswordDialog(email);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid or expired OTP'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Verify'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(String email) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    // Add state variables for password visibility
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        // Wrap with StatefulBuilder to manage state
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Reset Password',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        obscureNewPassword = !obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Get user ID and current password from email
                  final userResults = await DatabaseService.instance.query(
                    'SELECT id, password FROM users WHERE email = ?',
                    [email],
                  );

                  if (userResults.isEmpty) {
                    throw Exception('User not found');
                  }

                  final userId = userResults.first['id'] as int;
                  final currentHashedPassword =
                      userResults.first['password'] as String;

                  // Check if new password is same as current password
                  final normalizedHash =
                      currentHashedPassword.replaceFirst('\$2y', '\$2a');
                  final isSamePassword =
                      BCrypt.checkpw(newPassword, normalizedHash);

                  if (isSamePassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'New password cannot be the same as current password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Update password using the same method as change password
                  await DatabaseService.instance.updatePassword(
                    userId: userId,
                    newPassword: newPassword,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset successful'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to reset password: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<bool> _verifyOTP(String email, String otp) async {
    try {
      final results = await DatabaseService.instance.query(
        '''
        SELECT * FROM password_resets 
        WHERE email = ? 
        AND otp = ? 
        AND used = 0 
        AND created_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE)
        ''',
        [email, otp],
      );

      print('OTP verification results: $results');
      return results.isNotEmpty;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }
}
