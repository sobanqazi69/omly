import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchRooms() async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('rooms')
      .orderBy('createdAt', descending: true) // Order by 'createdAt' in descending order
      .get();

    List<Map<String, dynamic>> rooms = snapshot.docs.map((doc) {
      return {
        'roomName': doc['roomName'],
        'description': doc['description'],
        'createdAt': doc['createdAt'],
        'interests': List<String>.from(doc['interests']),
                'participants': List<String>.from(doc['participants']),

      };
    }).toList();

    return rooms;
  } catch (e) {
    print("Error fetching rooms: $e");
    return [];
  }
}
