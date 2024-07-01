import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Stream<List<Map<String, dynamic>>> fetchRooms() {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  return firestore
      .collection('rooms')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          List<dynamic>? blockedUsers = data['blockedUsers'];
          if (blockedUsers != null && blockedUsers.contains(userId)) {
            return null; // Exclude this room
          }
          return {
            'roomName': data['roomName'],
            'description': data['description'],
            'roomId': data['roomId'],
            'createdAt': data['createdAt'],
            'interests': List<String>.from(data['interests']),
            'participants': List<String>.from(data['participants']),
            'channelId': data['channelId'],
          };
        })
        .where((room) => room != null)
        .cast<Map<String, dynamic>>()
        .toList();
  });
}
