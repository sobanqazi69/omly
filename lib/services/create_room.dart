// utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addRoomData(String roomName, String description, List<String> interests) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    Map<String, dynamic> roomData = {
      'roomName': roomName,
      'description': description,
      'interests': interests,
      'createdAt': FieldValue.serverTimestamp(),
      'participants': [],
      'channelId' : null
    };

      

    await firestore.collection('rooms').add(roomData);

    print("Room added successfully!");
  } catch (e) {
    print("Error adding room: $e");
  }
}
