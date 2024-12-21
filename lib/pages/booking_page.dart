import 'package:flutter/material.dart';
import '../services/database_service.dart';

class BookingPage extends StatefulWidget {
  final String doctorName;
  final int doctorId; // Pass doctor ID

  const BookingPage(
      {super.key, required this.doctorName, required this.doctorId});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final DatabaseService _db = DatabaseService.instance;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _notes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking for Dr. ${widget.doctorName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: Text(
                _selectedDate == null
                    ? 'Select Appointment Date'
                    : 'Selected Date: ${_selectedDate!.toLocal()}'
                        .split(' ')[0],
              ),
            ),
            TextButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              child: Text(
                _selectedTime == null
                    ? 'Select Appointment Time'
                    : 'Selected Time: ${_selectedTime!.format(context)}',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              onChanged: (value) {
                _notes = value;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedDate != null && _selectedTime != null) {
                  _db
                      .addAppointment(
                    patientId: 1, // Replace with actual patient ID
                    doctorId: widget.doctorId,
                    appointmentDate: _selectedDate!,
                    appointmentTime: _selectedTime!,
                    notes: _notes,
                  )
                      .then((_) {
                    Navigator.pop(context); // Go back after booking
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                  });
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select date and time')),
                  );
                }
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
