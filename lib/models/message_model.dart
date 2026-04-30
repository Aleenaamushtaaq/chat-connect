import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final List<String> deletedBy;
  final String? repliedMessage;
  final String? repliedTo;
  final String? repliedMessageType;
  final bool isPinned;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.deletedBy = const [],
    this.repliedMessage,
    this.repliedTo,
    this.repliedMessageType,
    this.isPinned = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedBy: List<String>.from(data['deletedBy'] ?? []),
      isPinned: data['isPinned'] ?? false,

      repliedMessage: data['repliedMessage'],
      repliedTo: data['repliedTo'],
      repliedMessageType: data['repliedMessageType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'deletedBy': deletedBy,
      'isPinned': isPinned,
      'repliedMessage': repliedMessage,
      'repliedTo': repliedTo,
      'repliedMessageType': repliedMessageType,
    };
  }
}