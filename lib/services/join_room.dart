import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/roomScreens/room_screen.dart';

Future<void> joinRoom(String roomName, String userId, BuildContext context,
    String description, String roomId, String channelId) async {
  try {
    UserModel? userr = userData.currentUser;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Query to find the room with the specified roomId
    QuerySnapshot querySnapshot = await firestore
        .collection('rooms')
        .where('roomId', isEqualTo: roomId)
        .get();

    DocumentReference roomRef = firestore.collection('rooms').doc(roomId);

    // Update the room's participants list
    await roomRef.update({
      'participants': FieldValue.arrayUnion([userId])
    });

    // Fetch user details from Google account
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String displayName = user.displayName ?? 'Unknown User';
      String userImage =
          user.photoURL ?? 'https://example.com/default_image.jpg';
      String userRole = 'Participant'; // or whatever role you want to assign
      String username = userr?.username ?? displayName;

      // Create a subcollection named 'joinedUsers' under the room document
      DocumentReference joinedUserRef =
          roomRef.collection('joinedUsers').doc(userId);

      // Add a document with the user's details
      await joinedUserRef.set({
        'name': displayName,
        'image': userImage,
        'role': userRole,
        'username': username
      });

      // Navigate to the RoomScreen
      CustomNavigator().pushReplacement(
          context,
          RoomScreen(
            roomName: roomName,
            roomDesc: description,
            roomId: roomId,
            channelId: channelId,
          ));
      print("User added to room successfully!");
    } else {
      print("No user is currently signed in.");
    }
  } catch (e) {
    print("Error joining room: $e");
  }
}
