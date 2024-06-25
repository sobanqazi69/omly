import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkAndDeleteRoomIfEmpty(String roomId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);

    // Get the room document
    DocumentSnapshot roomDoc = await roomRef.get();
    if (!roomDoc.exists) {
      print('Room does not exist');
      return;
    }

    // Get the list of participants
    List<dynamic> participants = roomDoc.get('participants');
    
    // If no participants are left, delete the room document
    if (participants.isEmpty) {
      await roomRef.delete();       print('Room deleted because there are no participants left.');
    } else {
      print('Room still has participants.');
    }
  }
}
