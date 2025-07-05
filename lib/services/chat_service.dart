import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message to a room
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    try {
      final timestamp = DateTime.now();
      final messageDoc = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      final chatMessage = ChatMessage(
        id: messageDoc.id,
        senderId: senderId,
        senderName: senderName,
        message: message,
        roomId: roomId,
        timestamp: timestamp,
      );

      await messageDoc.set(chatMessage.toMap());
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Stream of messages for a specific room
  Stream<List<ChatMessage>> getMessages(String roomId) {
    try {
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(100) // Limit to last 100 messages
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessage.fromSnapshot(doc))
            .toList();
      });
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  // Delete a message
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }
} 