class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final String? senderName;
  final String? senderProfilePicture;
  final String? receiverName;
  final String? receiverProfilePicture;
  final String? messageType;
  final int unreadCount;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.isRead,
    this.senderName,
    this.senderProfilePicture,
    this.receiverName,
    this.receiverProfilePicture,
    this.messageType,
    this.unreadCount = 0,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    String? processImageUrl(String? url) {
      if (url == null) return null;
      if (url.startsWith('https://firebasestorage.googleapis.com')) {
        return url; // Return Firebase URLs as-is
      }
      if (url.startsWith('assets/')) {
        return url; // Return asset paths as-is
      }
      return 'assets/$url'; // Add assets/ prefix only if needed
    }

    return Message(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      message: map['message'],
      image: map['image'], // Don't process the image URL for chat images
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isRead: map['is_read'] == 1,
      senderName: map['sender_name'],
      senderProfilePicture: processImageUrl(map['sender_profile_picture']) ??
          'assets/images/doctor_placeholder.png',
      receiverName: map['receiver_name'],
      receiverProfilePicture:
          processImageUrl(map['receiver_profile_picture']) ??
              'assets/images/doctor_placeholder.png',
      messageType:
          map['message_type'] ?? (map['image'] != null ? 'image' : 'text'),
      unreadCount: map['unread_count'] ?? 0,
    );
  }
}
