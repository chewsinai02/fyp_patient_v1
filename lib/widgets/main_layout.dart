import 'package:flutter/material.dart';
import '../dashboard.dart';
import '../appointment_page.dart';
import '../pages/profile_page.dart';
import '../services/auth_service.dart';
import '../pages/messages_page.dart';
import '../pages/doctors_page.dart';
import '../services/database_service.dart';
import 'dart:async';

class MainLayout extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MainLayout({super.key, required this.userData});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  Timer? _taskCheckTimer;

  @override
  void initState() {
    super.initState();
    _pages = [
      Dashboard(userData: widget.userData),
      MessagesPage(
        patientId: widget.userData['id'] ?? 0,
        isFromMainLayout: true,
      ),
      AppointmentPage(isFromMainLayout: true),
      ProfilePage(
        userData: widget.userData,
        isFromMainLayout: true,
      ),
    ];
    AuthService.instance.setCurrentUser(widget.userData);

    // Start checking for new messages
    final userId = widget.userData['id'] as int;
    DatabaseService.instance.startMessageChecking(userId);

    _startTaskChecking();
  }

  @override
  void dispose() {
    // Stop checking for messages when widget is disposed
    DatabaseService.instance.stopMessageChecking();
    _taskCheckTimer?.cancel();
    super.dispose();
  }

  void _startTaskChecking() {
    print('Starting task check service...');

    // Check every 30 seconds for upcoming tasks
    _taskCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final userId = widget.userData['id'] as int;
      print('\nPeriodic task check triggered for user: $userId');
      DatabaseService.instance.checkUpcomingTasks(userId);
    });

    // Also check immediately
    final userId = widget.userData['id'] as int;
    print('Initial task check for user: $userId');
    DatabaseService.instance.checkUpcomingTasks(userId);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: _pages[_selectedIndex],
        floatingActionButton: _selectedIndex == 2
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DoctorsPage()),
                  );
                },
                backgroundColor: Colors.deepPurple,
                label: const Text('+', style: TextStyle(color: Colors.white)),
              )
            : null,
        bottomNavigationBar: Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.chat_bubble_rounded, 'Chat', 1),
              _buildNavItem(Icons.calendar_month_rounded, 'Appointments', 2),
              _buildNavItem(Icons.person_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
