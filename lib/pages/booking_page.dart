import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class BookingPage extends StatefulWidget {
  final String doctorName;
  final int doctorId;

  const BookingPage({
    super.key,
    required this.doctorName,
    required this.doctorId,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final DatabaseService _db = DatabaseService.instance;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _notes;
  Map<DateTime, List<String>> _availableSlots = {};

  // Mapping of database times to display times (reverse of the original map)
  final Map<String, String> _dbToDisplayTime = {
    '09:00:00': '9:00 AM',
    '09:30:00': '9:30 AM',
    '10:00:00': '10:00 AM',
    '10:30:00': '10:30 AM',
    '11:00:00': '11:00 AM',
    '11:30:00': '11:30 AM',
    '14:00:00': '2:00 PM',
    '14:30:00': '2:30 PM',
    '15:00:00': '3:00 PM',
    '15:30:00': '3:30 PM',
    '16:00:00': '4:00 PM',
    '16:30:00': '4:30 PM',
  };

  // Add this method to fetch available slots
  Future<void> _fetchAvailableSlots(DateTime date) async {
    final slots = await _db.getAvailableTimeSlots(widget.doctorId, date);
    setState(() {
      _availableSlots[date] = slots;
      // Clear selected time if it's no longer available
      if (_selectedTime != null && !slots.contains(_selectedTime)) {
        _selectedTime = null;
      }
    });
  }

  // Update the TableCalendar's calendarBuilders
  CalendarBuilders get _calendarBuilders => CalendarBuilders(
        defaultBuilder: (context, date, events) {
          // Disable Sundays and dates with no available slots
          if (date.weekday == DateTime.sunday ||
              (_availableSlots.containsKey(date) &&
                  _availableSlots[date]!.isEmpty)) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return null;
        },
      );

  // Update the onDaySelected callback
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (selectedDay.weekday != DateTime.sunday) {
      if (!_availableSlots.containsKey(selectedDay)) {
        await _fetchAvailableSlots(selectedDay);
      }

      if (_availableSlots[selectedDay]?.isNotEmpty ?? false) {
        setState(() {
          _selectedDate = selectedDay;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available slots for this date'),
          ),
        );
      }
    }
  }

  // Replace the DropdownButton with this updated version
  Widget _buildTimeDropdown() {
    if (_selectedDate == null) {
      return const Text('Please select a date first');
    }

    final availableSlots = _availableSlots[_selectedDate] ?? [];
    if (availableSlots.isEmpty) {
      return const Text('No available slots for selected date');
    }

    return DropdownButton<String>(
      hint: const Text('Select Appointment Time'),
      value: _selectedTime,
      onChanged: (String? newValue) {
        setState(() {
          _selectedTime = newValue;
        });
      },
      items: availableSlots.map<DropdownMenuItem<String>>((String dbTime) {
        return DropdownMenuItem<String>(
          value: dbTime,
          child: Text(_dbToDisplayTime[dbTime] ?? dbTime),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Information Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking for Dr. ${widget.doctorName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please select appointment time and below:',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Calendar for Date Selection
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime(2100),
                focusedDay: _selectedDate ?? DateTime.now(),
                onDaySelected: _onDaySelected,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  disabledDecoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                // Disable Sundays
                calendarBuilders: _calendarBuilders,
              ),
              const SizedBox(height: 20),

              // Appointment Time Selection
              _buildTimeDropdown(),
              const SizedBox(height: 20),

              // Notes Input
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                ),
                onChanged: (value) {
                  _notes = value;
                },
              ),
              const SizedBox(height: 20),

              // Confirm Booking Button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedDate != null && _selectedTime != null) {
                      final int? patientId =
                          await AuthService.instance.getCurrentUserId();
                      if (patientId != null) {
                        try {
                          await _db.addAppointment(
                            patientId: patientId,
                            doctorId: widget.doctorId,
                            appointmentDate: _selectedDate!,
                            appointmentTime: _selectedTime!,
                            notes: _notes,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment booked successfully!'),
                            ),
                          );

                          Navigator.pop(context);
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Error booking appointment: $error'),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please login to book an appointment'),
                          ),
                        );
                        Navigator.pushNamed(context, '/login');
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select date and time'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
