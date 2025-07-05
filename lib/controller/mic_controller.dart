import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_13/views/roomScreens/widgets/request_mic_sheet.dart';

class MicController extends GetxController {
  final RxBool isMuted = true.obs;
  final RxBool isMicOn = false.obs;
  final RxBool isRequested = false.obs;
  RtcEngine? _engine;

  void setEngine(RtcEngine engine) {
    _engine = engine;
  }

  Future<void> toggleMic() async {
    try {
      if (_engine == null) {
        print('Error: Agora engine not initialized');
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(Get.arguments['roomId'])
          .collection('joinedUsers')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String;

      if (userRole == 'Participant') {
        // Show request bottom sheet for participants
        Get.bottomSheet(
          RequestMicSheet(onRequestMic: _sendMicRequest),
          isScrollControlled: true,
        );
      } else {
        // Direct mic toggle for admins and owners
        isMuted.value = !isMuted.value;
        isMicOn.value = !isMuted.value;
        await _engine!.muteLocalAudioStream(isMuted.value);
        
        // Update user's mute status in Firestore
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(Get.arguments['roomId'])
            .collection('joinedUsers')
            .doc(currentUser.uid)
            .update({'isMuted': isMuted.value});
      }
    } catch (e) {
      print('Error toggling mic: $e');
    }
  }

  Future<void> _sendMicRequest() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final roomId = Get.arguments['roomId'];
      
      // Check if request already exists
      final existingRequest = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('speakRequests')
          .doc(currentUser.uid)
          .get();

      if (existingRequest.exists) {
        Get.snackbar(
          'Request Pending',
          'Your microphone request is already pending',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Add new request
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('speakRequests')
          .doc(currentUser.uid)
          .set({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Request Sent',
        'Your request has been sent to the room admin',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      isRequested.value = true;
    } catch (e) {
      print('Error sending mic request: $e');
      Get.snackbar(
        'Error',
        'Failed to send request. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method to handle mic permission granted by admin
  Future<void> handleMicPermissionGranted() async {
    try {
      if (_engine == null) return;

      isMuted.value = false;
      isMicOn.value = true;
      isRequested.value = false;
      await _engine!.muteLocalAudioStream(false);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update user's role and mute status
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(Get.arguments['roomId'])
          .collection('joinedUsers')
          .doc(currentUser.uid)
          .update({
        'role': 'Speaker',
        'isMuted': false,
      });

      // Remove the speak request
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(Get.arguments['roomId'])
          .collection('speakRequests')
          .doc(currentUser.uid)
          .delete();

      Get.snackbar(
        'Permission Granted',
        'You can now speak in the room',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error handling mic permission: $e');
    }
  }
}
