import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:live_13/constants/selected_tags.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/services/delete_room.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/views/roomScreens/room_screen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';


Future<void> leaveRoom(String userId, BuildContext context, String roomId, String userRole) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    final roomService = RoomService();

    QuerySnapshot querySnapshot = await firestore.collection('rooms')
      .where('roomId', isEqualTo: roomId)
      .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentReference roomRef = querySnapshot.docs.first.reference;

      // Store the user's role before removing the document
      DocumentReference userDocRef = roomRef.collection('joinedUsers').doc(userId);
      DocumentSnapshot userDoc = await userDocRef.get();
      if (userDoc.exists) {
        String userRole = userDoc['role'];
        await firestore.collection('rooms').doc(roomId).collection('userRoles').doc(userId).set({
          'role': userRole,
        });
      }

      // Remove the user from the participants list
      await roomRef.update({
        'participants': FieldValue.arrayRemove([userId])
      });

      // Delete the user's document from the 'joinedUsers' subcollection
      await roomRef.collection('joinedUsers').doc(userId).delete();

      // Navigate to the appropriate screen based on the user role
      if (userRole == 'Admin') {
        CustomNavigator().pushReplacement(context, AdminScreen());
      } else {
        CustomNavigator().pushReplacement(context, UserScreen());
      }

      print("User removed from room successfully!");
      roomService.checkAndDeleteRoomIfEmpty(roomId);
    } else {
      print("Room not found");
    }
  } catch (e) {
    print("Error leaving room: $e");
  }
}
