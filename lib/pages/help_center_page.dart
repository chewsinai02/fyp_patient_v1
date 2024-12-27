import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 19, 15, 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple,
                    Colors.deepPurple.shade300,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Help Center',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get help and find answers to your questions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHelpSection(
                    'Getting Started',
                    [
                      {
                        'title': 'How to login',
                        'content': 'Enter your registered email address \n' +
                            'Enter your password \n' +
                            'Tap the "Login" button \n' +
                            'If you forgot your password, use the "Forgot Password" to contact our admin.',
                      },
                      {
                        'title': 'Viewing your profile',
                        'content': 'Go to Settings \n' +
                            'Tap on "Edit Profile" \n' +
                            'View or update your personal information: Profile picture, Name, Email, Phone number',
                      },
                      {
                        'title': 'Changing your password',
                        'content': 'Go to Settings \n' +
                            'Select "Change Password" \n' +
                            'Enter your current password \n' +
                            'Enter and confirm your new password \n' +
                            'Make sure your new password: Is at least 8 characters long, Contains letters and numbers, Is different from your current password',
                      },
                      {
                        'title': 'Updating personal information',
                        'content': 'Navigate to Settings \n' +
                            'Tap "Edit Profile" \n' +
                            'Update your details: Profile picture, Personal information, Contact details \n' +
                            'Save your changes',
                      },
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(
                    'Appointments',
                    [
                      {
                        'title': 'Booking an appointment',
                        'content': 'Go to the Appointments section \n' +
                            'Select "Book New Appointment" \n' +
                            'Choose your preferred: Doctor, Date, Available time slot \n' +
                            'Add any notes or special requests \n' +
                            'Confirm your booking',
                      },
                      {
                        'title': 'Viewing upcoming appointments',
                        'content': 'Open the Appointments tab \n' +
                            'View your scheduled appointments \n' +
                            'Check details such as: Doctor\'s name, Date and time, Location/Room number, Appointment status',
                      },
                      {
                        'title': 'Canceling an appointment',
                        'content': 'Sorry, our app is not yet able to cancel appointments \n' +
                            'Please contact our hospital to cancel your appointment \n' +
                            'Note: Please cancel at least 24 hours in advance',
                      },
                      {
                        'title': 'Rescheduling an appointment',
                        'content': 'Sorry, our app is not yet able to reschedule appointments \n' +
                            'Please contact our hospital to reschedule your appointment \n' +
                            'Note: Please reschedule at least 24 hours in advance',
                      },
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(
                    'Medical Records',
                    [
                      {
                        'title': 'Accessing medical reports',
                        'content':
                            'Click on Reports section in the functions page\n' +
                                'View list of all your reports \n' +
                                'Reports are organized by: Date, Type, Doctor \n' +
                                'Tap on any report to view details',
                      },
                      {
                        'title': 'Understanding your reports',
                        'content':
                            'Each report includes: Diagnosis, Treatment plan, Medications, Lab results, Vital signs, Doctor\'s notes \n' +
                                'Contact your healthcare provider for clarification',
                      },
                      {
                        'title': 'Downloading reports',
                        'content': 'Open the desired report \n' +
                            'Look for the download icon \n' +
                            'Access downloaded reports in your device',
                      },
                      {
                        'title': 'Sharing reports with doctors',
                        'content': 'Open the report you want to share \n' +
                            'Tap the share button \n' +
                            'Choose sharing method: Direct to doctor, Email, Download and share \n' +
                            'Confirm sharing permissions',
                      },
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHelpSection(
                    'Communication',
                    [
                      {
                        'title': 'Chatting with doctors',
                        'content': 'Access the Messages section \n' +
                            'Select your doctor from the list \n' +
                            'Start a new conversation \n' +
                            'You can: Send text messages, Share images, Ask questions \n' +
                            'Maintain professional communication',
                      },
                      {
                        'title': 'Sending messages',
                        'content': 'Open a chat conversation \n' +
                            'Type your message \n' +
                            'Add attachments if needed \n' +
                            'Send your message \n' +
                            'Wait for response during business hours',
                      },
                      {
                        'title': 'Viewing chat history',
                        'content': 'Go to Messages \n' +
                            'Select a conversation \n' +
                            'Scroll through previous messages \n' +
                            'Messages are saved for future reference \n' +
                            'Search for specific messages using keywords',
                      },
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildContactSupport(),
                ],
              ),
            ),
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item['content']!.split('\n').map((line) {
              if (line.trim().isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 24),
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.trim().startsWith('•')
                            ? line.trim().substring(1).trim()
                            : line.trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
                    onPressed: () => _launchCall(),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Call Support'),
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

  void _launchCall() async {
    final Uri callUri = Uri(
      scheme: 'tel',
      path: '+60-177423008',
    );

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}
