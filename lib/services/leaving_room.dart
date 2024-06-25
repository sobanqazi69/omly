import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:live_13/constants/selected_tags.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/services/delete_room.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/views/roomScreens/room_screen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

Future<void> leaveRoom( String userId, BuildContext context, String roomiD , String userRole) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
                          final roomService = RoomService();

    
    QuerySnapshot querySnapshot = await firestore.collection('rooms')
      .where('roomId', isEqualTo: roomiD)
      .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentReference roomRef = querySnapshot.docs.first.reference;

      // Remove the user from the participants list
      await roomRef.update({
        'participants': FieldValue.arrayRemove([userId])
      });

      // Delete the user's document from the 'joinedUsers' subcollection
      await roomRef.collection('joinedUsers').doc(userId).delete();

      // Navigate to the appropriate screen based on the user role
      // if (userId == 'w44C44KnLpYgcaaLqah2CFG4QU93') {
      //   CustomNavigator().pushTo(context, AdminScreen());
      // } else {
      //   CustomNavigator().pushTo(context, UserScreen());
      // }
     if (userRole == 'Admin') {
            CustomNavigator().pushReplacement(context, AdminScreen());
          } else {
            CustomNavigator().pushReplacement(context, UserScreen());
          }
      
      print("User removed from room successfully!");
        roomService.checkAndDeleteRoomIfEmpty(roomiD);

    } else {
      print("Room not found");
    }
  } catch (e) {
    print("Error leaving room: $e");
  }
}
