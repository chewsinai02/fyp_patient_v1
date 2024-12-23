import 'package:flutter/material.dart';
import '../models/family_member.dart';
import 'database_service.dart';

class FamilyMemberService {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<FamilyMember>> getFamilyMembers(int userId) async {
    try {
      print('\n=== FETCHING FAMILY MEMBERS START ===');
      print('User ID: $userId');

      final db = DatabaseService.instance;

      // First get all relationships for this user
      final relationshipsQuery = '''
        SELECT relationship 
        FROM family_members 
        WHERE user_id = ?
      ''';

      print('\nFetching relationships...');
      final relationshipsResult = await db.query(relationshipsQuery, [userId]);

      if (relationshipsResult.isEmpty) {
        print('No relationships found for user ID: $userId');
        return [];
      }

      // Get the relationship IDs and ensure they're valid
      final relationships =
          relationshipsResult.first['relationship'].toString();
      if (relationships.isEmpty) {
        print('Empty relationships string');
        return [];
      }

      final relationshipIds = relationships
          .split(',')
          .where((id) => id.trim().isNotEmpty)
          .join(',');

      if (relationshipIds.isEmpty) {
        print('No valid relationship IDs found');
        return [];
      }

      print('Found relationship IDs: $relationshipIds');

      // Now get all users that match these relationship IDs with their bed conditions
      final query = '''
        SELECT 
          u.id,
          u.name, 
          u.email, 
          CONCAT('assets/', COALESCE(u.profile_picture, 'images/profile.png')) as imageUrl,
          COALESCE(b.condition, 'Stable') as health_condition
        FROM users u
        LEFT JOIN beds b ON b.patient_id = u.id
        WHERE u.id IN ($relationshipIds)
        ORDER BY FIELD(u.id, $relationshipIds)
      ''';

      print('\nExecuting users query...');
      print('Query: $query');

      final results = await db.query(query);
      print('\nQuery results:');
      print('Number of family members found: ${results.length}');

      if (results.isEmpty) {
        print('No family members found');
        return [];
      }

      print('\nProcessing family members:');
      final familyMembers = results.map((row) {
        print('\nProcessing member:');
        print('ID: ${row['id']}');
        print('Name: ${row['name']}');
        print('Email: ${row['email']}');
        print('Image URL: ${row['imageUrl']}');
        print('Health Condition: ${row['health_condition']}');

        final statusInfo =
            _determineStatusAndColor(row['health_condition']?.toString() ?? '');

        return FamilyMember(
          id: row['id'] as int,
          name: row['name']?.toString() ?? 'Unknown',
          relation: '',
          status: statusInfo['status'] as String,
          lastUpdate: 'Recently',
          statusColor: statusInfo['color'] as Color,
          imageUrl: row['imageUrl']?.toString() ?? 'assets/images/profile.png',
          email: row['email']?.toString() ?? '',
        );
      }).toList();

      print(
          '\n✓ Successfully processed ${familyMembers.length} family members');
      print('=== FETCHING FAMILY MEMBERS END ===\n');
      return familyMembers;
    } catch (e, stackTrace) {
      print('\n=== ERROR FETCHING FAMILY MEMBERS ===');
      print('Error: $e');
      print('Stack trace:\n$stackTrace');
      print('=== END ERROR ===\n');

      if (e.toString().contains('Socket has been closed')) {
        print('Attempting to reconnect...');
        await DatabaseService.instance.close();
        return getFamilyMembers(userId);
      }

      throw Exception('Failed to load family members: $e');
    }
  }

  String _formatLastUpdate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> addFamilyMember(
      int userId, int familyMemberId, String relationship) async {
    try {
      // First check if relationship already exists
      const checkQuery = '''
        SELECT COUNT(*) as count 
        FROM family_members 
        WHERE user_id = ? AND family_member_id = ?
      ''';

      final result = await _db.query(checkQuery, [userId, familyMemberId]);
      final count = result.first['count'] as int;

      if (count > 0) {
        throw Exception('This family member relationship already exists');
      }

      const insertQuery = '''
        INSERT INTO family_members (user_id, family_member_id)
        VALUES (?, ?)
      ''';

      await _db.execute(insertQuery, [userId, familyMemberId]);
    } catch (e) {
      throw Exception('Failed to add family member: $e');
    }
  }

  Future<void> removeFamilyMember(int userId, int familyMemberId) async {
    try {
      // First get the current relationship string
      const getQuery = '''
        SELECT relationship 
        FROM family_members 
        WHERE user_id = ?
      ''';

      final result = await _db.query(getQuery, [userId]);
      if (result.isEmpty) {
        throw Exception('Family member relationship not found');
      }

      // Get and update the relationship string
      final currentRelationships = result.first['relationship'].toString();
      final relationshipList = currentRelationships.split(',');
      relationshipList.remove(familyMemberId.toString());
      final newRelationships = relationshipList.join(',');

      // Update the relationship string
      const updateQuery = '''
        UPDATE family_members 
        SET relationship = ?
        WHERE user_id = ?
      ''';

      await _db.execute(updateQuery, [newRelationships, userId]);

      print('Updated relationships: $newRelationships');
    } catch (e) {
      print('Error removing family member: $e');
      throw Exception('Failed to remove family member: Database execute error');
    }
  }

  Future<void> updateRelationship(
      int userId, int familyMemberId, String newRelationship) async {
    try {
      const query = '''
        UPDATE family_members 
        SET relationship = ?
        WHERE user_id = ? AND family_member_id = ?
      ''';

      await _db.execute(query, [newRelationship, userId, familyMemberId]);
    } catch (e) {
      throw Exception('Failed to update relationship: $e');
    }
  }

  // Updated helper method to determine status and color based on health conditions
  Map<String, dynamic> _determineStatusAndColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'critical':
        return {
          'status': 'Critical',
          'color': Colors.red,
        };
      case 'serious':
        return {
          'status': 'Serious',
          'color': Colors.orange,
        };
      case 'fair':
        return {
          'status': 'Fair',
          'color': Colors.blue,
        };
      case 'good':
        return {
          'status': 'Good',
          'color': Colors.green,
        };
      default:
        return {
          'status': 'Stable',
          'color': Colors.green,
        };
    }
  }

  Future<void> testDatabaseConnection() async {
    try {
      print('\n=== DATABASE CONNECTION TEST START ===');

      // Test 1: Basic connection
      print('\n1. Testing basic connection...');
      final result = await _db.query('SELECT 1');
      print('✓ Basic connection successful');

      // Test 2: Check if users table exists and has data
      print('\n2. Checking users table...');
      final usersTable = await _db.query('''
        SELECT COUNT(*) as count 
        FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
        AND table_name = 'users'
      ''');
      print('Users table exists: ${usersTable.first['count'] > 0}');

      // Test 3: Check if family_members table exists
      print('\n3. Checking family_members table...');
      final familyTable = await _db.query('''
        SELECT COUNT(*) as count 
        FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
        AND table_name = 'family_members'
      ''');
      print('Family members table exists: ${familyTable.first['count'] > 0}');

      // Test 4: Check table structure
      print('\n4. Checking family_members table structure...');
      final columns = await _db.query('''
        SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
        FROM information_schema.COLUMNS 
        WHERE TABLE_NAME = 'family_members'
      ''');
      print('Family members table columns:');
      for (var col in columns) {
        print(
            '- ${col['COLUMN_NAME']}: ${col['DATA_TYPE']} (Nullable: ${col['IS_NULLABLE']})');
      }

      // Test 5: Check for specific users
      print('\n5. Checking specific users...');
      final userIds = [26, 11, 19, 22, 14, 17];
      for (final id in userIds) {
        final user = await _db
            .query('SELECT id, name, email FROM users WHERE id = ?', [id]);
        if (user.isEmpty) {
          print('❌ User $id: Not found');
        } else {
          print('✓ User $id: ${user.first['name']} (${user.first['email']})');
        }
      }

      // Test 6: Check existing family relationships
      print('\n6. Checking existing family relationships...');
      final relationships = await _db.query('''
        SELECT 
          fm.user_id,
          fm.family_member_id,
          u1.name as user_name,
          u2.name as family_member_name
        FROM family_members fm
        JOIN users u1 ON fm.user_id = u1.id
        JOIN users u2 ON fm.family_member_id = u2.id
        LIMIT 5
      ''');

      if (relationships.isEmpty) {
        print('❌ No family relationships found');
      } else {
        print('Found ${relationships.length} relationships:');
        for (var rel in relationships) {
          print('- ${rel['user_name']} -> ${rel['family_member_name']}');
        }
      }

      print('\n=== DATABASE CONNECTION TEST END ===\n');
    } catch (e, stackTrace) {
      print('\n=== DATABASE TEST ERROR ===');
      print('Error: $e');
      print('Stack trace:\n$stackTrace');
      print('=== END DATABASE TEST ERROR ===\n');
    }
  }
}
