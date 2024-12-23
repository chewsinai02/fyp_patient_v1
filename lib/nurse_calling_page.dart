import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class NurseCallingPage extends StatefulWidget {
  const NurseCallingPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.roomNumber,
    required this.bedNumber,
    required this.roomId,
    required this.floor,
    required this.assignedNurseId,
    required this.currentShift,
  });

  final int patientId;
  final String patientName;
  final int roomNumber;
  final int bedNumber;
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

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
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
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }

      // Show loading indicator
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
        final callId = callRef.key;
        _activeCallId = callId;

        // Create emergency call data
        final callData = {
          'patient_id': widget.patientId,
          'assigned_nurse_id': widget.assignedNurseId,
          'attended_at': null,
          'attended_by': null,
          'bed_number': widget.bedNumber,
          'room_id': widget.roomId,
          'floor': widget.floor,
          'current_shift': widget.currentShift,
          'call_status': true,
          'locations': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'updated_at': ServerValue.timestamp,
          },
          'patient_name': widget.patientName,
          'room_number': widget.roomNumber,
          'timestamp': ServerValue.timestamp,
        };

        // Push data to 'nurse_calls' node
        await callRef.set(callData);

        // Hide loading indicator
        if (context.mounted) {
          Navigator.pop(context); // Remove loading indicator
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
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 16),
          const Text(
            'Emergency Call',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

          // Update call_status to false for this patient's active calls
          if (snapshot.exists) {
            final calls = snapshot.value as Map;
            for (var callKey in calls.keys) {
              final call = calls[callKey] as Map;
              if (call['patient_id'] == widget.patientId &&
                  call['call_status'] == true) {
                await _databaseRef
                    .child('nurse_calls')
                    .child(callKey)
                    .update({'call_status': false});
              }
            }
          }

          if (context.mounted) {
            Navigator.pop(context);
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
}
