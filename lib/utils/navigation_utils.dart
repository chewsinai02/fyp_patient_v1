import 'package:flutter/material.dart';
import '../dashboard.dart';
import '../services/auth_service.dart';

bool canPopRoute(BuildContext context) {
  // Get the current route name
  final currentRoute = ModalRoute.of(context);
  if (currentRoute == null) return false;

  // If we're in MainLayout or its children, prevent back navigation
  if (currentRoute.settings.name == '/dashboard' ||
      currentRoute.settings.name == null || // For pages in MainLayout
      currentRoute.settings.name == '/' ||
      currentRoute.settings.name == '/login') {
    return false;
  }

  // Allow back navigation for other pages
  return true;
}

// For logout functionality
void logoutAndNavigateToLogin(BuildContext context) {
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/login',
    (route) => false,
  );
}

void handleBackPress(BuildContext context) async {
  // Get the current user data from AuthService
  final userData = await AuthService.instance.getCurrentUserData();
  if (userData != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Dashboard(userData: userData),
      ),
    );
  }
}
