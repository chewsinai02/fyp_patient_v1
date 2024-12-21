import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../pages/booking_page.dart';
import '../services/auth_service.dart';
import '../login.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final DatabaseService _db = DatabaseService.instance;
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    print(
        'DoctorsPage initialized - Current user: ${AuthService.instance.getCurrentUserId()}');
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _db.getDoctors();
      print('Doctors loaded: ${doctors.length}'); // Debugging print statement
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _doctors[index];
                        return _buildDoctorCard(
                          name: doctor['name'],
                          specialty: doctor['specialty'] ?? 'N/A',
                          experience: doctor['experience'] ?? 'N/A',
                          rating: doctor['rating']?.toDouble() ?? 0.0,
                          doctorId: doctor['id'],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              const Text(
                'Our Doctors',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Meet our experienced doctors and book your appointments!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String experience,
    required double rating,
    required int doctorId,
  }) {
    // Find the doctor data to get the profile picture
    final doctor = _doctors.firstWhere(
      (d) => d['id'] == doctorId,
      orElse: () => {},
    );

    final profilePicture = 'assets${doctor['profile_picture']}';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                profilePicture,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  print('Attempted path: $profilePicture');
                  return const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.deepPurple,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  specialty,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[700],
                      size: 16,
                    ),
                    Text(
                      ' $rating',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      experience,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Available',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  print('Book button pressed'); // Debug print
                  final currentUser = AuthService.instance.getCurrentUserId();
                  print(
                      'Current user when booking: $currentUser'); // Debug print

                  if (currentUser != null) {
                    print('User is logged in, proceeding to booking');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingPage(
                          doctorName: name,
                          doctorId: doctorId,
                        ),
                      ),
                    );
                  } else {
                    print('No user found in AuthService when trying to book');
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Login Required'),
                        content:
                            const Text('Please login to book an appointment.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to login page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              ).then((_) {
                                // Check login state after returning from login page
                                final user =
                                    AuthService.instance.getCurrentUserId();
                                print(
                                    'Returned from login page, current user: $user');
                              });
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Book',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
