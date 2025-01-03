import 'package:flutter/material.dart';
import 'package:fyp_patient_v1/utils/auth_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/main_layout.dart';
import 'login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/adaptive_image_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications first with proper error handling
  try {
    print('\n=== INITIALIZING NOTIFICATIONS ===');
    final notificationService = NotificationService.instance;
    await notificationService.initialize();
    await notificationService.requestPermissions();
    print('Notification service initialized successfully\n');
  } catch (e) {
    print('Error initializing notifications: $e');
  }

  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUC Hospital',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        extensions: [
          AdaptiveImageTheme(
            defaultFallbackAsset: 'assets/images/profile.png',
            defaultLoadingColor: Colors.grey[200]!,
          ),
        ],
      ),
      home: FutureBuilder<bool>(
        future: AuthUtils.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.data == true) {
            return FutureBuilder<Map<String, dynamic>>(
              future: AuthUtils.getUserData(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                  return LoginPage();
                }
                return MainLayout(userData: userSnapshot.data!);
              },
            );
          }

          return LoginPage();
        },
      ),
    );
  }
}
