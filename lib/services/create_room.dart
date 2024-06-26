// utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/roomScreens/room_screen.dart';

Future<void> addRoomData(String roomName, String description,
    List<String> interests, BuildContext context) async {
  try {
    Get.back();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    UserModel? userr = userData.currentUser;

    String channelId = generateChannelId();

    // Initial room data without roomId
    Map<String, dynamic> roomData = {
      'roomName': roomName,
      'description': description,
      'interests': interests,
      'createdAt': FieldValue.serverTimestamp(),
      'participants': [],
      'channelId': channelId,
      'password': '123456'
    };

    // Add the document to Firestore and get the DocumentReference
    DocumentReference docRef =
        await firestore.collection('rooms').add(roomData);

    // Get the document ID
    String roomId = docRef.id;

    // Update the document with the roomId
    await docRef.update({'roomId': roomId});

    User? user = FirebaseAuth.instance.currentUser;
    DocumentReference roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(roomId);

    if (user != null) {
      String userName = user.displayName ?? 'Unknown User';
      String userImage =
          user.photoURL ?? 'https://example.com/default_image.jpg';
      String userRole = 'Participant'; // or whatever role you want to assign

      DocumentReference joinedUserRef =
          roomRef.collection('joinedUsers').doc(user.uid);

      // Add a document with the user's details
      await joinedUserRef
          .set({'name': userName, 'image': userImage, 'role': 'Admin' , 'username': userr!.username});

      // String channelId = generateChannelId();

      FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'participants': FieldValue.arrayUnion([user.uid])
      });
      // updateChannelIdIfNull(roomName, description, channelId);

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
    }

    CustomNavigator().pushReplacement(
        context,
        RoomScreen(
          roomName: roomName,
          roomDesc: description,
          roomId: roomId,
           channelId: channelId,
        ));
    print("Room added successfully with ID: $roomId");
  } catch (e) {
    print("Error adding room: $e");
  }
}

String generateChannelId() {
  // Generate a random channel ID (you can customize this function as needed)
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String geenrateRoomId() {
  // Generate a random channel ID (you can customize this function as needed)
  return DateTime.now().microsecondsSinceEpoch.toString();
}
