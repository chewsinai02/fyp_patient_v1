import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'widgets/main_layout.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_patient_v1/utils/auth_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:io';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
          id INT PRIMARY KEY AUTO_INCREMENT,
          email VARCHAR(255) NOT NULL,
          otp VARCHAR(6) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          used TINYINT(1) DEFAULT 0
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

                                        _handleResetPassword(context, email);
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

      // Load and encode logo image
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      final List<int> logoBytes = logoData.buffer.asUint8List();
      final String logoBase64 = base64Encode(logoBytes);

      // Gmail SMTP configuration
      String username = 'chewsinai2002@gmail.com';
      String password = 'bohv qjdl bjcq qktb';

      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'SUC Hospital')
        ..recipients.add(email)
        ..subject = 'Password Reset OTP'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 5px;
        }
        .header {
            text-align: center;
            padding: 20px 0;
            background-color: #673ab7;
            color: white;
            border-radius: 5px 5px 0 0;
        }
        .logo {
            width: 80px;
            height: 80px;
            margin: 0 auto 10px;
            background-color: white;
            border-radius: 50%;
            padding: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .logo img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }
        .content {
            padding: 20px;
            background-color: white;
            border-radius: 0 0 5px 5px;
        }
        .otp-code {
            font-size: 32px;
            font-weight: bold;
            text-align: center;
            color: #673ab7;
            padding: 20px;
            margin: 20px 0;
            background-color: #f0f0f0;
            border-radius: 5px;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            font-size: 12px;
            color: #666666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">
                <img src="data:image/png;base64,$logoBase64" alt="SUC Hospital Logo">
            </div>
            <h1>SUC Hospital</h1>
        </div>
        <div class="content">
            <h2>Password Reset Request</h2>
            <p>Dear User,</p>
            <p>We received a request to reset your password. Please use the following OTP code to proceed with your password reset:</p>
            
            <div class="otp-code">
                $otp
            </div>
            
            <p>This OTP will expire in 15 minutes. If you did not request this password reset, please ignore this email.</p>
            
            <p>For security reasons, please do not share this OTP with anyone.</p>
            
            <p>Best regards,<br>SUC Hospital Team</p>
        </div>
        <div class="footer">
            <p>This is an automated message, please do not reply to this email.</p>
            <p>© ${DateTime.now().year} SUC Hospital. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
''';

      try {
        final sendReport = await send(message, smtpServer);
        print('Email sent: ${sendReport.toString()}');
        return true;
      } on MailerException catch (e) {
        print('Failed to send email: ${e.message}');
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      print('\n=== Error Details ===');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
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

  Future<void> _handleResetPassword(BuildContext context, String email) async {
    if (!mounted) return;

    try {
      final success = await _sendPasswordResetEmail(email);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context); // Close the current dialog
        _showOTPVerificationDialog(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> sendEmail(
    BuildContext context, String recipientEmail, String otp) async {
  String username = 'chewsinai2002@gmail.com'; // Your Email
  String password =
      'bohv qjdl bjcq qktb'; // 16 Digits App Password Generated From Google Account

  final smtpServer = gmail(username, password);

  // Create our message.
  final message = Message()
    ..from = Address(username, 'Confirmation Bot')
    ..recipients.add(recipientEmail) // Dynamic recipient email
    ..subject = 'Your OTP Code'
    ..text = 'Hello dear,\n\nYour OTP code is: $otp\n\nThank you!';

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Mail sent successfully")));
  } on MailerException catch (e) {
    print('Message not sent.');
    print(e.message);
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send mail: ${e.message}")));
  }
}
