import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import 'chat_page.dart';

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
        future: DatabaseService.instance.getLatestMessages(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No messages found.'));
          }

          final messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              // Get the other user's ID (doctor)
              final doctorId = message.senderId == patientId
                  ? message.receiverId
                  : message.senderId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: message.senderId == patientId
                      ? (message.receiverProfilePicture != null
                          ? AssetImage(message.receiverProfilePicture!)
                          : const AssetImage(
                              'assets/images/doctor_placeholder.png'))
                      : (message.senderProfilePicture != null
                              ? AssetImage(message.senderProfilePicture!)
                              : const AssetImage(
                                  'assets/images/doctor_placeholder.png'))
                          as ImageProvider,
                  backgroundColor: Colors.deepPurple.shade100,
                  // child: Text(
                  //   (message.senderId == patientId
                  //           ? message.receiverName
                  //           : message.senderName)?[0] ??
                  //       '?',
                  //   style: const TextStyle(color: Colors.deepPurple),
                  // ),
                ),
                title: Text(
                  message.senderId == patientId
                      ? message.receiverName ?? 'Unknown'
                      : message.senderName ?? 'Unknown',
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!message.isRead && message.senderId != patientId)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                trailing: Text(formatTime(message.createdAt)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        patientId: patientId,
                        otherUserId: doctorId,
                      ),
                    ),
                  );
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
