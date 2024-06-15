import 'package:cloud_firestore/cloud_firestore.dart';

Stream<List<Map<String, dynamic>>> fetchRooms() {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  return firestore
      .collection('rooms')
      .orderBy('createdAt', descending: true) // Order by 'createdAt' in descending order
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return {
        'roomName': doc['roomName'],
        'description': doc['description'],
        'roomId': doc['roomId'],
        'createdAt': doc['createdAt'],
        'interests': List<String>.from(doc['interests']),
        'participants': List<String>.from(doc['participants']),
      };
    }).toList();
  });
}
