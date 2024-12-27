import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../widgets/message_input.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  final int patientId;
  final int otherUserId;
  final bool isFromMainLayout;

  const ChatPage({
    super.key,
    required this.patientId,
    required this.otherUserId,
    this.isFromMainLayout = false,
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
    print('=== CHAT PAGE INITIALIZED ===');
    print('Patient ID: ${widget.patientId}');
    print('Doctor ID: ${widget.otherUserId}');
    _messagesFuture = _loadMessages();

    // Mark messages as read when entering chat
    DatabaseService.instance.markMessageAsRead(
      widget.otherUserId, // Doctor's ID (sender)
      widget.patientId, // Current patient's ID (receiver)
    );
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleImageMessage(String imageUrl, String caption) async {
    try {
      await DatabaseService().sendMessage(
        senderId: widget.patientId,
        receiverId: widget.otherUserId,
        message: caption,
        image: imageUrl,
        messageType: 'image',
      );
      setState(() {
        _messagesFuture = _loadMessages();
      });
    } catch (e) {
      print('Error sending image message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: widget.isFromMainLayout
            ? null // Hide back button if from MainLayout
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: FutureBuilder<List<Message>>(
          future: _messagesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final message = snapshot.data!.first;
              final isOtherUserSender = message.senderId != widget.patientId;
              final otherUserName =
                  isOtherUserSender ? message.senderName : message.receiverName;
              final otherUserProfilePicture = isOtherUserSender
                  ? message.senderProfilePicture
                  : message.receiverProfilePicture;

              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: otherUserProfilePicture != null
                        ? AssetImage(otherUserProfilePicture)
                        : const AssetImage(
                            'assets/images/doctor_placeholder.png',
                          ) as ImageProvider,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUserName ?? 'Chat',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const Text(
              'Chat',
              style: TextStyle(color: Colors.white),
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: isPatient
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isPatient) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: message.senderProfilePicture !=
                                      null
                                  ? AssetImage(message.senderProfilePicture!)
                                  : const AssetImage(
                                          'assets/images/doctor_placeholder.png')
                                      as ImageProvider,
                              backgroundColor: Colors.deepPurple.shade100,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: message.senderId == widget.patientId
                                    ? Colors.deepPurple
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft:
                                      Radius.circular(isPatient ? 20 : 0),
                                  bottomRight:
                                      Radius.circular(isPatient ? 0 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isPatient
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  _buildMessageContent(message),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTime(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isPatient
                                          ? Colors.white70
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isPatient) const SizedBox(width: 24),
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
            onSendImage: _handleImageMessage,
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

  Widget _buildMessageContent(Message message) {
    if (message.messageType == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                message.message,
                style: TextStyle(
                  color: message.senderId == widget.patientId
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.image ?? '',
              width: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 150,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),
        ],
      );
    } else {
      return Text(
        message.message,
        style: TextStyle(
          color: message.senderId == widget.patientId
              ? Colors.white
              : Colors.black87,
          fontSize: 15,
        ),
      );
    }
  }
}
