import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

void deleteRoomAndRedirect(BuildContext context, String roomId, String userId, String userRole) async {
  try {
    // Delete main document
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
    
    // Delete joinedUsers subcollection document
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('joinedUsers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();

    // Delete speakRequests subcollection document
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('speakRequests')
        .doc(userId)
        .delete();

    // Check user role and redirect accordingly
    if (userRole == 'Admin') {
      CustomNavigator().pushTo(context, AdminScreen());
    } else {
      CustomNavigator().pushTo(context, UserScreen());
    }
    Get.snackbar('OoPs', 'Room Has Been Deleted By Admin');
  } catch (e) {
    print('Error deleting documents: $e');
    // Handle the error appropriately in your app
  }
}
