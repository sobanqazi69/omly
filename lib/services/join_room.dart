import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

    // Fetch user details from Google account
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String displayName = user.displayName ?? 'Unknown User';
      String userImage =
          userr?.image ?? 'https://example.com/default_image.jpg';
      String username = userr?.username ?? displayName;

      // Check if the user has an existing role stored
      DocumentReference roleRef = roomRef.collection('userRoles').doc(userId);
      DocumentSnapshot roleDoc = await roleRef.get();

      String userRole = 'Participant'; // Default role
      if (roleDoc.exists) {
        userRole = roleDoc['role'];
      }

      // Add or update the user's document in the joinedUsers subcollection
      DocumentReference joinedUserRef = roomRef.collection('joinedUsers').doc(userId);
      await joinedUserRef.set({
        'name': displayName,
        'image': userImage,
        'role': userRole,
        'username': username
      });

      // Update the room's participants list
      await roomRef.update({
        'participants': FieldValue.arrayUnion([userId])
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

