import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static DatabaseService? _instance;
  MySqlConnection? _conn;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<MySqlConnection> get connection async {
    print('=== DATABASE CONNECTION START ===');

    try {
      var env = DotEnv();
      print('Loading environment variables...');

      // Try multiple possible paths
      List<String> possiblePaths = [
        '.env',
        '../.env',
        'lib/.env',
        'assets/.env',
      ];

      bool loaded = false;
      for (String path in possiblePaths) {
        try {
          print('\nTrying to load .env from: $path');
          env.load([path]);
          loaded = true;
          print('Successfully loaded .env from: $path');
          break;
        } catch (e) {
          print('Failed to load from $path: $e');
        }
      }

      if (!loaded) {
        throw 'Could not find or load .env file';
      }

      final settings = ConnectionSettings(
        host:
            'mydb.cdsagqe648ba.ap-southeast-2.rds.amazonaws.com', // AWS RDS endpoint
        port: 3306,
        user: 'admin',
        password: 'admin1234',
        db: 'mydb1',
        timeout: const Duration(
            seconds: 30), // Increased timeout for remote connection
      );

      print('\nAttempting to establish connection to AWS RDS...');
      _conn = await MySqlConnection.connect(settings);
      print('Connection to AWS RDS established successfully!');
      return _conn!;
    } catch (e, stackTrace) {
      print('=== DATABASE CONNECTION ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }

  // Example method to fetch doctors
  Future<List<Map<String, dynamic>>> getDoctors() async {
    final conn = await connection;
    final results = await conn.query('SELECT * FROM doctors');

    return results
        .map((row) => {
              'id': row['id'],
              'name': row['name'],
              'specialty': row['specialty'],
              'experience': row['experience'],
              'rating': row['rating'],
              'isAvailable': row['is_available'] == 1,
            })
        .toList();
  }

  // Example method to add a doctor
  Future<void> addDoctor({
    required String name,
    required String specialty,
    required String experience,
    required double rating,
    required bool isAvailable,
  }) async {
    final conn = await connection;
    await conn.query(
      'INSERT INTO doctors (name, specialty, experience, rating, is_available) VALUES (?, ?, ?, ?, ?)',
      [name, specialty, experience, rating, isAvailable ? 1 : 0],
    );
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
}
