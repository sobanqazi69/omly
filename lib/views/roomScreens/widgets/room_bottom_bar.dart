import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/controller/wallet_controller.dart';
import 'package:live_13/services/speak_user_request.dart';

class RoomBottomBar extends StatelessWidget {
  final String roomId;
  final String userId;
  final String userRole;
  final bool isMicOn;
  final bool isOwner;
  final bool isUploadingImage;
  final VoidCallback onMicToggle;
  final VoidCallback onShowGifts;
  final VoidCallback onShowUserManagement;
  final VoidCallback onChangeBackground;
  final VoidCallback onShowBottomSheet;

  const RoomBottomBar({
    Key? key,
    required this.roomId,
    required this.userId,
    required this.userRole,
    required this.isMicOn,
    required this.isOwner,
    required this.isUploadingImage,
    required this.onMicToggle,
    required this.onShowGifts,
    required this.onShowUserManagement,
    required this.onChangeBackground,
    required this.onShowBottomSheet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show admin features for both Owner and Admin roles
    bool canManageUsers = isOwner || userRole == 'Admin';

    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mute Button
          _buildBottomBarItem(
            icon: userRole == 'Participant' && !isOwner 
                ? Icons.mic_off 
                : isMicOn 
                    ? Icons.mic 
                    : Icons.mic_off,
            label: userRole == 'Participant' && !isOwner 
                ? 'Request Mic' 
                : isMicOn 
                    ? 'Mute' 
                    : 'Unmute',
            isActive: isMicOn,
            onTap: () {
              if (userRole == 'Participant' && !isOwner) {
                onShowBottomSheet();
              } else {
                onMicToggle();
              }
            },
          ),
          
          // Gift Button
          _buildBottomBarItem(
            icon: Icons.card_giftcard,
            label: 'Gift',
            onTap: onShowGifts,
          ),
          
          // Speak Requests Button (for Owner and Admins)
          if (canManageUsers)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .collection('speakRequests')
                  .snapshots(),
              builder: (context, requestSnapshot) {
                bool hasRequests = requestSnapshot.hasData && 
                                  requestSnapshot.data!.docs.isNotEmpty;
                
                return _buildBottomBarItem(
                  icon: Icons.record_voice_over,
                  label: 'Requests',
                  isActive: hasRequests,
                  onTap: () {
                    showSpeakRequestsBottomSheet(context, roomId);
                  },
                );
              },
            ),
          
          // Participants Management Button (for Owner and Admins)  
          if (canManageUsers)
            _buildBottomBarItem(
              icon: Icons.group,
              label: 'Users',
              onTap: onShowUserManagement,
            ),

          // Background Change Button (for Owner only)
          if (isOwner)
            _buildBottomBarItem(
              icon: isUploadingImage ? Icons.hourglass_empty : Icons.wallpaper,
              label: 'Background',
              isActive: isUploadingImage,
              onTap: isUploadingImage ? null : onChangeBackground,
            ),
          
          // Coins Display
          _buildCoinsDisplay(),
        ],
      ),
    );
  }

  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppColor.red : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 3),
          Text(
            label,
            style: style(
              family: AppFonts.gMedium,
              size: 11,
              clr: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsDisplay() {
    final WalletController walletController = Get.find<WalletController>();
    
    return Obx(() => Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.red,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            color: Colors.white,
            size: 14,
          ),
          SizedBox(width: 3),
          Text(
            walletController.formatCoins(walletController.userCoins.value),
            style: style(
              family: AppFonts.gBold,
              size: 11,
              clr: Colors.white,
            ),
          ),
        ],
      ),
    ));
  }
} 