import 'package:flutter/material.dart';
import 'nurse_calling_page.dart';
import 'pages/daily_tasks_page.dart';
// import 'pages/medications_page.dart'; // Commented out
import 'pages/reports_page.dart';
// import 'pages/vitals_page.dart'; // Commented out
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/doctors_page.dart';
import 'services/auth_service.dart';
import 'pages/messages_page.dart';
import 'services/database_service.dart';

class FunctionPage extends StatelessWidget {
  const FunctionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildHealthServices(context),
                    const SizedBox(height: 32),
                    _buildPersonalSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Access all healthcare services',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions'),
        Row(
          children: [
            Expanded(
              child: _buildFunctionCard(
                title: 'Emergency',
                icon: Icons.emergency_outlined,
                color: Colors.red,
                onTap: () async {
                  try {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Get current user data
                    final userData = AuthService.instance.currentUser;
                    if (userData == null) {
                      if (context.mounted) {
                        Navigator.pop(context); // Remove loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User data not found')),
                        );
                      }
                      return;
                    }

                    // Fetch user data based on patient ID
                    final userId = int.parse(userData['id'].toString());
                    final patientData =
                        await DatabaseService.instance.getUserById(userId);

                    if (patientData == null) {
                      if (context.mounted) {
                        Navigator.pop(context); // Remove loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Unable to fetch patient data')),
                        );
                      }
                      return;
                    }

                    // Get current time and determine shift
                    final now = DateTime.now();
                    String currentShift;
                    if (now.hour >= 7 && now.hour < 15) {
                      currentShift = 'morning';
                    } else if (now.hour >= 15 && now.hour < 23) {
                      currentShift = 'afternoon';
                    } else {
                      currentShift = 'night';
                    }

                    // Fetch assigned nurse for current shift
                    final nurseData =
                        await DatabaseService.instance.getNurseSchedule(
                      roomId: patientData['room_id'],
                      shift: currentShift,
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // Remove loading indicator
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NurseCallingPage(
                            patientId: userId,
                            patientName: patientData['patient_name'] ??
                                patientData['name'] ??
                                userData['name'] ??
                                'Unknown Patient',
                            roomNumber: patientData['room_number'] ?? 0,
                            bedNumber: patientData['bed_number'] ?? 0,
                            bedId: patientData['bed_id'] ??
                                patientData['bed_number'] ??
                                0,
                            roomId: patientData['room_id'] ?? 0,
                            floor: patientData['floor'] ?? 0,
                            assignedNurseId: nurseData?['nurse_id'] ?? 0,
                            currentShift: currentShift,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Remove loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                    print('Error navigating to nurse call: $e');
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFunctionCard(
                title: 'Daily Tasks',
                icon: Icons.task_alt_outlined,
                color: Colors.blue,
                onTap: () {
                  final user = AuthService.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DailyTasksPage(
                          patientId: user['id'],
                          patientName: user['name'],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthServices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Health Services'),
        Row(
          children: [
            Expanded(
              child: _buildFunctionCard(
                title: 'Our Doctors',
                icon: Icons.medical_services_outlined,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorsPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFunctionCard(
                title: 'Reports',
                icon: Icons.analytics_outlined,
                color: Colors.orange,
                onTap: () => _navigateToReports(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPersonalSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal'),
        Row(
          children: [
            Expanded(
              child: _buildFunctionCard(
                title: 'Profile',
                icon: Icons.person_outline,
                color: Colors.indigo,
                onTap: () {
                  final userData = AuthService.instance.currentUser;
                  if (userData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userData: userData),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFunctionCard(
                title: 'Settings',
                icon: Icons.settings_outlined,
                color: Colors.grey,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunctionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReports(BuildContext context) {
    final userId = AuthService.instance.currentUser?['id'];
    print('\n=== NAVIGATING TO REPORTS ===');
    print('Current user: ${AuthService.instance.currentUser}');
    print('User ID: $userId');

    if (userId == null) {
      print('Warning: User ID is null!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not determine user ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsPage(patientId: userId),
      ),
    );
  }
}
