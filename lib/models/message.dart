import '../utils/time_utils.dart';

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final int unreadCount;
  final String? senderName;
  final String? senderProfilePicture;
  final String? receiverName;
  final String? receiverProfilePicture;
  final String messageType; // 'text', 'image', or 'file'

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.isRead,
    this.unreadCount = 0,
    this.senderName,
    this.senderProfilePicture,
    this.receiverName,
    this.receiverProfilePicture,
    this.messageType = 'text',
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    // Convert timestamps to KL time
    final createdAt = TimeUtils.parseFromDatabase(map['created_at'].toString());
    final updatedAt = TimeUtils.parseFromDatabase(map['updated_at'].toString());

    return Message(
      id: map['id'] as int,
      senderId: map['sender_id'] as int,
      receiverId: map['receiver_id'] as int,
      message: map['message'] as String,
      image: map['image'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isRead: (map['is_read'] as int? ?? 0) == 0,
      unreadCount: map['unread_count'] as int? ?? 0,
      senderName: map['sender_name'] as String?,
      senderProfilePicture: map['sender_profile_picture'] as String?,
      receiverName: map['receiver_name'] as String?,
      receiverProfilePicture: map['receiver_profile_picture'] as String?,
      messageType: map['message_type'] as String? ?? 'text',
    );
  }

  String getFileIcon() {
    if (image == null) return 'bi-file-earmark';

    final filename = image!.toLowerCase();
    if (filename.endsWith('.pdf')) return 'bi-file-earmark-pdf';
    if (filename.endsWith('.doc') || filename.endsWith('.docx'))
      return 'bi-file-earmark-word';
    if (filename.endsWith('.xls') || filename.endsWith('.xlsx'))
      return 'bi-file-earmark-excel';
    if (filename.endsWith('.ppt') || filename.endsWith('.pptx'))
      return 'bi-file-earmark-ppt';
    if (filename.endsWith('.zip') || filename.endsWith('.rar'))
      return 'bi-file-earmark-zip';
    if (filename.endsWith('.txt')) return 'bi-file-earmark-text';
    return 'bi-file-earmark';
  }

  bool get isImage {
    if (image == null) return false;
    final lowercaseUrl = image!.toLowerCase();

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
      } catch (e) {
        print('Error parsing URL: $e');
      }
    }

    return false;
  }

  String getFileName() {
    if (image == null) return '';
    final uri = Uri.parse(image!);
    final path = uri.path;
    final filename = path.split('/').last;
    // Remove timestamp prefix if exists (file_1234567890_filename.ext)
    final parts = filename.split('_');
    if (parts.length > 2) {
      return parts.sublist(2).join('_');
    }
    return filename;
  }
}
