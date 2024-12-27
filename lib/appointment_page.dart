import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'package:intl/intl.dart';
import 'pages/doctors_page.dart'; // Adjust the path as necessary

class AppointmentPage extends StatefulWidget {
  final bool isFromMainLayout;

  const AppointmentPage({
    super.key,
    this.isFromMainLayout = false,
  });

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final userId = await AuthService.instance.getCurrentUserId();
      if (userId != null) {
        final appointments =
            await DatabaseService.instance.getAppointments(userId);
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isFromMainLayout
        ? _buildContent()
        : Scaffold(
            body: _buildContent(),
          );
  }

  Widget _buildContent() {
    return CustomScrollView(
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
                      if (!widget.isFromMainLayout)
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
                          'Appointments',
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
                    'Schedule and manage your appointments',
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
        SliverToBoxAdapter(
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              _buildUpcomingAppointments(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_appointments.isEmpty)
          const Center(
            child: Text('No upcoming appointments'),
          )
        else
          ..._appointments.map((appointment) => _buildAppointmentCard(
                doctorName: appointment['doctor_name'],
                specialty: appointment['notes'] is String
                    ? appointment['notes']
                    : appointment['notes'].toString(),
                date: _formatDateTime(
                  appointment['appointment_date'],
                  appointment['appointment_time'],
                ),
                isUpcoming: true,
                doctorId: appointment['doctor_id'],
              )),
      ],
    );
  }

  Widget _buildAppointmentCard({
    required String doctorName,
    required String specialty,
    required String date,
    required bool isUpcoming,
    required dynamic doctorId,
  }) {
    final appointment = _appointments.firstWhere(
      (a) => a['doctor_id'] == doctorId,
      orElse: () => {},
    );

    final profilePicture = 'assets${appointment['profile_picture']}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                profilePicture,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  print('Attempted path: $profilePicture');
                  return const Icon(
                    Icons.person,
                    color: Colors.deepPurple,
                    size: 30,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  specialty,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.3),
        ),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDateTime(dynamic date, dynamic time) {
    // Convert date and time to String if they are not already
    String dateString = date is String ? date : date.toString();
    String timeString = time is String ? time : time.toString();

    // Parse the date and time
    DateTime parsedDate =
        DateTime.parse(dateString); // Assuming date is in 'yyyy-mm-dd' format
    String formattedTime = DateFormat.jm().format(
        DateFormat.Hm().parse(timeString)); // Format time to 'hh:mm am/pm'

    // Return formatted date and time
    return '${parsedDate.toIso8601String().split('T')[0]}, $formattedTime'; // Format date to 'yyyy-mm-dd'
  }
}
