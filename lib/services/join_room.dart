import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/joinRoom/join_room.dart';

Future<void> joinRoom(String roomName, String userId, BuildContext context, String description) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Query to find the room with the specified roomName and description
    QuerySnapshot querySnapshot = await firestore.collection('rooms')
      .where('roomName', isEqualTo: roomName)
      .where('description', isEqualTo: description)
      .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentReference roomRef = querySnapshot.docs.first.reference;

      // Update the room's participants list
      await roomRef.update({
        'participants': FieldValue.arrayUnion([userId])
      });

      // Fetch user details from Google account
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userName = user.displayName ?? 'Unknown User';
        String userImage = user.photoURL ?? 'https://example.com/default_image.jpg';
        String userRole = 'Participant'; // or whatever role you want to assign

        // Create a subcollection named 'joinedUsers' under the room document
        DocumentReference joinedUserRef = roomRef.collection('joinedUsers').doc(userId);
        
        // Add a document with the user's details
        user.uid == 'w44C44KnLpYgcaaLqah2CFG4QU93' ?
        await joinedUserRef.set({
          'name': userName,
          'image': userImage,
          'role': 'Admin'
        }):
         await joinedUserRef.set({
          'name': userName,
          'image': userImage,
          'role': userRole
        });


        // Navigate to the RoomScreen
        CustomNavigator().pushTo(context, RoomScreen(roomName: roomName, roomDesc: description));
        print("User added to room successfully!");
      } else {
        print("No user is currently signed in.");
      }
    } else {
      print("Room not found");
    }
  } catch (e) {
    print("Error joining room: $e");
  }
}
