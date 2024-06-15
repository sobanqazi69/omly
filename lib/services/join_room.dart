import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/roomScreens/room_screen.dart';

Future<void> joinRoom(String roomName, String userId, BuildContext context,
    String description , String roomId) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Query to find the room with the specified roomName and description
    QuerySnapshot querySnapshot = await firestore
        .collection('rooms')
        .where('roomId', isEqualTo: roomId)
        .get();

      DocumentReference roomRef =FirebaseFirestore.instance.collection('rooms').doc(roomId);

 FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
          'participants': FieldValue.arrayUnion([userId])

 });
      // Update the room's participants list
     

      // Fetch user details from Google account
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userName = user.displayName ?? 'Unknown User';
        String userImage =
            user.photoURL ?? 'https://example.com/default_image.jpg';
        String userRole = 'Participant'; // or whatever role you want to assign

        // Create a subcollection named 'joinedUsers' under the room document
        DocumentReference joinedUserRef =
            roomRef.collection('joinedUsers').doc(userId);

        // Add a document with the user's details
       await joinedUserRef
                .set({'name': userName, 'image': userImage, 'role': userRole});

        // String channelId = generateChannelId();

        // updateChannelIdIfNull(roomName, description, channelId);

        // Navigate to the RoomScreen
        CustomNavigator().pushTo(
            context, RoomScreen(roomName: roomName, roomDesc: description ,roomId: roomId,));
        print("User added to room successfully!");
      } else {
        print("No user is currently signed in.");
      }
     
  } catch (e) {
    print("Error joining room: $e");
  }
}





