import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class ChatPage extends StatelessWidget {
  final int patientId;
  const ChatPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<List<Message>>(
                future: DatabaseService.instance.getMessages(patientId),
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
                    padding: const EdgeInsets.all(24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSender = message.senderId ==
                          patientId; // Check if the current user is the sender
                      return _buildChatCard(
                        message: message.message,
                        time: formatTime(message.createdAt),
                        isRead: message.isRead,
                        hasImage: message.image != null,
                        doctorName: isSender
                            ? message.receiverName ?? 'Unknown'
                            : message.senderName ?? 'Unknown',
                        profilePicture: isSender
                            ? message.receiverProfilePicture
                            : message.senderProfilePicture,
                      );
                    },
                  );
                },
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 16),
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard({
    required String message,
    required String time,
    required bool isRead,
    required bool hasImage,
    required String doctorName,
    String? profilePicture,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: profilePicture != null
            ? NetworkImage(profilePicture)
            : const AssetImage('assets/images/doctor_placeholder.png')
                as ImageProvider,
      ),
      title: Text(doctorName),
      subtitle: Text(message),
      trailing: Text(time),
    );
  }

  String formatTime(DateTime dateTime) {
    // Format the DateTime to a string (e.g., '2m ago', '1h ago')
    // Implement your formatting logic here
    return ''; // Placeholder
  }
}
