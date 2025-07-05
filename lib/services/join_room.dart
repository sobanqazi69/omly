import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/roomScreens/room_screen.dart';

class JoinRoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> joinRoom(String roomId, BuildContext context, {int maxRetries = 3}) async {
    int retryCount = 0;
    Duration backoff = Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        // Check if room exists
        final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
        if (!roomDoc.exists) {
          Get.snackbar(
            'Error',
            'Room not found',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }

        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          Get.snackbar(
            'Error',
            'User not authenticated',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }

        // Get user data
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (!userDoc.exists) {
          Get.snackbar(
            'Error',
            'User profile not found',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }

        final userData = userDoc.data() as Map<String, dynamic>;

        // Check if user is already in room
        final joinedUserDoc = await _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('joinedUsers')
            .doc(currentUser.uid)
            .get();

        if (joinedUserDoc.exists) {
          return true; // User is already in the room
        }

        // Join room with transaction to ensure atomicity
        await _firestore.runTransaction((transaction) async {
          // Get fresh room data within transaction
          final freshRoomDoc = await transaction.get(_firestore.collection('rooms').doc(roomId));
          
          if (!freshRoomDoc.exists) {
            throw Exception('Room no longer exists');
          }

          // Add user to joinedUsers collection
          transaction.set(
            _firestore
                .collection('rooms')
                .doc(roomId)
                .collection('joinedUsers')
                .doc(currentUser.uid),
            {
              'userId': currentUser.uid,
              'userName': userData['userName'] ?? 'Anonymous',
              'profileImage': userData['profileImage'] ?? '',
              'joinedAt': FieldValue.serverTimestamp(),
              'role': 'Participant',
              'isOwner': false,
              'isMuted': true,
              'seat': -1,
            },
          );

          // Update room members count
          transaction.update(
            _firestore.collection('rooms').doc(roomId),
            {'membersCount': FieldValue.increment(1)},
          );
        });

        return true;

      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          Get.snackbar(
            'Error',
            'Failed to join room. Please try again later.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          print('Error joining room after $maxRetries retries: $e');
          return false;
        }

        // Wait with exponential backoff before retrying
        await Future.delayed(backoff);
        backoff *= 2; // Double the backoff duration for next retry
        print('Retrying join room attempt $retryCount after ${backoff.inSeconds}s delay');
      }
    }

    return false;
  }
}

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

