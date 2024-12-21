import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../widgets/message_input.dart';

class ChatPage extends StatefulWidget {
  final int patientId;
  final int otherUserId;

  const ChatPage({
    super.key,
    required this.patientId,
    required this.otherUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<List<Message>> _messagesFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  Future<List<Message>> _loadMessages() async {
    print(
        'Loading messages for patient ${widget.patientId} and other user ${widget.otherUserId}');
    final messages = await DatabaseService.instance
        .getMessagesBetweenUsers(widget.patientId, widget.otherUserId);
    print('Loaded ${messages.length} messages');
    return messages;
  }

  Future<void> _handleSendMessage(String text) async {
    try {
      await DatabaseService.instance.sendMessage(
        senderId: widget.patientId,
        receiverId: widget.otherUserId,
        message: text,
      );
      setState(() {
        _messagesFuture = _loadMessages();
      });
      // Scroll to bottom after sending message
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chat',
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Error loading messages: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  print('No messages found');
                  return const Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!;
                print('Displaying ${messages.length} messages');

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isPatient = message.senderId == widget.patientId;
                    print(
                        'Message ${index + 1}: ${message.message} - From: ${message.senderId}');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isPatient
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isPatient) ...[
                            CircleAvatar(
                              backgroundImage: message.senderProfilePicture !=
                                      null
                                  ? AssetImage(message.senderProfilePicture!)
                                  : const AssetImage(
                                          'assets/images/doctor_placeholder.png')
                                      as ImageProvider,
                              backgroundColor: Colors.deepPurple.shade100,
                              // Remove the child Text widget to eliminate the text
                              // child: Text(
                              //   message.senderName?[0] ?? '?',
                              //   style:
                              //       const TextStyle(color: Colors.deepPurple),
                              // ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPatient
                                    ? Colors.deepPurple
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: isPatient
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.message,
                                    style: TextStyle(
                                      color: isPatient
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTime(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPatient
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isPatient) const SizedBox(width: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(onSendMessage: _handleSendMessage),
        ],
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
