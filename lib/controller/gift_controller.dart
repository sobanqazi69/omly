import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/controller/wallet_controller.dart';

class GiftController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Reactive variables
  var showGiftOverlay = false.obs;
  var currentGift = Rxn<String>();
  var giftSenderName = Rxn<String>();
  var lastProcessedGiftId = Rxn<String>();
  
  Timer? giftTimer;
  StreamSubscription? giftSubscription;
  String? currentRoomId;

  void initializeGiftListener(String roomId) {
    try {
      currentRoomId = roomId;
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      
      // Cancel any existing subscription
      giftSubscription?.cancel();
      
      // Listen to gift messages
      giftSubscription = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('giftMessages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        
        if (snapshot.docs.isNotEmpty) {
          var giftDoc = snapshot.docs.first;
          var data = giftDoc.data();
          String senderId = data['senderId'] ?? '';
          String giftId = giftDoc.id;
          
          // Show gift if we haven't processed this gift yet
          if (lastProcessedGiftId.value != giftId && !showGiftOverlay.value) {
            
            lastProcessedGiftId.value = giftId;
            bool isSender = senderId == currentUserId;
            _showGift(
              data['giftAsset'] ?? '',
              data['senderName'] ?? 'Someone',
              isSender
            );
          }
        }
      });
    } catch (e) {
      print('Error initializing gift listener: $e');
    }
  }

  void _showGift(String giftAsset, String senderName, bool isSender) {
    try {
      // Cancel any existing timer
      giftTimer?.cancel();
      
      // Show gift overlay
      showGiftOverlay.value = true;
      currentGift.value = giftAsset;
      
      // Set different message for sender vs receiver
      if (isSender) {
        giftSenderName.value = "You sent this gift! 🎉";
      } else {
        giftSenderName.value = senderName;
      }
      
      // Hide gift after 2 seconds
      giftTimer = Timer(Duration(seconds: 2), () {
        hideGift();
      });
    } catch (e) {
      print('Error showing gift: $e');
    }
  }

  void hideGift() {
    try {
      showGiftOverlay.value = false;
      currentGift.value = null;
      giftSenderName.value = null;
      giftTimer?.cancel();
    } catch (e) {
      print('Error hiding gift: $e');
    }
  }

  Future<void> sendGift(String giftName, String giftAsset, String roomId, int giftCost) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String senderName = userData.currentUser?.username ?? 'Someone';
      
      // Check if user has enough coins
      WalletController walletController = Get.find<WalletController>();
      if (walletController.userCoins.value < giftCost) {
        Get.snackbar(
          'Insufficient Coins',
          'You need $giftCost coins to send this gift. Purchase more coins from your wallet.',
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // Deduct coins first
      await walletController.spendCoins(giftCost, 'Gift: $giftName');
      
      // Send gift to Firestore
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('giftMessages')
          .add({
        'giftName': giftName,
        'giftAsset': giftAsset,
        'senderName': senderName,
        'senderId': userId,
        'giftCost': giftCost,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Gift sent: $giftName by $senderName (cost: $giftCost coins)');
      
      // Show success feedback
      Get.snackbar(
        'Gift Sent! 🎁',
        'You sent a $giftName for $giftCost coins',
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error sending gift: $e');
      Get.snackbar(
        'Error',
        'Failed to send gift',
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    giftTimer?.cancel();
    giftSubscription?.cancel();
    super.onClose();
  }
} 