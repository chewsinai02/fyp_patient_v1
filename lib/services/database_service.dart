import 'package:mysql1/mysql1.dart' as mysql;
import 'package:dotenv/dotenv.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bcrypt/bcrypt.dart';

class DatabaseService {
  static DatabaseService? _instance;
  mysql.MySqlConnection? _conn;
  bool _isConnecting = false;
  static const int _maxConnections = 5;
  static int _currentConnections = 0;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<mysql.MySqlConnection> get connection async {
    if (_conn != null) {
      return _conn!;
    }

    if (_isConnecting) {
      await Future.delayed(Duration(seconds: 1));
      return connection;
    }

    if (_currentConnections >= _maxConnections) {
      await close(); // Close existing connections
      _currentConnections = 0;
    }

    try {
      _isConnecting = true;
      _currentConnections++;

      final settings = mysql.ConnectionSettings(
        host: 'mydb.cdsagqe648ba.ap-southeast-2.rds.amazonaws.com',
        port: 3306,
        user: 'admin',
        password: 'admin1234',
        db: 'mydb1',
        timeout: Duration(seconds: 30),
      );

      _conn = await mysql.MySqlConnection.connect(settings);
      return _conn!;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> close() async {
    if (_conn != null) {
      await _conn!.close();
      _conn = null;
      _currentConnections--;
    }
  }

  // Update authentication method to handle bcrypt passwords
  Future<Map<String, dynamic>?> authenticateUser(
      String email, String password) async {
    try {
      print('=== AUTHENTICATION START ===');
      print('Attempting login with email: $email');
      final conn = await connection;

      final results =
          await conn.query('SELECT * FROM users WHERE email = ?', [email]);

      if (results.isEmpty) {
        print('No user found with email: $email');
        return null;
      }

      final user = results.first;
      final hashedPassword = user['password'] as String;

      print('Stored password from DB: $hashedPassword');
      print('Input password: $password');

      try {
        // Remove the $2y prefix and replace with $2a for Dart's bcrypt
        final normalizedHash = hashedPassword.replaceFirst('\$2y', '\$2a');
        final isValid = BCrypt.checkpw(password, normalizedHash);

        if (!isValid) {
          print('Password verification failed');
          return null;
        }

        print('Password verified successfully');
        return {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'gender': user['gender'],
          'address': user['address'],
          'phone': user['contact_number'],
          'profile_picture': user['profile_picture'],
        };
      } catch (e) {
        print('Error verifying password with bcrypt: $e');
        return null;
      }
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  //dashboard count task
  Future<Map<String, dynamic>> getTasksProgress(int patientId) async {
    try {
      final conn = await connection;
      print('Getting tasks progress for patient ID: $patientId');

      // Get today's date in the correct format
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get pending tasks count for today
      final pendingResult = await conn.query('''
        SELECT COUNT(*) as pending 
        FROM tasks 
        WHERE patient_id = ? 
        AND DATE(due_date) = ?
        AND status = 'pending'
        AND deleted_at IS NULL
        ''', [patientId, today]);

      // Get completed tasks count for today
      final completedResult = await conn.query('''
        SELECT COUNT(*) as completed 
        FROM tasks 
        WHERE patient_id = ? 
        AND DATE(due_date) = ?
        AND status = 'completed'
        AND deleted_at IS NULL
        ''', [patientId, today]);

      // Get passed tasks count for today
      final passedResult = await conn.query('''
        SELECT COUNT(*) as passed 
        FROM tasks 
        WHERE patient_id = ? 
        AND DATE(due_date) = ?
        AND status = 'passed'
        AND deleted_at IS NULL
        ''', [patientId, today]);

      print('Query results:');
      print('Pending tasks: ${pendingResult.first['pending']}');
      print('Completed tasks: ${completedResult.first['completed']}');
      print('Passed tasks: ${passedResult.first['passed']}');

      final pending = pendingResult.first['pending'] as int;
      final completed = completedResult.first['completed'] as int;
      final passed = passedResult.first['passed'] as int;

      final total = pending + completed + passed;

      print('Calculated progress:');
      print('Pending tasks: $pending');
      print('Completed tasks: $completed');
      print('Passed tasks: $passed');
      print('Total tasks: $total');

      // Calculate progress as a ratio of completed tasks to total tasks
      final progress = total > 0 ? completed / total : 0.0;
      print('Progress ratio: $progress');

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'passed': passed,
        'progress': progress,
      };
    } catch (e, stackTrace) {
      print('Error getting tasks progress:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'passed': 0,
        'progress': 0.0,
      };
    }
  }

  //calendar page
  Future<List<Map<String, dynamic>>> getTasksByDate(
    int patientId, {
    DateTime? selectedDate,
  }) async {
    try {
      final conn = await connection;
      print('=== FETCHING TASKS START ===');
      print('Patient ID: $patientId');

      // Use selected date or default to today
      final date = selectedDate ?? DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Simplified query to get tasks for the specific date
      const query = '''
        SELECT 
          id, 
          title, 
          description, 
          status, 
          priority,
          due_date,
          room_id
        FROM tasks 
        WHERE patient_id = ? 
        AND DATE(due_date) = ?
        AND deleted_at IS NULL
        ORDER BY TIME(due_date) ASC
      ''';

      print('Executing Query with parameters:');
      print('Patient ID: $patientId');
      print('Selected Date: $formattedDate');

      final results = await conn.query(query, [patientId, formattedDate]);

      print('Raw Results Count: ${results.length}');

      List<Map<String, dynamic>> tasks = [];

      for (var row in results) {
        DateTime? dueDate;
        if (row['due_date'] != null) {
          if (row['due_date'] is DateTime) {
            dueDate = row['due_date'];
          } else {
            try {
              dueDate = DateTime.parse(row['due_date'].toString());
            } catch (e) {
              print('Error parsing due_date: ${row['due_date']}');
              print('Error: $e');
            }
          }
        }

        String convertToString(dynamic value) {
          if (value == null) return '';
          if (value is mysql.Blob) {
            return String.fromCharCodes(value.toBytes());
          }
          return value.toString();
        }

        final task = {
          'id': row['id'],
          'room_id': row['room_id'],
          'title': convertToString(row['title']),
          'description': row['description'] != null
              ? convertToString(row['description'])
              : null,
          'status': convertToString(row['status']),
          'priority': convertToString(row['priority']),
          'due_date': dueDate,
        };

        print('Processed Task: $task');
        tasks.add(task);
      }

      print('Total Tasks Found: ${tasks.length}');
      print('=== FETCHING TASKS END ===');
      return tasks;
    } catch (e, stackTrace) {
      print('=== ERROR FETCHING TASKS ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Example method to fetch doctors
  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final conn = await connection;
      print('Fetching doctors');

      const query = '''
        SELECT 
          id,
          name,
          description,
          staff_id as experience,
          CAST(5.0 AS DECIMAL(3,1)) as rating,
          profile_picture
        FROM users 
        WHERE LOWER(role) = 'doctor'
      ''';

      final results = await conn.query(query);
      List<Map<String, dynamic>> doctors = [];

      for (var row in results) {
        // Convert Blob to String if necessary
        String? description = row['description'] != null
            ? (row['description'] is mysql.Blob
                ? String.fromCharCodes(
                    (row['description'] as mysql.Blob).toBytes())
                : row['description'].toString())
            : null;

        // Process profile picture URL
        String? profilePicture = row['profile_picture'] != null
            ? (row['profile_picture'] is mysql.Blob
                ? String.fromCharCodes(
                    (row['profile_picture'] as mysql.Blob).toBytes())
                : row['profile_picture'].toString())
            : null;

        // Only add 'assets/' prefix if it's not a Firebase URL or existing asset path
        if (profilePicture != null &&
            !profilePicture.startsWith('http') &&
            !profilePicture.startsWith('assets/') &&
            !profilePicture
                .startsWith('https://firebasestorage.googleapis.com')) {
          profilePicture = 'assets/$profilePicture';
        }

        doctors.add({
          'id': row['id'],
          'name': row['name'].toString(),
          'specialty': description ?? 'General Practice',
          'experience': row['experience']?.toString() ?? 'N/A',
          'rating': row['rating'] ?? 5.0,
          'profile_picture': profilePicture,
        });
      }

      return doctors;
    } catch (e) {
      print('Error fetching doctors: $e');
      return [];
    }
  }

  // Example method to add a doctor
  Future<void> addDoctor({
    required String name,
    required String specialty,
    required String experience,
    required double rating,
  }) async {
    final conn = await connection;
    await conn.query(
      'INSERT INTO doctors (name, specialty, experience, rating) VALUES (?, ?, ?, ?)',
      [name, specialty, experience, rating],
    );
  }

  //booking page
  Future<void> addAppointment({
    required int patientId,
    required int doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    try {
      final conn = await connection;
      const query = '''
        INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status, notes)
        VALUES (?, ?, ?, ?, 'active', ?)
      ''';

      // Log the values being inserted
      print('Inserting appointment for Patient ID: $patientId');
      print('Doctor ID: $doctorId');
      print(
          'Appointment Date: ${appointmentDate.toIso8601String().split('T')[0]}');
      print('Appointment Time: $appointmentTime');
      print('Notes: $notes');

      await conn.query(query, [
        patientId,
        doctorId,
        appointmentDate.toIso8601String().split('T')[0],
        appointmentTime,
        notes,
      ]);

      print('Appointment added successfully.');
    } catch (e) {
      print('Error adding appointment: $e');
      rethrow;
    }
  }

  // Add this new method
  Future<List<String>> getAvailableTimeSlots(
      int doctorId, DateTime date) async {
    try {
      final conn = await connection;

      // Format the date to match MySQL date format
      final formattedDate = date.toIso8601String().split('T')[0];

      // Get all booked appointments for the specified doctor and date
      const query = '''
        SELECT TIME_FORMAT(appointment_time, '%H:%i:%s') as appointment_time 
        FROM appointments 
        WHERE doctor_id = ? 
        AND DATE(appointment_date) = ?
        AND status = 'active'
      ''';

      print('Checking appointments for:');
      print('Doctor ID: $doctorId');
      print('Date: $formattedDate');

      final results = await conn.query(query, [doctorId, formattedDate]);

      // Convert results to a list of booked times
      List<String> bookedTimes =
          results.map((row) => row['appointment_time'].toString()).toList();

      print('=== AVAILABLE TIME SLOTS ===');
      print('Checking date: $formattedDate');
      print('Doctor ID: $doctorId');
      print('Already booked times: $bookedTimes');

      // Define all possible time slots
      final allTimeSlots = [
        '09:00:00',
        '09:30:00',
        '10:00:00',
        '10:30:00',
        '11:00:00',
        '11:30:00',
        '14:00:00',
        '14:30:00',
        '15:00:00',
        '15:30:00',
        '16:00:00',
        '16:30:00'
      ];

      // Get available slots by filtering out booked times
      final availableSlots = allTimeSlots
          .where((timeSlot) => !bookedTimes.any((bookedTime) {
                return timeSlot.trim() == bookedTime.trim();
              }))
          .toList();

      print('Available slots for $formattedDate: $availableSlots');
      print('=========================');

      return availableSlots;
    } catch (e) {
      print('Error getting available time slots: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  //chat page
  Future<List<Message>> getMessages(int patientId) async {
    try {
      final conn = await connection;
      print('Fetching messages for patient ID: $patientId');

      final results = await conn.query('''
        SELECT 
          m.*,
          u_sender.name as sender_name,
          u_sender.profile_picture as sender_profile_picture,
          u_receiver.name as receiver_name,
          u_receiver.profile_picture as receiver_profile_picture
        FROM messages m
        JOIN users u_sender ON m.sender_id = u_sender.id
        JOIN users u_receiver ON m.receiver_id = u_receiver.id
        WHERE m.sender_id = ? OR m.receiver_id = ?
        ORDER BY m.created_at DESC
      ''', [patientId, patientId]);

      print('Query executed. Raw results: ${results.length}');
      if (results.isEmpty) {
        print('No messages found for patient ID: $patientId');
      } else {
        for (var row in results) {
          print('Message ID: ${row['id']}');
          print('Sender ID: ${row['sender_id']}');
          print('Receiver ID: ${row['receiver_id']}');
          print('Message: ${row['message']}');
          print('-------------------');
        }
      }

      final messages = results
          .map((row) => Message.fromMap({
                ...row.fields,
                'sender_name': row['sender_name'],
                'sender_profile_picture': row['sender_profile_picture'],
                'receiver_name': row['receiver_name'],
                'receiver_profile_picture': row['receiver_profile_picture'],
              }))
          .toList();

      print('Converted to ${messages.length} Message objects');
      return messages;
    } catch (e, stackTrace) {
      print('Error fetching messages: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  //check unread messages
  Future<int> checkUnreadMessages(int patientId) async {
    final conn = await connection;
    final result = await conn.query(
        'SELECT COUNT(*) FROM messages WHERE receiver_id = ? AND is_read = 1',
        [patientId]);
    return result.first['COUNT(*)'] as int;
  }

  //mark message as read
  Future<void> markMessageAsRead(int senderId, int receiverId) async {
    try {
      final conn = await connection;
      print('Marking messages as read - From: $senderId, To: $receiverId');

      // Update only unread messages (is_read = 1) where:
      // 1. The current user is the receiver
      // 2. The message is from the specific sender
      final result = await conn.query('''
        UPDATE messages 
        SET is_read = 0,
            updated_at = NOW() 
        WHERE sender_id = ?  -- Specific sender's ID
          AND receiver_id = ?  -- Current user's ID (receiver)
          AND is_read = 1  -- Only update unread messages
      ''', [senderId, receiverId]);

      print('Messages marked as read. Rows affected: ${result.affectedRows}');
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Add this method to DatabaseService class
  Future<List<Map<String, dynamic>>> getAppointments(int patientId) async {
    try {
      final conn = await connection;
      print('Fetching appointments for patient ID: $patientId');

      // First, get the doctor's profile picture
      const doctorQuery = '''
        SELECT 
          d.id as doctor_id,
          d.profile_picture
        FROM users d
        WHERE d.role = 'doctor'
      ''';

      final doctorResults = await conn.query(doctorQuery);
      Map<int, String?> doctorProfiles = {};

      for (var row in doctorResults) {
        String? profilePicture = row['profile_picture'] != null
            ? (row['profile_picture'] is mysql.Blob
                ? String.fromCharCodes(
                    (row['profile_picture'] as mysql.Blob).toBytes())
                : row['profile_picture'].toString())
            : null;
        doctorProfiles[row['doctor_id']] = profilePicture;
      }

      // Then get the appointments
      const query = '''
        SELECT 
          a.id,
          a.appointment_date,
          a.appointment_time,
          a.status,
          a.notes,
          u.id as doctor_id,
          u.name as doctor_name,
          u.description as specialty
        FROM appointments a
        INNER JOIN users u ON a.doctor_id = u.id
        WHERE a.patient_id = ?
        AND a.status = 'active'
        ORDER BY a.appointment_date ASC, a.appointment_time ASC
      ''';

      final results = await conn.query(query, [patientId]);
      List<Map<String, dynamic>> appointments = [];

      for (var row in results) {
        final doctorId = row['doctor_id'];
        String? profilePicture = doctorProfiles[doctorId];

        // Process profile picture URL - only add 'assets/' prefix for local assets
        if (profilePicture != null &&
            !profilePicture.startsWith('http') &&
            !profilePicture.startsWith('assets/') &&
            !profilePicture
                .startsWith('https://firebasestorage.googleapis.com')) {
          profilePicture = 'assets/$profilePicture';
        }

        // Convert specialty from Blob if necessary
        String? specialty = row['specialty'] != null
            ? (row['specialty'] is mysql.Blob
                ? String.fromCharCodes(
                    (row['specialty'] as mysql.Blob).toBytes())
                : row['specialty'].toString())
            : null;

        appointments.add({
          'id': row['id'],
          'doctor_id': doctorId,
          'doctor_name': row['doctor_name']?.toString() ?? 'Unknown Doctor',
          'specialty': specialty ?? 'General Practice',
          'appointment_date': row['appointment_date'],
          'appointment_time': row['appointment_time'],
          'notes': row['notes']?.toString(),
          'profile_picture': profilePicture,
          'status': row['status']?.toString(),
        });
      }

      return appointments;
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  Future<List<Message>> getLatestMessages(int patientId) async {
    try {
      final conn = await connection;
      print('Fetching latest messages for patient: $patientId');

      // Updated query to count unread messages (is_read=1)
      final results = await conn.query('''
        WITH RankedMessages AS (
          SELECT 
            m.*,
            u_sender.name as sender_name,
            u_sender.profile_picture as sender_profile_picture,
            u_receiver.name as receiver_name,
            u_receiver.profile_picture as receiver_profile_picture,
            (SELECT COUNT(*) 
             FROM messages m2 
             WHERE m2.sender_id = m.sender_id 
             AND m2.receiver_id = ? 
             AND m2.is_read = 1) as unread_count,
            ROW_NUMBER() OVER (
              PARTITION BY 
                CASE 
                  WHEN m.sender_id = ? THEN m.receiver_id 
                  ELSE m.sender_id 
                END
              ORDER BY m.created_at DESC
            ) as rn
          FROM messages m
          JOIN users u_sender ON m.sender_id = u_sender.id
          JOIN users u_receiver ON m.receiver_id = u_receiver.id
          WHERE m.sender_id = ? OR m.receiver_id = ?
        )
        SELECT * FROM RankedMessages 
        WHERE rn = 1
        ORDER BY unread_count DESC, created_at DESC
      ''', [patientId, patientId, patientId, patientId]);

      return results.map((row) {
        String messageText = row['message'] is mysql.Blob
            ? String.fromCharCodes((row['message'] as mysql.Blob).toBytes())
            : row['message']?.toString() ?? '';

        final unreadCount = row['unread_count'] as int;
        print('Conversation unread count: $unreadCount'); // Debug print

        return Message.fromMap({
          'id': row['id'],
          'sender_id': row['sender_id'],
          'receiver_id': row['receiver_id'],
          'message': messageText,
          'image': row['image'],
          'created_at': row['created_at'].toString(),
          'updated_at': row['updated_at'].toString(),
          'is_read': row['is_read'] ?? false,
          'unread_count': unreadCount,
          'sender_name': row['sender_name'],
          'sender_profile_picture': row['sender_profile_picture'],
          'receiver_name': row['receiver_name'],
          'receiver_profile_picture': row['receiver_profile_picture'],
          'message_type': row['image'] != null ? 'image' : 'text',
        });
      }).toList();
    } catch (e) {
      print('Error fetching latest messages: $e');
      return [];
    }
  }

  Future<List<Message>> getMessagesBetweenUsers(
      int userId1, int userId2) async {
    try {
      final conn = await connection;
      print('=== FETCHING MESSAGES ===');
      print('Between users: $userId1 and $userId2');

      const query = '''
        SELECT 
          m.*,
          s.name as sender_name,
          s.profile_picture as sender_profile_picture,
          r.name as receiver_name,
          r.profile_picture as receiver_profile_picture
        FROM messages m
        JOIN users s ON m.sender_id = s.id
        JOIN users r ON m.receiver_id = r.id
        WHERE (m.sender_id = ? AND m.receiver_id = ?)
           OR (m.sender_id = ? AND m.receiver_id = ?)
        ORDER BY m.created_at ASC
      ''';

      final results =
          await conn.query(query, [userId1, userId2, userId2, userId1]);
      print('Found ${results.length} messages');

      final messages = results.map((row) {
        String messageText = row['message'] is mysql.Blob
            ? String.fromCharCodes((row['message'] as mysql.Blob).toBytes())
            : row['message']?.toString() ?? '';

        return Message.fromMap({
          'id': row['id'],
          'sender_id': row['sender_id'],
          'receiver_id': row['receiver_id'],
          'message': messageText,
          'image': row['image'],
          'created_at': row['created_at'].toString(),
          'updated_at': row['updated_at'].toString(),
          'is_read': row['is_read'] ?? false,
          'sender_name': row['sender_name'],
          'sender_profile_picture': row['sender_profile_picture'],
          'receiver_name': row['receiver_name'],
          'receiver_profile_picture': row['receiver_profile_picture'],
          'message_type': row['image'] != null ? 'image' : 'text',
        });
      }).toList();

      return messages;
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  Future<void> sendMessage({
    required int senderId,
    required int receiverId,
    required String message,
    String? image,
    String messageType = 'text',
  }) async {
    try {
      final conn = await connection;
      print('Sending message:');
      print('From: $senderId');
      print('To: $receiverId');
      print('Type: $messageType');
      print('Image URL: $image');

      // Don't modify Firebase Storage URLs
      final imageToStore = image != null &&
              image.startsWith('https://firebasestorage.googleapis.com')
          ? image
          : image != null
              ? 'assets/$image'
              : null;

      final timestamp = DateTime.now().toUtc().toString();

      // Remove message_type from the query until column is added
      await conn.query('''
        INSERT INTO messages (
          sender_id, 
          receiver_id, 
          message, 
          image, 
          created_at, 
          updated_at, 
          is_read
        ) VALUES (?, ?, ?, ?, ?, ?, 0)
      ''', [
        senderId,
        receiverId,
        message,
        imageToStore,
        timestamp,
        timestamp,
      ]);

      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReports(int patientId) async {
    try {
      final conn = await connection;
      print('\n=== FETCHING REPORTS START ===');
      print('Patient ID: $patientId');

      // First, verify the patient exists
      final patientCheck = await conn.query(
        'SELECT id, name FROM users WHERE id = ?',
        [patientId],
      );
      print(
          'Patient check result: ${patientCheck.isNotEmpty ? 'Found' : 'Not found'}');

      // Get total reports count for this patient
      final countResult = await conn.query(
        'SELECT COUNT(*) as count FROM reports WHERE patient_id = ?',
        [patientId],
      );
      print('Total reports in database: ${countResult.first['count']}');

      const query = '''
        SELECT 
          id,
          title,
          diagnosis,
          report_date,
          status,
          created_at,
          patient_id
        FROM reports 
        WHERE patient_id = ?
        AND deleted_at IS NULL
        ORDER BY created_at DESC
      ''';

      print('\nExecuting query:');
      print(query);
      print('Parameters: [$patientId]');

      final results = await conn.query(query, [patientId]);
      print('\nQuery results:');
      print('Number of reports found: ${results.length}');

      if (results.isEmpty) {
        print('No reports found for patient ID: $patientId');
        return [];
      }

      List<Map<String, dynamic>> reports = [];
      for (var row in results) {
        print('\nProcessing row:');
        print('ID: ${row['id']}');
        print('Title: ${row['title']}');
        print('Patient ID: ${row['patient_id']}');
        print('Status: ${row['status']}');

        final report = {
          'id': row['id'],
          'title': row['title'],
          'diagnosis': row['diagnosis'],
          'report_date': row['report_date'],
          'status': row['status'],
          'created_at': row['created_at'],
        };
        reports.add(report);
      }

      print('\nProcessed ${reports.length} reports successfully');
      print('=== FETCHING REPORTS END ===\n');
      return reports;
    } catch (e, stackTrace) {
      print('\n=== ERROR FETCHING REPORTS ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getReportDetails(int reportId) async {
    try {
      final conn = await connection;
      print('\n=== FETCHING REPORT DETAILS START ===');
      print('Report ID: $reportId');

      // First verify if the report exists
      final reportCheck = await conn.query(
        'SELECT id FROM reports WHERE id = ?',
        [reportId],
      );
      print('Report exists: ${reportCheck.isNotEmpty}');

      if (reportCheck.isEmpty) {
        print('Report not found with ID: $reportId');
        return null;
      }

      const query = '''
        SELECT 
          r.id,
          r.title,
          r.diagnosis,
          r.report_date,
          r.symptoms,
          r.treatment_plan,
          r.medications,
          r.blood_pressure_systolic,
          r.blood_pressure_diastolic,
          r.heart_rate,
          r.temperature,
          r.respiratory_rate,
          r.lab_results,
          r.status,
          r.height,
          r.weight,
          p.name as patient_name,
          p.gender,
          p.contact_number,
          p.profile_picture,
          d.name as doctor_name
        FROM reports r
        LEFT JOIN users p ON r.patient_id = p.id
        LEFT JOIN users d ON r.doctor_id = d.id
        WHERE r.id = ?
      ''';

      print('\nExecuting query with ID: $reportId');
      final results = await conn.query(query, [reportId]);

      if (results.isEmpty) {
        print('No results found after join');
        return null;
      }

      final row = results.first;
      print('\nProcessing row data:');
      print('Report ID: ${row['id']}');
      print('Height: ${row['height']}');
      print('Weight: ${row['weight']}');

      // Helper function to convert BLOB to String
      String? blobToString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        if (value is mysql.Blob) {
          return String.fromCharCodes(value.toString().codeUnits);
        }
        return value.toString();
      }

      // Build the report details map with BLOB handling
      final reportDetails = {
        'id': row['id'],
        'title': blobToString(row['title']) ?? 'Untitled Report',
        'patient_name': blobToString(row['patient_name']) ?? 'Unknown Patient',
        'patient_gender': blobToString(row['gender']) ?? 'Not Specified',
        'patient_contact': blobToString(row['contact_number']) ?? 'No Contact',
        'patient_profile': blobToString(row['profile_picture']),
        'doctor_name': blobToString(row['doctor_name']) ?? 'Unknown Doctor',
        'report_date': row['report_date']?.toString() ?? 'No Date',
        'symptoms': blobToString(row['symptoms']) ?? 'No symptoms recorded',
        'diagnosis': blobToString(row['diagnosis']) ?? 'No diagnosis recorded',
        'treatment_plan':
            blobToString(row['treatment_plan']) ?? 'No treatment plan recorded',
        'medications':
            blobToString(row['medications']) ?? 'No medications recorded',
        'height': row['height']?.toString() ?? 'Not recorded',
        'weight': row['weight']?.toString() ?? 'Not recorded',
        'blood_pressure': row['blood_pressure_systolic'] != null &&
                row['blood_pressure_diastolic'] != null
            ? '${row['blood_pressure_systolic']}/${row['blood_pressure_diastolic']}'
            : 'Not recorded',
        'heart_rate': row['heart_rate']?.toString() ?? 'Not recorded',
        'temperature': row['temperature']?.toString() ?? 'Not recorded',
        'respiratory_rate':
            row['respiratory_rate']?.toString() ?? 'Not recorded',
        'lab_results': blobToString(row['lab_results']) ?? 'No lab results',
        'status': blobToString(row['status']) ?? 'pending',
      };

      print('\nReport details processed successfully');
      print('Height value: ${reportDetails['height']}');
      print('Weight value: ${reportDetails['weight']}');
      print('Returning data: $reportDetails');
      return reportDetails;
    } catch (e, stackTrace) {
      print('\n=== ERROR FETCHING REPORT DETAILS ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Add this method to DatabaseService class
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final conn = await connection;
      print('Fetching user data for ID: $userId');

      // Get bed information
      final bedResults = await conn.query('''
        SELECT id, bed_number, room_id 
        FROM beds 
        WHERE patient_id = ?
      ''', [userId]);

      if (bedResults.isEmpty) {
        throw Exception('No bed assigned to this patient');
      }

      // Get patient name
      final userResults = await conn.query('''
        SELECT name 
        FROM users 
        WHERE id = ?
      ''', [userId]);

      if (userResults.isEmpty) {
        throw Exception('User not found');
      }

      // Get room information and nurse schedule
      final roomResults = await conn.query('''
        SELECT r.room_number, r.floor, ns.nurse_id, ns.shift
        FROM rooms r
        LEFT JOIN nurse_schedules ns ON ns.room_id = r.id
        WHERE r.id = ?
        AND ns.date = CURDATE()
        AND ns.status = 'scheduled'
        AND (
          (HOUR(NOW()) BETWEEN 7 AND 14 AND ns.shift = 'morning') OR
          (HOUR(NOW()) BETWEEN 15 AND 22 AND ns.shift = 'afternoon') OR
          ((HOUR(NOW()) >= 23 OR HOUR(NOW()) <= 6) AND ns.shift = 'night')
        )
      ''', [bedResults.first['room_id']]);

      final userData = {
        'patient_name': userResults.first['name'] ?? 'Unknown Patient',
        'bed_id': bedResults.first['id'] ?? 0,
        'bed_number': bedResults.first['bed_number'] ?? 1,
        'room_id': bedResults.first['room_id'] ?? 1,
        'room_number': roomResults.isNotEmpty
            ? roomResults.first['room_number'] ?? 101
            : 101,
        'floor': roomResults.isNotEmpty ? roomResults.first['floor'] ?? 1 : 1,
        'assigned_nurse_id':
            roomResults.isNotEmpty ? roomResults.first['nurse_id'] ?? 0 : 0,
        'current_shift': roomResults.isNotEmpty
            ? roomResults.first['shift'] ?? 'morning'
            : 'morning',
      };

      print('Fetched user data: $userData');
      return userData;
    } catch (e) {
      print('Error fetching user data: $e');
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic>? params]) async {
    try {
      print('\n=== DATABASE QUERY START ===');
      print('SQL: $sql');
      print('Parameters: $params');

      final conn = await connection;
      final results = await conn.query(sql, params);

      print('Query executed successfully');
      print('Number of rows returned: ${results.length}');

      // Convert Results to List<Map<String, dynamic>>
      final mappedResults = results.map((row) => row.fields).toList();

      print('Results converted to map successfully');
      print('=== DATABASE QUERY END ===\n');

      return mappedResults;
    } catch (e, stackTrace) {
      print('\n=== DATABASE QUERY ERROR ===');
      print('SQL: $sql');
      print('Parameters: $params');
      print('Error: $e');
      print('Stack trace:\n$stackTrace');
      print('=== END DATABASE QUERY ERROR ===\n');
      throw Exception('Database query failed: $e');
    }
  }

  Future<void> execute(String sql, [List<dynamic>? params]) async {
    try {
      final conn = await connection;
      await conn.query(sql, params);
    } catch (e) {
      print('Error executing statement: $e');
      throw Exception('Database execute failed: $e');
    }
  }

  // Update the constructor to use the singleton pattern
  factory DatabaseService() {
    return instance;
  }

  // for family status page
  Future<List<Map<String, dynamic>>> getFamilyMembers(int userId) async {
    try {
      print('Fetching family members for user ID: $userId');
      final sqlQuery = '''
        SELECT 
          fm.user_id,
          fm.relationship,
          b.status,  -- Fetching status from beds table
          u.id,
          u.name,
          u.email,
          u.profile_picture,
          u.medical_condition
        FROM family_members fm
        JOIN users u ON fm.family_member_id = u.id
        LEFT JOIN beds b ON b.patient_id = u.id  -- Joining with beds table
        WHERE fm.user_id = ?
        AND fm.deleted_at IS NULL
      ''';
      final results = await query(sqlQuery, [userId]);
      print('Found ${results.length} family members for user ID: $userId');
      return results;
    } catch (e, stackTrace) {
      print('Error fetching family members: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Add this method to DatabaseService class
  Future<int> getUnreadMessageCount(int userId) async {
    try {
      final conn = await connection;
      print('=== FETCHING READ MESSAGES ===');
      print('User ID: $userId');

      const query = '''
        SELECT COUNT(*) as read_count 
        FROM messages 
        WHERE receiver_id = ? 
        AND is_read = 1
      ''';

      final results = await conn.query(query, [userId]);
      final readCount = results.first['read_count'] as int;

      print('Read message count: $readCount');
      return readCount;
    } catch (e) {
      print('Error getting read message count: $e');
      return 0;
    }
  }

  // Add this method to mark messages as read
  Future<void> markMessagesAsRead(int senderId, int receiverId) async {
    try {
      final conn = await connection;
      print('Marking messages as read between $senderId and $receiverId');

      await conn.query('''
        UPDATE messages 
        SET is_read = 1, 
            updated_at = NOW()
        WHERE sender_id = ? 
        AND receiver_id = ? 
        AND is_read = 0
      ''', [senderId, receiverId]);

      print('Messages marked as read successfully');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  //profile page
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final conn = await connection;
    final result = await conn
        .query('SELECT *, profile_picture FROM users WHERE id = ?', [userId]);
    return result.first.fields;
  }

  // update user profile
  Future<void> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    required String phone,
    String? profilePicture,
    String? gender,
  }) async {
    try {
      final conn = await connection;
      print('Updating profile for user ID: $userId');

      String query = '''
        UPDATE users 
        SET 
          name = ?,
          email = ?,
          contact_number = ?,
          ${profilePicture != null ? 'profile_picture = ?,' : ''}
          updated_at = NOW()
        WHERE id = ?
      ''';

      List<dynamic> params = [
        name,
        email,
        phone,
        if (profilePicture != null) profilePicture,
        userId,
      ];

      await conn.query(query, params);
      print('Profile updated successfully');
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNurseSchedule({
    required int roomId,
    required String shift,
  }) async {
    final conn = await connection;
    final result = await conn.query(
      'SELECT nurse_id FROM nurse_schedules WHERE date = CURRENT_DATE AND shift = ? AND room_id = ?',
      [shift, roomId],
    );

    if (result.isEmpty) {
      throw Exception('No nurse assigned for this shift');
    }

    return result.first.fields;
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateFirestoreUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // change password
  Future<bool> verifyPassword({
    required int userId,
    required String password,
  }) async {
    try {
      final conn = await connection;
      print('Verifying password for user ID: $userId');

      final results = await conn.query('''
        SELECT password 
        FROM users 
        WHERE id = ?
      ''', [userId]);

      if (results.isEmpty) {
        print('No user found for ID: $userId');
        return false;
      }

      final hashedPassword = results.first['password'] as String;
      print('Stored hashed password: $hashedPassword');
      print('Input password: $password');

      // Use bcrypt to verify the password
      try {
        // Remove the $2y prefix and replace with $2a for Dart's bcrypt
        final normalizedHash = hashedPassword.replaceFirst('\$2y', '\$2a');
        final isValid = BCrypt.checkpw(password, normalizedHash);

        print(isValid
            ? 'Password verified successfully'
            : 'Password verification failed');
        return isValid;
      } catch (e) {
        print('Error verifying password with bcrypt: $e');
        return false;
      }
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  Future<void> updatePassword({
    required int userId,
    required String newPassword,
  }) async {
    try {
      final conn = await connection;
      print('Updating password for user ID: $userId');

      // Hash the new password using bcrypt
      final salt = BCrypt.gensalt();
      final hashedPassword = BCrypt.hashpw(newPassword, salt);
      // Convert $2a to $2y to match PHP's bcrypt format
      final phpCompatibleHash = hashedPassword.replaceFirst('\$2a', '\$2y');

      await conn.query('''
        UPDATE users 
        SET password = ?,
            updated_at = NOW()
        WHERE id = ?
      ''', [phpCompatibleHash, userId]);

      print('Password updated successfully');
    } catch (e) {
      print('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }
}
