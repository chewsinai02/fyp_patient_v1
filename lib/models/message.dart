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
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      message: map['message'],
      image: map['image'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isRead: map['is_read'] == 1,
      senderName: map['sender_name'],
      senderProfilePicture: map['sender_profile_picture'],
      receiverName: map['receiver_name'],
      receiverProfilePicture: map['receiver_profile_picture'],
      messageType: map['message_type'] ?? 'text',
    );
  }
}
