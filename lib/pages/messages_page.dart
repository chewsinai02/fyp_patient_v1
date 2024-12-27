import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  final int patientId;
  const MessagesPage({super.key, required this.patientId});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Message>>(
        future: DatabaseService.instance.getLatestMessages(widget.patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final message = messages[index];
              final doctorId = message.senderId == widget.patientId
                  ? message.receiverId
                  : message.senderId;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                color: message.unreadCount > 0 &&
                        message.receiverId == widget.patientId
                    ? Colors.blue.shade50
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: message.unreadCount > 0 &&
                            message.receiverId == widget.patientId
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.1),
                    width: message.unreadCount > 0 &&
                            message.receiverId == widget.patientId
                        ? 2
                        : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    try {
                      // Mark messages as read if there are unread messages
                      if (message.unreadCount > 0 &&
                          message.receiverId == widget.patientId) {
                        await DatabaseService.instance.markMessageAsRead(
                          message.senderId, // Doctor's ID (sender)
                          widget.patientId, // Current patient's ID (receiver)
                        );

                        // Refresh the messages list immediately
                        setState(() {});
                      }

                      // Then navigate to chat
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            patientId: widget.patientId,
                            otherUserId: doctorId,
                          ),
                        ),
                      ).then((_) {
                        setState(() {}); // Refresh again when returning
                      });
                    } catch (e) {
                      print('Error updating message status: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: message.senderId ==
                                      widget.patientId
                                  ? (message.receiverProfilePicture != null
                                      ? AssetImage(
                                          message.receiverProfilePicture!)
                                      : const AssetImage(
                                              'assets/images/doctor_placeholder.png')
                                          as ImageProvider)
                                  : (message.senderProfilePicture != null
                                      ? AssetImage(
                                          message.senderProfilePicture!)
                                      : const AssetImage(
                                              'assets/images/doctor_placeholder.png')
                                          as ImageProvider),
                              backgroundColor: Colors.deepPurple.shade50,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    message.senderId == widget.patientId
                                        ? message.receiverName ?? 'Unknown'
                                        : message.senderName ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: message.unreadCount > 0 &&
                                              message.receiverId ==
                                                  widget.patientId
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 16,
                                      color: message.unreadCount > 0 &&
                                              message.receiverId ==
                                                  widget.patientId
                                          ? Colors.blue
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    formatTime(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: message.unreadCount > 0 &&
                                              message.receiverId ==
                                                  widget.patientId
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: message.unreadCount > 0 &&
                                              message.receiverId ==
                                                  widget.patientId
                                          ? Colors.blue
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      message.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: message.unreadCount > 0 &&
                                                message.receiverId ==
                                                    widget.patientId
                                            ? Colors.black87
                                            : Colors.grey[600],
                                        fontWeight: message.unreadCount > 0 &&
                                                message.receiverId ==
                                                    widget.patientId
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (message.unreadCount > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message.unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
