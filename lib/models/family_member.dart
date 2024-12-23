import 'package:flutter/material.dart';

class FamilyMember {
  final int id;
  final String name;
  final String relation;
  final String status;
  final String lastUpdate;
  final Color statusColor;
  final String imageUrl;
  final String email;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.status,
    required this.lastUpdate,
    required this.statusColor,
    required this.imageUrl,
    required this.email,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Unknown',
      relation: map['relationship'] as String? ?? 'Unknown',
      status: map['status'] as String? ?? 'Unknown',
      lastUpdate: map['last_update'] as String? ?? 'Recently',
      statusColor: _parseColor(map['status_color'] as String? ?? 'grey'),
      imageUrl:
          map['imageUrl'] as String? ?? 'https://ui-avatars.com/api/?name=User',
      email: map['email'] as String? ?? '',
    );
  }

  static Color _parseColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
