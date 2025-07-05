import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final String roomId;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.roomId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'roomId': roomId,
        'timestamp': timestamp.toIso8601String(),
      };
    } catch (e) {
      print('Error converting ChatMessage to map: $e');
      rethrow;
    }
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    try {
      return ChatMessage(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        message: map['message'] ?? '',
        roomId: map['roomId'] ?? '',
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
    } catch (e) {
      print('Error creating ChatMessage from map: $e');
      rethrow;
    }
  }

  factory ChatMessage.fromSnapshot(DocumentSnapshot snapshot) {
    try {
      final data = snapshot.data() as Map<String, dynamic>;
      return ChatMessage.fromMap({
        'id': snapshot.id,
        ...data,
      });
    } catch (e) {
      print('Error creating ChatMessage from snapshot: $e');
      rethrow;
    }
  }
} 