import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/database_service.dart';
import '../utils/time_utils.dart';

class NurseCallingPage extends StatefulWidget {
  const NurseCallingPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.roomNumber,
    required this.bedNumber,
    required this.bedId,
    required this.roomId,
    required this.floor,
    required this.assignedNurseId,
    required this.currentShift,
  });

  final int patientId;
  final String patientName;
  final int roomNumber;
  final int bedNumber;
  final int bedId;
  final int roomId;
  final int floor;
  final int? assignedNurseId;
  final String? currentShift;

  @override
  State<NurseCallingPage> createState() => _NurseCallingPageState();
}

class _NurseCallingPageState extends State<NurseCallingPage> {
  Timer? _locationTimer;
  String? _activeCallId;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  StreamSubscription? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    _listenToCallStatus();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _callStatusSubscription?.cancel();
    super.dispose();
  }

  void _listenToCallStatus() {
    _callStatusSubscription =
        _databaseRef.child('nurse_calls').onChildChanged.listen((event) async {
      if (!mounted) return;

      final callData = event.snapshot.value as Map?;
      if (callData == null) return;

      if (callData['patient_id'] == widget.patientId &&
          callData['call_status'] == false &&
          callData['attended_by'] != null) {
        if (context.mounted) {
          _locationTimer?.cancel();
          _locationTimer = null;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Nurse Has Arrived'),
              content: const Text(
                  'Your responsible nurse has attended to your call.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  Future<void> _updateLocation() async {
    if (_activeCallId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _databaseRef
          .child('nurse_calls')
          .child(_activeCallId!)
          .child('locations')
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _handleEmergencyCall(BuildContext context) async {
    try {
      print('\n=== EMERGENCY CALL VALIDATION ===');
      print('Patient ID: ${widget.patientId}');
      print('Room ID: ${widget.roomId}');
      print('Room Number: ${widget.roomNumber}');
      print('Floor: ${widget.floor}');
      print('Assigned Nurse ID: ${widget.assignedNurseId}');
      print('Current Shift: ${widget.currentShift}');

      // First check room info
      final conn = await DatabaseService.instance.connection;
      final roomQuery = '''
        SELECT room_number, floor 
        FROM rooms 
        WHERE id = ?
      ''';

      final roomInfo = await conn.query(roomQuery, [widget.roomId]);
      print('\n=== ROOM INFO ===');
      print('Room query result: ${roomInfo.first.fields}');

      // Fix type casting
      final correctRoomNumber =
          int.parse(roomInfo.first['room_number'].toString());
      final correctFloor = int.parse(roomInfo.first['floor'].toString());

      print('Parsed room info:');
      print('Room Number: $correctRoomNumber');
      print('Floor: $correctFloor');

      // Then check nurse schedule with correct column names
      final nurseAssignmentQuery = '''
        SELECT 
          ns.*,
          u.name as nurse_name,
          r.room_number,
          r.floor
        FROM nurse_schedules ns
        JOIN users u ON ns.nurse_id = u.id
        JOIN rooms r ON ns.room_id = r.id
        WHERE ns.room_id = ?
          AND ns.shift = ?
          AND DATE(CONVERT_TZ(NOW(), '+00:00', '+08:00')) = DATE(ns.date)
          AND (
            (ns.shift = 'morning' AND HOUR(CONVERT_TZ(NOW(), '+00:00', '+08:00')) >= 7 AND HOUR(CONVERT_TZ(NOW(), '+00:00', '+08:00')) < 15) OR
            (ns.shift = 'afternoon' AND HOUR(CONVERT_TZ(NOW(), '+00:00', '+08:00')) >= 16 AND HOUR(CONVERT_TZ(NOW(), '+00:00', '+08:00')) < 23) OR
            (ns.shift = 'night' AND (HOUR(CONVERT_TZ(NOW(), '+00:00', '+08:00')) >= 23 OR HOUR(CONVERT_TZ(NOW(), '+00:00', '+08:00')) < 7))
          )
        LIMIT 1
      ''';

      // Add debug logging
      print('\n=== CHECKING NURSE ASSIGNMENT ===');
      print('Room ID: ${widget.roomId}');
      print('Current Shift: ${getCurrentShift()}');
      print('Current Time: ${TimeUtils.getLocalTime()}');

      final assignments = await conn
          .query(nurseAssignmentQuery, [widget.roomId, getCurrentShift()]);

      if (assignments.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No nurse is currently assigned to this room for the current shift'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final assignment = assignments.first;
      final nurseId = assignment['nurse_id'];
      final nurseName = assignment['nurse_name'];

      print('Found nurse assignment:');
      print('Nurse ID: $nurseId');
      print('Nurse Name: $nurseName');
      print('Shift: ${assignment['shift']}');

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }

      // Show loading indicator
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Get new call ID
        final callRef = _databaseRef.child('nurse_calls').push();
        final callId = 'call_${callRef.key}';
        _activeCallId = callId;

        // Create emergency call data
        final callData = {
          'patient_id': widget.patientId,
          'assigned_nurse_id': nurseId,
          'attended_at': null,
          'attended_by': null,
          'bed_id': widget.bedId,
          'bed_number': widget.bedNumber,
          'room_id': widget.roomId,
          'floor': correctFloor,
          'current_shift': getCurrentShift(),
          'call_status': true,
          'locations': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'updated_at': ServerValue.timestamp,
          },
          'patient_name': widget.patientName,
          'room_number': correctRoomNumber,
          'timestamp': ServerValue.timestamp,
        };

        await _databaseRef.child('nurse_calls').child(callId).set(callData);

        if (context.mounted) {
          Navigator.pop(context); // Remove loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency call sent to nurse: $nurseName'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Start location updates
        _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          _updateLocation();
        });
      } catch (e) {
        print('Database error: $e');
        if (context.mounted) {
          Navigator.pop(context); // Remove loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send nurse call: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in emergency call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEmergencyButton(context),
                  const SizedBox(height: 40),
                  _buildCancelButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
                    'Emergency Call',
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
              'Press the button below to call a nurse for emergency assistance.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleEmergencyCall(context),
      child: Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade50,
          border: Border.all(
            color: Colors.red,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emergency,
              size: 64,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              'Call Nurse',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        try {
          // Cancel location updates
          _locationTimer?.cancel();
          _locationTimer = null;

          // Get all nurse calls
          final snapshot = await _databaseRef.child('nurse_calls').get();

          if (snapshot.exists) {
            final calls = snapshot.value as Map;
            for (var callKey in calls.keys) {
              final call = calls[callKey] as Map;
              if (call['patient_id'] == widget.patientId &&
                  call['call_status'] == true) {
                // Check if nurse already attended
                if (call['attended_by'] != null) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Nurse Already Attending'),
                        content: const Text(
                            'A nurse is already on their way to assist you.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                // If not attended, allow cancellation
                await _databaseRef
                    .child('nurse_calls')
                    .child(callKey)
                    .update({'call_status': false});

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error canceling nurse call: $e');
        }
      },
      child: const Text(
        'Cancel',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 18,
        ),
      ),
    );
  }

  String getCurrentShift() {
    final now = TimeUtils.getLocalTime(); // Gets KL time
    final hour = now.hour;

    if (hour >= 7 && hour < 15) return 'morning'; // 7 AM - 3 PM
    if (hour >= 16 && hour < 23) return 'afternoon'; // 4 PM - 11 PM
    return 'night'; // 11 PM - 7 AM
  }
}
