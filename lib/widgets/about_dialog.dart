import 'package:flutter/material.dart';

void showAppAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AboutDialog(
      applicationName: 'Patient Care App',
      applicationVersion: 'Version 1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/logo.png', // Make sure to add this asset
          width: 48,
          height: 48,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Patient Care App is designed to help patients manage their healthcare journey effectively. '
          'Our app provides easy access to medical records, appointment scheduling, and direct '
          'communication with healthcare providers.',
        ),
        const SizedBox(height: 16),
        const Text(
          '© 2024 Patient Care App. All rights reserved.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
