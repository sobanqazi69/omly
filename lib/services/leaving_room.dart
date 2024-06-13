import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:live_13/constants/selected_tags.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

Future<void> leaveRoom(String roomName, String userId, BuildContext context, String description) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    QuerySnapshot querySnapshot = await firestore.collection('rooms')
      .where('roomName', isEqualTo: roomName)
      .where('description', isEqualTo: description)
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
      if (userId == 'w44C44KnLpYgcaaLqah2CFG4QU93') {
        CustomNavigator().pushTo(context, AdminScreen());
      } else {
        CustomNavigator().pushTo(context, UserScreen());
      }
      
      print("User removed from room successfully!");
    } else {
      print("Room not found");
    }
  } catch (e) {
    print("Error leaving room: $e");
  }
}
