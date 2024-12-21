import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../widgets/message_input.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('=== CHAT PAGE INITIALIZED ===');
    print('Patient ID: ${widget.patientId}');
    print('Doctor ID: ${widget.otherUserId}');
    _messagesFuture = _loadMessages();
  }

  Future<List<Message>> _loadMessages() async {
    print('=== LOADING CHAT MESSAGES ===');
    print('Patient ID: ${widget.patientId}');
    print('Other User ID: ${widget.otherUserId}');

    if (widget.patientId <= 0 || widget.otherUserId <= 0) {
      print('Invalid user IDs detected:');
      print('Patient ID: ${widget.patientId}');
      print('Other User ID: ${widget.otherUserId}');
      throw Exception('Invalid user IDs');
    }

    try {
      final messages = await DatabaseService.instance
          .getMessagesBetweenUsers(widget.patientId, widget.otherUserId);

      print('Loaded ${messages.length} messages');
      if (messages.isEmpty) {
        print('No messages found between users');
      } else {
        print('First message: ${messages.first.message}');
        print('Last message: ${messages.last.message}');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      return messages;
    } catch (e, stackTrace) {
      print('Error loading messages: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
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
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _handleSendImage(File imageFile) async {
    try {
      print('=== HANDLING SEND IMAGE ===');
      print('Image file path: ${imageFile.path}');
      print('File exists: ${imageFile.existsSync()}');
      print('File size: ${await imageFile.length()} bytes');

      await DatabaseService.instance.sendMessage(
        senderId: widget.patientId,
        receiverId: widget.otherUserId,
        message: '📷 Image',
        imageFile: imageFile,
      );

      print('Message with image sent successfully');
      setState(() {
        _messagesFuture = _loadMessages();
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    } catch (e) {
      print('=== ERROR SENDING IMAGE ===');
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
        title: FutureBuilder<List<Message>>(
          future: _messagesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final otherUserName =
                  widget.patientId == snapshot.data!.first.senderId
                      ? snapshot.data!.first.receiverName
                      : snapshot.data!.first.senderName;
              return Text(
                otherUserName ?? 'Chat',
                style: const TextStyle(color: Colors.black87),
              );
            }
            return const Text(
              'Chat',
              style: TextStyle(color: Colors.black87),
            );
          },
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
                  print('Error in FutureBuilder: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nStart a conversation!',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final messages = snapshot.data!;
                print('Displaying ${messages.length} messages');

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  reverse: false,
                  itemBuilder: (context, index) {
                    final message = messages[index];
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
                              backgroundImage: AssetImage(
                                message.senderProfilePicture ??
                                    'assets/images/doctor_placeholder.png',
                              ),
                              backgroundColor: Colors.deepPurple.shade100,
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
                                  if (message.image != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        message.image!,
                                        width: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
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
          MessageInput(
            onSendMessage: _handleSendMessage,
            onSendImage: _handleSendImage,
          ),
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
