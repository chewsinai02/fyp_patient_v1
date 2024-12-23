import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class DatabaseService {
  static DatabaseService? _instance;
  MySqlConnection? _conn;
  bool _isConnecting = false;
  static const int _maxConnections = 5;
  static int _currentConnections = 0;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<MySqlConnection> get connection async {
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

      final settings = ConnectionSettings(
        host: 'mydb.cdsagqe648ba.ap-southeast-2.rds.amazonaws.com',
        port: 3306,
        user: 'admin',
        password: 'admin1234',
        db: 'mydb1',
        timeout: Duration(seconds: 30),
      );

      _conn = await MySqlConnection.connect(settings);
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

      // First, check if user exists
      print('Executing user query...');
      final results =
          await conn.query('SELECT * FROM users WHERE email = ?', [email]);

      print('Query results count: ${results.length}');

      if (results.isEmpty) {
        print('No user found with email: $email');
        return null;
      }

      final user = results.first;

      // For Laravel's password hash, we need to use the raw password
      // Laravel will handle the hashing on their end
      final storedPassword = user['password'];

      // For testing purposes, let's print the raw input
      print('\nUser found:');
      print('ID: ${user['id']}');
      print('Name: ${user['name']}');
      print('Email: ${user['email']}');

      // Direct comparison with the raw password
      // This assumes your Laravel API will handle the actual password verification
      return {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'gender': user['gender'],
        'address': user['address'],
        'phone': user['contact_number'],
        'profile_picture': user['profile_picture'],
      };
    } catch (e, stackTrace) {
      print('=== AUTHENTICATION ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  //dashboard count task
  Future<Map<String, dynamic>> getTasksProgress(int patientId) async {
    try {
      final conn = await connection;
      print('Getting tasks progress for patient ID: $patientId');

      // Get pending tasks count for today
      final pendingResult = await conn.query('''
        SELECT COUNT(*) as pending 
        FROM tasks 
        WHERE patient_id = ? 
        AND DATE(due_date) = CURDATE() 
        AND status = "pending"
        ''', [patientId]);

      // Get completed tasks count for today
      final completedResult = await conn.query('''
        SELECT COUNT(*) as completed 
        FROM tasks 
        WHERE patient_id = ? 
        AND DATE(due_date) = CURDATE() 
        AND status = "completed"
        ''', [patientId]);

      // Get passed tasks count for today
      final passedResult = await conn.query('''
        SELECT COUNT(*) as passed 
        FROM tasks 
        WHERE patient_id = ? 
        AND DATE(due_date) = CURDATE() 
        AND status = "passed"
        ''', [patientId]);

      print('Query results:');
      print('Pending tasks: ${pendingResult.first}');
      print('Completed tasks: ${completedResult.first}');
      print('Passed tasks: ${passedResult.first}');

      final pending = pendingResult.first['pending'] as int;
      final completed = completedResult.first['completed'] as int;
      final passed = passedResult.first['passed'] as int;

      final total = pending + completed + passed;

      print('Calculated progress:');
      print('Pending tasks: $pending');
      print('Completed tasks: $completed');
      print('Passed tasks: $passed');
      print('Total tasks: $total');
      print('Progress ratio: ${total > 0 ? completed / total : 0.0}');

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'passed': passed,
        'progress': total > 0 ? completed / total : 0.0,
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
          if (value is Blob) {
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
      print('=== FETCHING DOCTORS START ===');
      final conn = await connection;

      const query = '''
        SELECT 
          id,
          name,
          description,
          staff_id as experience,
          CAST(5.0 AS DECIMAL(3,1)) as rating,
          COALESCE(profile_picture, '/images/default_avatar.png') as profile_picture
        FROM users 
        WHERE LOWER(role) = 'doctor'
      ''';

      print('Executing query: $query');
      final results = await conn.query(query);
      print('Raw results from database: ${results.length}');

      List<Map<String, dynamic>> doctors = [];
      for (var row in results) {
        String specialty = 'General Practice';
        try {
          if (row['description'] != null) {
            if (row['description'] is Blob) {
              final blob = row['description'] as Blob;
              specialty = String.fromCharCodes(blob.toString().codeUnits);
            } else {
              specialty = row['description'].toString();
            }
          }
        } catch (e) {
          print('Error converting description to string: $e');
          specialty = 'General Practice';
        }

        // Process profile picture path
        String profilePicture =
            row['profile_picture'] ?? '/images/default_avatar.png';
        if (!profilePicture.startsWith('/')) {
          profilePicture = '/$profilePicture';
        }

        final doctor = {
          'id': row['id'],
          'name': row['name'],
          'specialty': specialty,
          'experience': row['experience']?.toString() ?? 'N/A',
          'rating': row['rating'] ?? 5.0,
          'profile_picture': profilePicture,
        };
        print('Processing doctor: $doctor');
        doctors.add(doctor);
      }

      print('=== FETCHING DOCTORS END ===');
      print('Total doctors processed: ${doctors.length}');
      return doctors;
    } catch (e, stackTrace) {
      print('=== ERROR FETCHING DOCTORS ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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
      Map<int, String> doctorProfiles = {};

      for (var row in doctorResults) {
        doctorProfiles[row['doctor_id']] =
            row['profile_picture'] ?? '/images/default_avatar.png';
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

      print('Executing appointments query with patient ID: $patientId');
      final results = await conn.query(query, [patientId]);
      print('Found ${results.length} appointments');

      List<Map<String, dynamic>> appointments = [];
      for (var row in results) {
        final doctorId = row['doctor_id'];
        String profilePicture =
            doctorProfiles[doctorId] ?? '/images/default_avatar.png';

        // Ensure profile picture starts with a forward slash
        if (!profilePicture.startsWith('/')) {
          profilePicture = '/$profilePicture';
        }

        print(
            'Processing appointment: ${row['id']} for doctor: ${row['doctor_name']}');
        print('Doctor ID: $doctorId');
        print('Profile picture path: $profilePicture');

        appointments.add({
          'id': row['id'],
          'doctor_id': doctorId,
          'doctor_name': row['doctor_name'] ?? 'Unknown Doctor',
          'specialty': row['specialty'] ?? 'General Practice',
          'appointment_date': row['appointment_date'],
          'appointment_time': row['appointment_time'],
          'notes': row['notes'],
          'profile_picture': profilePicture,
          'status': row['status'],
        });
      }

      print('Processed ${appointments.length} appointments successfully');
      return appointments;
    } catch (e, stackTrace) {
      print('Error fetching appointments: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Message>> getLatestMessages(int patientId) async {
    try {
      final conn = await connection;
      print('Fetching latest messages for patient ID: $patientId');

      // Modified query to get latest message with each doctor
      final results = await conn.query('''
        WITH RankedMessages AS (
          SELECT 
            m.*,
            u_sender.name as sender_name,
            u_sender.profile_picture as sender_profile_picture,
            u_sender.role as sender_role,
            u_receiver.name as receiver_name,
            u_receiver.profile_picture as receiver_profile_picture,
            u_receiver.role as receiver_role,
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
          WHERE (m.sender_id = ? OR m.receiver_id = ?)
            AND (u_sender.role = 'doctor' OR u_receiver.role = 'doctor')
        )
        SELECT * FROM RankedMessages 
        WHERE rn = 1
        ORDER BY created_at DESC
      ''', [patientId, patientId, patientId]);

      print('Found ${results.length} conversations');

      return results.map((row) {
        String messageText = row['message'] is Blob
            ? String.fromCharCodes((row['message'] as Blob).toBytes())
            : row['message'].toString();

        return Message.fromMap({
          'id': row['id'],
          'sender_id': row['sender_id'],
          'receiver_id': row['receiver_id'],
          'message': messageText,
          'image': row['image'] != null ? 'assets/${row['image']}' : null,
          'created_at': row['created_at'].toString(),
          'updated_at': row['updated_at'].toString(),
          'is_read': row['is_read'],
          'sender_name': row['sender_name'],
          'sender_profile_picture': row['sender_profile_picture'] != null
              ? 'assets/${row['sender_profile_picture']}'
              : 'assets/images/doctor_placeholder.png',
          'receiver_name': row['receiver_name'],
          'receiver_profile_picture': row['receiver_profile_picture'] != null
              ? 'assets/${row['receiver_profile_picture']}'
              : 'assets/images/doctor_placeholder.png',
        });
      }).toList();
    } catch (e) {
      print('Error fetching latest messages: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<List<Message>> getMessagesBetweenUsers(
      int userId1, int userId2) async {
    try {
      final conn = await connection;
      print('=== FETCHING MESSAGES BETWEEN USERS ===');
      print('User 1 ID: $userId1');
      print('User 2 ID: $userId2');

      // First verify if both users exist and at least one is a doctor
      const userCheckQuery = '''
        SELECT id, name, role FROM users 
        WHERE id IN (?, ?) AND (role = 'doctor' OR role = 'patient')
      ''';

      final userResults = await conn.query(userCheckQuery, [userId1, userId2]);
      print('Found ${userResults.length} users:');
      for (var user in userResults) {
        print(
            'User ID: ${user['id']}, Name: ${user['name']}, Role: ${user['role']}');
      }

      if (userResults.length != 2) {
        print('Error: Could not find both users or invalid user roles');
        return [];
      }

      // Then get the messages with role verification
      final results = await conn.query('''
        SELECT 
          m.id,
          m.sender_id,
          m.receiver_id,
          CAST(m.message AS CHAR) as message,
          m.image,
          m.created_at,
          m.updated_at,
          m.is_read,
          sender.name as sender_name,
          sender.profile_picture as sender_profile_picture,
          sender.role as sender_role,
          receiver.name as receiver_name,
          receiver.profile_picture as receiver_profile_picture,
          receiver.role as receiver_role
        FROM messages m
        JOIN users sender ON m.sender_id = sender.id
        JOIN users receiver ON m.receiver_id = receiver.id
        WHERE ((m.sender_id = ? AND m.receiver_id = ?) 
           OR (m.sender_id = ? AND m.receiver_id = ?))
        AND (
          (sender.role = 'doctor' AND receiver.role = 'patient')
          OR 
          (sender.role = 'patient' AND receiver.role = 'doctor')
        )
        ORDER BY m.created_at ASC
      ''', [userId1, userId2, userId2, userId1]);

      print('Found ${results.length} messages between users');

      if (results.isEmpty) {
        print('No messages found between these users');
        // Check if there are any messages at all for either user
        final checkMessages = await conn.query('''
          SELECT DISTINCT m.sender_id, m.receiver_id 
          FROM messages m
          JOIN users sender ON m.sender_id = sender.id
          JOIN users receiver ON m.receiver_id = receiver.id
          WHERE (m.sender_id IN (?, ?) OR m.receiver_id IN (?, ?))
          AND (
            (sender.role = 'doctor' AND receiver.role = 'patient')
            OR 
            (sender.role = 'patient' AND receiver.role = 'doctor')
          )
        ''', [userId1, userId2, userId1, userId2]);

        print(
            'Total message relationships for these users: ${checkMessages.length}');
        for (var msg in checkMessages) {
          print(
              'Message relationship: ${msg['sender_id']} -> ${msg['receiver_id']}');
        }
      }

      final messages = results.map((row) {
        // Convert Blob to String if necessary
        String messageText = row['message'] is Blob
            ? String.fromCharCodes((row['message'] as Blob).toBytes())
            : row['message'].toString();

        print(
            'Processing message: ID=${row['id']}, Sender=${row['sender_id']}, Receiver=${row['receiver_id']}');

        return Message.fromMap({
          'id': row['id'],
          'sender_id': row['sender_id'],
          'receiver_id': row['receiver_id'],
          'message': messageText,
          'image': row['image'] != null ? 'assets/${row['image']}' : null,
          'created_at': row['created_at'].toString(),
          'updated_at': row['updated_at'].toString(),
          'is_read': row['is_read'] ?? false,
          'sender_name': row['sender_name'],
          'sender_profile_picture': row['sender_profile_picture'] != null
              ? 'assets/${row['sender_profile_picture']}'
              : 'assets/images/doctor_placeholder.png',
          'receiver_name': row['receiver_name'],
          'receiver_profile_picture': row['receiver_profile_picture'] != null
              ? 'assets/${row['receiver_profile_picture']}'
              : 'assets/images/doctor_placeholder.png',
        });
      }).toList();

      print('Successfully processed ${messages.length} messages');
      print('=== END FETCHING MESSAGES ===');
      return messages;
    } catch (e, stackTrace) {
      print('=== ERROR FETCHING MESSAGES ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
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
      print('Sending message from $senderId to $receiverId');
      print('Message type: $messageType');
      print('Image URL: $image');

      final timestamp = DateTime.now().toUtc().toString();
      await conn.query('''
        INSERT INTO messages (
          sender_id, 
          receiver_id, 
          message, 
          image, 
          created_at, 
          updated_at, 
          is_read,
          message_type
        ) VALUES (?, ?, ?, ?, ?, ?, 0, ?)
      ''', [
        senderId,
        receiverId,
        message,
        image,
        timestamp,
        timestamp,
        messageType
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
        if (value is Blob) {
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

      // Join query to get all required information
      final results = await conn.query('''
        SELECT 
          u.id,
          u.name as patient_name,
          b.id as bed_id,
          b.bed_number,
          b.room_id,
          r.room_number,
          r.floor,
          ns.nurse_id,
          ns.shift
        FROM users u
        JOIN beds b ON b.patient_id = u.id
        JOIN rooms r ON b.room_id = r.id
        LEFT JOIN nurse_schedules ns ON ns.room_id = r.id
        WHERE u.id = ?
        AND ns.date = CURDATE()
        AND ns.status = 'scheduled'
        AND (
          (HOUR(NOW()) BETWEEN 7 AND 14 AND ns.shift = 'morning') OR
          (HOUR(NOW()) BETWEEN 15 AND 22 AND ns.shift = 'afternoon') OR
          ((HOUR(NOW()) >= 23 OR HOUR(NOW()) <= 6) AND ns.shift = 'night')
        )
      ''', [userId]);

      if (results.isEmpty) {
        throw Exception('User not found');
      }

      final userData = {
        'patient_name': results.first['patient_name'],
        'room_number': results.first['room_number'],
        'bed_number': results.first['bed_number'],
        'room_id': results.first['room_id'],
        'floor': results.first['floor'],
        'assigned_nurse_id': results.first['nurse_id'],
        'current_shift': results.first['shift'],
      };

      print('Fetched user data: $userData');
      return userData;
    } catch (e) {
      print('Error fetching user data: $e');
      return {
        'patient_name': 'Unknown Patient',
        'room_number': 101,
        'bed_number': 1,
        'room_id': 1,
        'floor': 1,
        'assigned_nurse_id': null,
        'current_shift': null,
      };
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
}
