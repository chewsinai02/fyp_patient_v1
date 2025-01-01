import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../widgets/message_input.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/adaptive_image.dart';
import '../utils/time_utils.dart';
import '../services/notification_service.dart';

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

    // Add scroll listener for loading more messages
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });

    // Mark messages as read when entering chat
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await DatabaseService.instance.markMessageAsRead(
        widget.otherUserId, // Sender's ID
        widget.patientId, // Current user's ID (receiver)
      );
      // Refresh messages to update read status
      setState(() {
        _messagesFuture = _loadMessages();
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Add this to handle new messages
  void _handleNewMessage() async {
    await _markMessagesAsRead();
    setState(() {
      _messagesFuture = _loadMessages();
    });
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
        0,
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

  void _handleFileMessage(String fileUrl, String fileName) async {
    try {
      await DatabaseService().sendMessage(
        senderId: widget.patientId,
        receiverId: widget.otherUserId,
        message: fileName,
        image: fileUrl,
        messageType: 'file',
      );
      setState(() {
        _messagesFuture = _loadMessages();
      });
    } catch (e) {
      print('Error sending file message: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    // Implement pagination logic here if needed
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
                    backgroundColor: Colors.white,
                    child: AdaptiveImage(
                      imageUrl: otherUserProfilePicture,
                      fallbackAsset: 'assets/images/doctor_placeholder.png',
                      circle: true,
                      width: 40,
                      height: 40,
                    ),
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
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
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
                              backgroundColor: Colors.deepPurple.shade100,
                              child: AdaptiveImage(
                                imageUrl: message.senderProfilePicture,
                                fallbackAsset:
                                    'assets/images/doctor_placeholder.png',
                                circle: true,
                                width: 32,
                                height: 32,
                              ),
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
                                    TimeUtils.getTimeAgo(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          message.senderId == widget.patientId
                                              ? Colors.white70
                                              : Colors.grey[600],
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
            onSendFile: _handleFileMessage,
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
    if (message.messageType == 'image' || message.messageType == 'file') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.message.isNotEmpty && message.message != '[Image]')
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
          if (message.image != null)
            if (_isImageUrl(message.image!))
              // For images - show preview directly
              GestureDetector(
                onTap: () => _showFullScreenImage(context, message.image!),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                    maxHeight: 200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message.image!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              _buildFileDownloadButton(message),
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

  bool _isImageUrl(String url) {
    final lowercaseUrl = url.toLowerCase();

    // Check file extensions
    final extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    if (extensions.any((ext) => lowercaseUrl.endsWith(ext))) {
      return true;
    }

    // Check for Firebase Storage image URLs
    if (lowercaseUrl.contains('firebasestorage.googleapis.com')) {
      if (lowercaseUrl.contains('image/') ||
          lowercaseUrl.contains('/images/') ||
          lowercaseUrl.contains('chat_images/')) {
        return true;
      }
    }

    // Check for direct image URLs
    if (lowercaseUrl.contains('image/') ||
        lowercaseUrl.contains('/images/') ||
        Uri.tryParse(lowercaseUrl)?.hasAbsolutePath == true) {
      try {
        // Try to check if URL ends with image extension
        final uri = Uri.parse(lowercaseUrl);
        final path = uri.path.toLowerCase();
        if (extensions.any((ext) => path.endsWith(ext))) {
          return true;
        }

        // Additional check for content-type in query parameters
        if (uri.queryParameters.containsKey('type')) {
          final type = uri.queryParameters['type']!.toLowerCase();
          if (type.startsWith('image/')) {
            return true;
          }
        }
      } catch (e) {
        print('Error parsing URL: $e');
      }
    }

    // Try to validate URL by checking if it's a direct image link
    try {
      final uri = Uri.parse(url);
      if (uri.hasAbsolutePath &&
          !uri.path.endsWith('/') &&
          !uri.path.contains('.php') &&
          !uri.path.contains('.asp') &&
          !uri.path.contains('.html')) {
        final lastSegment = uri.pathSegments.last.toLowerCase();
        if (extensions.any((ext) => lastSegment.endsWith(ext))) {
          return true;
        }
      }
    } catch (e) {
      print('Error validating URL: $e');
    }

    return false;
  }

  Widget _buildFileDownloadButton(Message message) {
    final fileName = message.getFileName();
    final fileIcon = _getFileIcon(message.getFileIcon());
    final isPatient = message.senderId == widget.patientId;

    return InkWell(
      onTap: () => _downloadFile(message.image!, fileName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPatient ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPatient ? Colors.white24 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fileIcon,
              size: 24,
              color: isPatient ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isPatient ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to download',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPatient ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.download,
              size: 20,
              color: isPatient ? Colors.white70 : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Semi-transparent background
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
            // Image with InteractiveViewer
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      final result = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!result) {
        throw 'Could not launch URL';
      }
    } catch (e) {
      print('Error downloading file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getFileIcon(String iconName) {
    switch (iconName) {
      case 'bi-file-earmark-pdf':
        return Icons.picture_as_pdf;
      case 'bi-file-earmark-word':
        return Icons.description;
      case 'bi-file-earmark-excel':
        return Icons.table_chart;
      case 'bi-file-earmark-ppt':
        return Icons.slideshow;
      case 'bi-file-earmark-zip':
        return Icons.folder_zip;
      case 'bi-file-earmark-text':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
