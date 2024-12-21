import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class MessagesPage extends StatelessWidget {
  final int patientId;
  const MessagesPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Message>>(
        future: DatabaseService.instance.getMessages(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No messages found.'));
          }

          final messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(message.message),
                subtitle: message.image != null ? const Text('[Image]') : null,
                trailing: Text(formatTime(message.createdAt)),
                onTap: () {
                  // Handle message tap
                },
              );
            },
          );
        },
      ),
    );
  }

  String formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
