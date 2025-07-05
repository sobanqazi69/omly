import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/services/leaving_room.dart';

class RoomDialogs {
  static Future<void> showLeaveConfirmationDialog(
    BuildContext context, 
    String userId, 
    String roomId, 
    String userRole
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Leave Room'),
          content: Text('Are you sure you want to leave the room?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Leave'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                leaveRoom(FirebaseAuth.instance.currentUser!.uid,
                    context, roomId, userRole);
              },
            ),
          ],
        );
      },
    );
  }

  static void showMicRequestBottomSheet(
    BuildContext context,
    VoidCallback onRequestToSpeak,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_off,
              size: 50,
              color: AppColor.red,
            ),
            SizedBox(height: 10),
            Text(
              AppText.PeopleMightBeAbleToListen,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              AppText.TheHostMightSaveThisRecording,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onRequestToSpeak();
                Navigator.pop(context);
              },
              child: Text("Request to speak"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColor.red,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showOptionsBottomSheet(
    BuildContext context,
    String roomId,
    String userId,
    String userRole,
    Function(String) onPromoteToAdmin,
    Function(String) onDemoteToParticipant,
    Function(String) onRemoveModeratorPermission,
    Function(String) onKickFromRoom,
    Function(String) onBlockUser,
  ) async {
    try {
      // Get current user's role from Firestore
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('joinedUsers')
          .doc(currentUserId)
          .get();
      
      // Get room owner ID
      DocumentSnapshot roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      
      String? roomOwnerId = roomDoc.data() != null 
          ? (roomDoc.data() as Map<String, dynamic>)['admin'] as String?
          : null;
      
      String currentUserRole = 'Participant';
      bool isCurrentUserOwner = currentUserId == roomOwnerId;
      
      if (currentUserDoc.exists) {
        currentUserRole = currentUserDoc['role'] ?? 'Participant';
      }
      
      // Don't show options if current user is just a participant (unless they're the owner)
      if (currentUserRole == 'Participant' && !isCurrentUserOwner) {
        return;
      }
      
      // Don't show options for yourself
      if (userId == currentUserId) {
        return;
      }
      
      bool isTargetOwner = userId == roomOwnerId;
      
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'User Options',
                  style: style(
                    family: AppFonts.gBold,
                    size: 18,
                  ),
                ),
                SizedBox(height: 16),
                
                // Role Management Options
                if ((currentUserRole == 'Admin' || isCurrentUserOwner) && !isTargetOwner) ...[
                  // Promote/Demote options
                  if (userRole == 'Participant')
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings, color: AppColor.red),
                      title: Text('Promote to Admin'),
                      onTap: () {
                        onPromoteToAdmin(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Moderator' && isCurrentUserOwner)
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings, color: AppColor.red),
                      title: Text('Promote to Admin'),
                      onTap: () {
                        onPromoteToAdmin(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Admin' && isCurrentUserOwner)
                    ListTile(
                      leading: Icon(Icons.remove_circle_outline, color: Colors.orange),
                      title: Text('Demote to Speaker'),
                      onTap: () {
                        onDemoteToParticipant(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Moderator')
                    ListTile(
                      leading: Icon(Icons.mic_off, color: Colors.orange),
                      title: Text('Remove Speaking Permission'),
                      onTap: () {
                        onRemoveModeratorPermission(userId);
                        Navigator.pop(context);
                      },
                    ),
                  
                  // Room Management Options
                  if (userRole == 'Participant' || userRole == 'Moderator' || (isCurrentUserOwner && userRole == 'Admin'))
                    ListTile(
                      leading: Icon(Icons.remove_circle, color: Colors.red),
                      title: Text('Kick from Room'),
                      onTap: () {
                        onKickFromRoom(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Participant' || userRole == 'Moderator' || (isCurrentUserOwner && userRole == 'Admin'))
                    ListTile(
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text('Block User'),
                      onTap: () {
                        onBlockUser(userId);
                        Navigator.pop(context);
                      },
                    ),
                ],
                
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing options: $e');
    }
  }

  static void showUserManagementBottomSheet(
    BuildContext context,
    String roomId,
    Function(String userId, String userRole) onShowOptions,
  ) async {
    try {
      // Get room owner ID
      DocumentSnapshot roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      
      String? roomOwnerId = roomDoc.data() != null 
          ? (roomDoc.data() as Map<String, dynamic>)['admin'] as String?
          : null;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.red,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Room Members',
                        style: style(
                          family: AppFonts.gBold,
                          size: 18,
                          clr: Colors.white,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomId)
                        .collection('joinedUsers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No users in room'));
                      }

                      var users = snapshot.data!.docs;
                      
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          var userDoc = users[index];
                          var userName = userDoc['username'];
                          var userImage = userDoc['image'];
                          var userRole = userDoc['role'];
                          bool isOwner = userDoc.id == roomOwnerId;
                          
                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(userImage),
                                  radius: 24,
                                ),
                                if (isOwner)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColor.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(userName),
                            subtitle: Row(
                              children: [
                                Text(isOwner ? 'Owner' : userRole),
                                if (userRole == 'Moderator') ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.mic, color: Colors.white, size: 12),
                                        SizedBox(width: 2),
                                        Text(
                                          'Speaking',
                                          style: style(
                                            family: AppFonts.gMedium,
                                            size: 10,
                                            clr: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: userDoc.id != FirebaseAuth.instance.currentUser!.uid
                                ? IconButton(
                                    icon: Icon(Icons.more_vert),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onShowOptions(userDoc.id, userRole);
                                    },
                                  )
                                : Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColor.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'You',
                                      style: style(
                                        family: AppFonts.gMedium,
                                        size: 12,
                                        clr: AppColor.red,
                                      ),
                                    ),
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing user management: $e');
    }
  }
} 