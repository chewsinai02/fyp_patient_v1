import 'package:flutter/material.dart';
import 'nurse_calling_page.dart';
import 'family_status_page.dart';
import 'appointment_page.dart';
import 'function_page.dart';
import 'pages/daily_tasks_page.dart';
import 'services/database_service.dart';
import 'pages/messages_page.dart';
import 'pages/settings_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DashboardPage({super.key, required this.userData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: DashboardContent(userData: widget.userData),
    );
  }
}

// Extract the current dashboard content into a separate widget
class DashboardContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  const DashboardContent({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar with reduced height
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top section - Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                _buildNotificationBadge(),
                                const SizedBox(width: 8),
                                IconButton(
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SettingsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bottom section - Profile info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white,
                                backgroundImage: userData[
                                            'assets/' 'profile_picture'] !=
                                        null
                                    ? NetworkImage(
                                        userData['assets/' 'profile_picture'])
                                    : const AssetImage(
                                            'assets/images/profile.png')
                                        as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  userData['name'] ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Progress Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: DatabaseService.instance
                    .getTasksProgress(int.parse(userData['id'].toString())),
                builder: (context, snapshot) {
                  print('FutureBuilder state:');
                  print('Has data: ${snapshot.hasData}');
                  print('Has error: ${snapshot.hasError}');
                  if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                  }

                  double progress = 0.0;
                  int total = 0;
                  int completed = 0;
                  int pending = 0;
                  int passed = 0;

                  if (snapshot.hasData) {
                    progress = snapshot.data!['progress'];
                    total = snapshot.data!['total'];
                    completed = snapshot.data!['completed'];
                    pending = snapshot.data!['pending'];
                    passed = snapshot.data!['passed'];
                    print('Dashboard received data:');
                    print('Progress: $progress');
                    print('Total: $total');
                    print('Completed: $completed');
                    print('Pending: $pending');
                    print('Passed: $passed');
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyTasksPage(
                            patientId: int.parse(userData['id'].toString()),
                            patientName: userData['name'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Today\'s Tasks',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.deepPurple),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Completed $completed of $total tasks',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Quick Actions Grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.medical_services_outlined,
                  title: 'Nurse Call',
                  description: 'Request immediate assistance',
                  color: Colors.red.shade100,
                  iconColor: Colors.red,
                  onTap: () async {
                    try {
                      // Fetch user data based on patient ID
                      final userId = int.parse(userData['id'].toString());
                      final patientData =
                          await DatabaseService.instance.getUserById(userId);

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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NurseCallingPage(
                              patientId: userId,
                              patientName: patientData['patient_name'],
                              roomNumber: patientData['room_number'] is String
                                  ? int.parse(patientData['room_number'])
                                  : patientData['room_number'],
                              bedNumber: patientData['bed_number'] is String
                                  ? int.parse(patientData['bed_number'])
                                  : patientData['bed_number'],
                              bedId: patientData['bed_id'] != null
                                  ? (patientData['bed_id'] is String
                                      ? int.parse(patientData['bed_id'])
                                      : patientData['bed_id'])
                                  : patientData['bed_number'],
                              roomId: patientData['room_id'] is String
                                  ? int.parse(patientData['room_id'])
                                  : patientData['room_id'],
                              floor: patientData['floor'] is String
                                  ? int.parse(patientData['floor'])
                                  : patientData['floor'],
                              assignedNurseId: nurseData['nurse_id'],
                              currentShift: currentShift,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error navigating to nurse call: $e');
                      // Handle error appropriately
                    }
                  },
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.family_restroom,
                  title: 'Family Status',
                  description: 'View family members\' status',
                  color: Colors.blue.shade100,
                  iconColor: Colors.blue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FamilyStatusPage(),
                    ),
                  ),
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Appointments',
                  description: 'Schedule your visits',
                  color: Colors.green.shade100,
                  iconColor: Colors.green,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AppointmentPage(),
                    ),
                  ),
                ),
                _buildQuickActionCard(
                  context: context,
                  icon: Icons.more_horiz,
                  title: 'More',
                  description: 'Additional services',
                  color: Colors.orange.shade100,
                  iconColor: Colors.orange,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FunctionPage(),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return FutureBuilder<int>(
      future: DatabaseService.instance.getUnreadMessageCount(userData['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data! > 0) {
          return Stack(
            children: [
              IconButton(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesPage(
                        patientId: int.parse(userData['id'].toString()),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    snapshot.data! > 99 ? '99+' : snapshot.data!.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return IconButton(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagesPage(
                  patientId: int.parse(userData['id'].toString()),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
