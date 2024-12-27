import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpSection(
            'Getting Started',
            [
              {
                'title': 'How to login',
                'content': '''
• Enter your registered email address
• Enter your password
• Tap the "Login" button
• If you forgot your password, use the "Forgot Password" to contact our admin.
''',
              },
              {
                'title': 'Viewing your profile',
                'content': '''
• Go to Settings
• Tap on "Edit Profile"
• View or update your personal information:
  - Profile picture
  - Name
  - Email
  - Phone number
''',
              },
              {
                'title': 'Changing your password',
                'content': '''
• Go to Settings
• Select "Change Password"
• Enter your current password
• Enter and confirm your new password
• Make sure your new password:
  - Is at least 8 characters long
  - Contains letters and numbers
  - Is different from your current password
''',
              },
              {
                'title': 'Updating personal information',
                'content': '''
• Navigate to Settings
• Tap "Edit Profile"
• Update your details:
  - Profile picture
  - Personal information
  - Contact details
• Save your changes
''',
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            'Appointments',
            [
              {
                'title': 'Booking an appointment',
                'content': '''
• Go to the Appointments section
• Select "Book New Appointment"
• Choose your preferred:
  - Doctor
  - Date
  - Available time slot
• Add any notes or special requests
• Confirm your booking
''',
              },
              {
                'title': 'Viewing upcoming appointments',
                'content': '''
• Open the Appointments tab
• View your scheduled appointments
• Check details such as:
  - Doctor's name
  - Date and time
  - Location/Room number
  - Appointment status
''',
              },
              {
                'title': 'Canceling an appointment',
                'content': '''
• Sorry, our app is not yet able to cancel appointments.
• Please contact our hospital to cancel your appointment.
 Note: Please cancel at least 24 hours in advance
''',
              },
              {
                'title': 'Rescheduling an appointment',
                'content': '''
• Sorry, our app is not yet able to reschedule appointments.
• Please contact our hospital to reschedule your appointment.
 Note: Please reschedule at least 24 hours in advance
''',
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            'Medical Records',
            [
              {
                'title': 'Accessing medical reports',
                'content': '''
• Go to Medical Records section
• View list of all your reports
• Reports are organized by:
  - Date
  - Type
  - Doctor
• Tap on any report to view details
''',
              },
              {
                'title': 'Understanding your reports',
                'content': '''
• Each report includes:
  - Diagnosis
  - Treatment plan
  - Medications
  - Lab results
  - Vital signs
  - Doctor's notes
• Contact your healthcare provider for clarification
''',
              },
              {
                'title': 'Downloading reports',
                'content': '''
• Open the desired report
• Look for the download icon
• Choose download format (PDF/Image)
• Select save location
• Access downloaded reports in your device
''',
              },
              {
                'title': 'Sharing reports with doctors',
                'content': '''
• Open the report you want to share
• Tap the share button
• Choose sharing method:
  - Direct to doctor
  - Email
  - Download and share
• Confirm sharing permissions
''',
              },
            ],
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            'Communication',
            [
              {
                'title': 'Chatting with doctors',
                'content': '''
• Access the Messages section
• Select your doctor from the list
• Start a new conversation
• You can:
  - Send text messages
  - Share images
  - Ask questions
• Maintain professional communication
''',
              },
              {
                'title': 'Sending messages',
                'content': '''
• Open a chat conversation
• Type your message
• Add attachments if needed
• Send your message
• Wait for response during business hours
''',
              },
              {
                'title': 'Viewing chat history',
                'content': '''
• Go to Messages
• Select a conversation
• Scroll through previous messages
• Messages are saved for future reference
• Search for specific messages using keywords
''',
              },
              {
                'title': 'Notifications settings',
                'content': '''
• Go to Settings
• Select Notifications
• Customize your preferences:
  - Push notifications
  - Message alerts
  - Appointment reminders
  - Email notifications
''',
              },
            ],
          ),
          const SizedBox(height: 24),
          _buildContactSupport(),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<Map<String, String>> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: items.map((item) => _buildHelpItem(item)).toList(),
      ),
    );
  }

  Widget _buildHelpItem(Map<String, String> item) {
    return ExpansionTile(
      title: Text(
        item['title']!,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            item['content']!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupport() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need more help?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contact our support team for assistance',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchEmail(),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@patientcare.com',
      queryParameters: {
        'subject': 'Patient Care App Support',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}
