import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_13/constants/selected_tags.dart';
import 'package:live_13/controller/mic_controller.dart';
import 'package:live_13/controller/gift_controller.dart';
import 'package:live_13/controller/wallet_controller.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/services/agora_token_service.dart';
import 'package:live_13/services/speak_user_request.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:live_13/Config/app_spacing.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/services/leaving_room.dart';

const appId =
    "f0ac4696784a47baa71c64381cabbacd"; // Replace with your actual Agora App ID

const gifts = [
  {'name': 'Cake', 'asset': 'assets/gifts/cake.svg', 'cost': 100},
  {'name': 'Castle', 'asset': 'assets/gifts/castle.svg', 'cost': 500},
  {'name': 'Cat', 'asset': 'assets/gifts/cat.svg', 'cost': 150},
  {'name': 'Crown', 'asset': 'assets/gifts/crown.svg', 'cost': 1000},
  {'name': 'Galaxy Gift', 'asset': 'assets/gifts/galaxy_gift.svg', 'cost': 2000},
  {'name': 'Heart', 'asset': 'assets/gifts/heart.svg', 'cost': 200},
  {'name': 'Magic Show', 'asset': 'assets/gifts/magic_show.svg', 'cost': 800},
  {'name': 'Plane', 'asset': 'assets/gifts/plane.svg', 'cost': 1500},
  {'name': 'Ring', 'asset': 'assets/gifts/ring.svg', 'cost': 3000},
  {'name': 'Rose', 'asset': 'assets/gifts/rose.svg', 'cost': 300},
  {'name': 'Surprise Box', 'asset': 'assets/gifts/surprise_box.svg', 'cost': 400},
  {'name': 'Yacht', 'asset': 'assets/gifts/yacht.svg', 'cost': 5000},
];

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String roomDesc;
  final String roomId;
  final String channelId;

  RoomScreen(
      {Key? key,
      required this.roomName,
      required this.roomDesc,
      required this.roomId, required this.channelId})
      : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}



class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
    final MicController micController = Get.put(MicController());
    final GiftController giftController = Get.put(GiftController());
    final WalletController walletController = Get.put(WalletController());

  
  Map<int, bool> mutedUsers = {};

  UserModel? user = userData.currentUser;
  bool isReceiver = false;
  Timer? _timer;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  late RtcEngine _engine = createAgoraRtcEngine();
  bool isMicOn = false;
  String userRole = 'Participant'; // Default role
  int uId = 0;
  bool isUploadingImage = false;
  
  // Predefined colors for room backgrounds
  final List<Color> predefinedColors = [
    AppColor.red, // Default app color
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.deepOrange,
    Colors.cyan,
    Colors.amber,
    Colors.lime,
    Colors.deepPurple,
    Colors.blueGrey,
    Colors.black87,
    Color(0xFF1A1A2E), // Dark blue
    Color(0xFF16213E), // Navy
    Color(0xFF0F3460), // Dark blue-grey
    Color(0xFF533483), // Purple
    Color(0xFF7209B7), // Magenta
    Color(0xFF2D1B69), // Royal purple
    Color(0xFF11698E), // Steel blue
    Color(0xFF19A7CE), // Sky blue
  ];

  @override
  void initState() {
    //WidgetsBinding.instance.addObserver(this); // Add observer
    super.initState();
        _getUserRole(); 

    initAgora();
    _startUpdatingTimestamp();
 uId = generateUnique15DigitInteger();
 storeUid ();

 // Initialize gift listener
 giftController.initializeGiftListener(widget.roomId);

  }

  Future<void> storeUid () async {
     String userId = FirebaseAuth.instance.currentUser!.uid;
    String roomId = widget.roomId;

    DocumentReference userDocRef = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('joinedUsers')
        .doc(userId);

    DocumentSnapshot userDoc = await userDocRef.get();

    if (userDoc.exists) {
      await userDocRef.set({
        'uId': uId,
      }, SetOptions(merge: true));
      print('uid stored of  $userId');
    }
  }

  Future<void> _updateTimestampIfUserExists() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String roomId = widget.roomId;

    DocumentReference userDocRef = firestore
        .collection('rooms')
        .doc(roomId)
        .collection('joinedUsers')
        .doc(userId);

    DocumentSnapshot userDoc = await userDocRef.get();

    if (userDoc.exists) {
      await userDocRef.set({
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Timestamp updated for user $userId');
    } else {
      print('User document does not exist');
    }
  }

  // Function to start the timer and update the timestamp every minute
  void _startUpdatingTimestamp() {
    _updateTimestampIfUserExists(); // Update immediately when the function is called
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _updateTimestampIfUserExists();
    });
  }
Future<void> _getUserRole() async {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  DocumentSnapshot userDoc = await firestore
      .collection('rooms')
      .doc(widget.roomId)
      .collection('joinedUsers')
      .doc(userId)
      .get();

  if (userDoc.exists) {
    if (mounted) {
      setState(() {
        userRole = userDoc['role'];
      });
    }
  }
}



  Future<void> signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      print('Signed in anonymously: ${FirebaseAuth.instance.currentUser?.uid}');
    } catch (e) {
      print('Error signing in anonymously: $e');
    }
  }

  Future<String> generateToken() async {
    try {
      // Use Railway-based Agora token service
      final token = await fetchAgoraToken(
        channelName: widget.channelId,
        uid: uId,
      );

      if (token != null && token.isNotEmpty) {
        print('Token generated successfully: ${token.substring(0, 20)}...');
        return token;
      } else {
        throw Exception('Failed to generate Agora token - received null or empty token');
      }
    } catch (e) {
      print('Error generating Agora token: $e');
      rethrow;
    }
  }

  Future<void> initAgora() async {
    String token = await generateToken();

    var status = await [Permission.microphone].request();
    if (status[Permission.microphone] != PermissionStatus.granted) {
      print('Microphone permission not granted');
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      print('Agora engine initialized');
    } catch (e) {
      print('Error initializing Agora engine: $e');
      return;
    }

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left channel");
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableAudio();
    debugPrint('Audio enabled');

    DocumentSnapshot? roomDoc = await _getRoomDocumentt();
    if (roomDoc == null) {
      print("Room document not found");
      return;
    }
    // String channelId = roomDoc['channelId'];
    // print("Channel ID: $channelId");
    

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelId,
      uid: uId,
      options: const ChannelMediaOptions(),
    );
    debugPrint('Joined channel: ${widget.channelId}');
          (userRole=='Participant')?     _engine.enableLocalAudio(false) :     _engine.enableLocalAudio(true);


  }

  int generateUnique15DigitInteger() {
    Random random = Random();

    int randomPart = random.nextInt(9000000) + 1000000;
    int timestampPart = DateTime.now().millisecondsSinceEpoch;

    String uniqueIdString = '$timestampPart$randomPart';

    uniqueIdString = uniqueIdString.substring(0, 15);

    return int.parse(uniqueIdString);
  }

  Future<DocumentSnapshot?> _getRoomDocumentt() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .where('roomId', isEqualTo: widget.roomId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }
  
// void _toggleMic(String userRole) {
//  final String userId = FirebaseAuth.instance.currentUser!.uid;
//   final DocumentReference userDocRef = firestore
//       .collection('rooms')
//       .doc(widget.roomId)
//       .collection('joinedUsers')
//       .doc(userId);

//   userDocRef.get().then((DocumentSnapshot docSnapshot) {
//     if (docSnapshot.exists) {
//       Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;
//       if (data != null) {
//         bool currentMicStatus = data['isMicOn'] as bool? ?? false;
//         bool newMicStatus = !currentMicStatus;

//         // Update Firestore and Agora mute state
//         userDocRef.update({'isMicOn': newMicStatus}).then((_) {
//           setState(() {
//             isMicOn = newMicStatus;
//           });
//           print("Mic status updated: $newMicStatus");
//           // Mute or unmute the local audio
//           if(userRole=='Admin')
//           {
//           _engine.muteLocalAudioStream(!newMicStatus).then((value) {
//             print("Local audio stream is now ${newMicStatus ? 'unmuted' : 'muted'}");
//           }).catchError((muteError) {
//             print("Error in muting/unmuting local audio stream: $muteError");
//           }); 
//           }
//           else
//           {
//             setState(() {
//     // Toggle the muted state for the given user ID
//     mutedUsers[uId] = !(mutedUsers[userId] ?? false);
//   });

//   // Call Agora's SDK to mute/unmute the remote audio stream
//   try{
// _engine.muteRemoteAudioStream(uid: uId,mute: mutedUsers[userId]!);
// print('remote user is muted')
// ;  }
// catch(e){
//   print('error muting rmote iser');
// }
  
//           }
//         }).catchError((error) {
//           print("Error updating mic status: $error");
//         }); 
//       }
//     } 
//   }).catchError((error) {
//     print("Error fetching user document: $error");
//   });
// }


void _toggleMic(String userRole) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final DocumentReference userDocRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('joinedUsers')
        .doc(userId);

    userDocRef.get().then((DocumentSnapshot docSnapshot) {
      if (docSnapshot.exists) {
        Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          bool currentMicStatus = data['isMicOn'] as bool? ?? false;
          bool newMicStatus = !currentMicStatus;

          // Update Firestore and Agora mute state
          userDocRef.update({'isMicOn': newMicStatus}).then((_) {
            micController.isMicOn.value = newMicStatus; // Update GetX state
            print("Mic status updated for $userId: ${newMicStatus ? 'unmuted' : 'muted'}");
            _engine.enableLocalAudio(newMicStatus);
          }).catchError((error) {
            print("Error updating Firestore mic status for $userId: $error");
          });
        }
      }
    }).catchError((error) {
      print("Error fetching user document for $userId: $error");
    });
  }





  void _showBottomSheet() {
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
                _requestToSpeak();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      _handleAppClosed();
    }
  }

  void _handleAppClosed() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    leaveRoom(userId, context, widget.roomId, user!.role);
  }

  Future<void> _requestToSpeak() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    User? userr = FirebaseAuth.instance.currentUser;

    if (userr != null) {
      String userName = userr.displayName ?? 'Unknown';
      String userImage = userr.photoURL ?? '';

      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('speakRequests')
          .doc(userId)
          .set({
        'isRequest': true,
        'name': user!.username ,
        'image': user?.image ?? userImage,
      });
    } else {
      print('No user signed in');
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    WidgetsBinding.instance.removeObserver(this); // Remove observer

    leaveRoom(widget.roomId, context, widget.roomId, user!.role);
    _engine.release();
    _timer?.cancel();

    super.dispose();
  }

  void showOptionsBottomSheet(BuildContext context, String userId, String userRole) async {
    try {
      // Get current user's role from Firestore
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot currentUserDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(currentUserId)
          .get();
      
      // Get room owner ID
      DocumentSnapshot roomDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
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
                        _promoteToAdmin(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Moderator' && isCurrentUserOwner)
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings, color: AppColor.red),
                      title: Text('Promote to Admin'),
                      onTap: () {
                        _promoteToAdmin(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Admin' && isCurrentUserOwner)
                    ListTile(
                      leading: Icon(Icons.remove_circle_outline, color: Colors.orange),
                      title: Text('Demote to Speaker'),
                      onTap: () {
                        _demoteToParticipant(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Moderator')
                    ListTile(
                      leading: Icon(Icons.mic_off, color: Colors.orange),
                      title: Text('Remove Speaking Permission'),
                      onTap: () {
                        _removeModeratorPermission(userId);
                        Navigator.pop(context);
                      },
                    ),
                  
                  // Room Management Options
                  if (userRole == 'Participant' || userRole == 'Moderator' || (isCurrentUserOwner && userRole == 'Admin'))
                    ListTile(
                      leading: Icon(Icons.remove_circle, color: Colors.red),
                      title: Text('Kick from Room'),
                      onTap: () {
                        _kickFromRoom(userId);
                        Navigator.pop(context);
                      },
                    ),
                  if (userRole == 'Participant' || userRole == 'Moderator' || (isCurrentUserOwner && userRole == 'Admin'))
                    ListTile(
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text('Block User'),
                      onTap: () {
                        _blockUser(userId);
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


Future<void> _promoteToAdmin(String userId) async {
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({'role': 'Admin'});
      
      Get.snackbar(
        'Success',
        'User promoted to Admin',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error promoting user: $e');
      Get.snackbar(
        'Error',
        'Failed to promote user',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _demoteToParticipant(String userId) async {
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({'role': 'Moderator'}); // Keep speaking permission as Moderator
      
      Get.snackbar(
        'Success',
        'User demoted to Speaker (kept mic permission)',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error demoting user: $e');
      Get.snackbar(
        'Error',
        'Failed to demote user',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removeModeratorPermission(String userId) async {
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({'role': 'Participant'});
      
      Get.snackbar(
        'Success',
        'Speaking permission removed',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error removing moderator permission: $e');
      Get.snackbar(
        'Error',
        'Failed to remove speaking permission',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removeFromModerator(String userId) async {
    await firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('joinedUsers')
        .doc(userId)
        .update({'role': 'Participant'});
  }

Future<void> _kickFromRoom(String userId) async {
  final roomRef = firestore.collection('rooms').doc(widget.roomId);

  // Start a Firestore batch operation
  WriteBatch batch = firestore.batch();

  // Remove the user document from the joinedUsers subcollection
  batch.delete(roomRef.collection('joinedUsers').doc(userId));

  // Get the room document to update the participant list
  DocumentSnapshot roomDoc = await roomRef.get();
  if (roomDoc.exists) {
    var data = roomDoc.data() as Map<String, dynamic>?;
    if (data != null) {
      List participants = List.from(data['participants'] ?? []);
      participants.remove(userId);

      // Update the participants list in the room document
      batch.update(roomRef, {'participants': participants});
    }
  }

  // Commit the batch operation
  await batch.commit();
}
  Future<void> _blockUser(String userId) async {
  final roomRef = firestore.collection('rooms').doc(widget.roomId);

  // Add the user ID to the blockedUsers array
  await roomRef.update({
    'blockedUsers': FieldValue.arrayUnion([userId])
  });
  _kickFromRoom(userId);

  // Remove the user document from the joinedUsers subcollection
  
}

  Future<void> _changeRoomBackground() async {
    try {
      // Check if current user is the owner
      DocumentSnapshot roomDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .get();
      
      String? roomOwnerId = roomDoc.data() != null 
          ? (roomDoc.data() as Map<String, dynamic>)['admin'] as String?
          : null;
      
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      
      if (currentUserId != roomOwnerId) {
        Get.snackbar(
          'Error',
          'Only the room owner can change the background',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show image picker options
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                                 Text(
                   'Change Room Background',
                   style: style(
                     family: AppFonts.gBold,
                     size: 18,
                   ),
                 ),
                 SizedBox(height: 20),
                 ListTile(
                   leading: Icon(Icons.palette, color: AppColor.red),
                   title: Text('Choose Color'),
                   onTap: () {
                     Navigator.pop(context);
                     _showColorPicker();
                   },
                 ),
                 ListTile(
                   leading: Icon(Icons.photo_library, color: AppColor.red),
                   title: Text('Choose from Gallery'),
                   onTap: () {
                     Navigator.pop(context);
                     _pickAndUploadBackground(ImageSource.gallery);
                   },
                 ),
                 ListTile(
                   leading: Icon(Icons.camera_alt, color: AppColor.red),
                   title: Text('Take Photo'),
                   onTap: () {
                     Navigator.pop(context);
                     _pickAndUploadBackground(ImageSource.camera);
                   },
                 ),
                 ListTile(
                   leading: Icon(Icons.restore, color: Colors.orange),
                   title: Text('Reset to Default'),
                   onTap: () {
                     Navigator.pop(context);
                     _resetRoomBackground();
                   },
                 ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error changing background: $e');
      Get.snackbar(
        'Error',
        'Failed to change background',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickAndUploadBackground(ImageSource source) async {
    try {
      setState(() {
        isUploadingImage = true;
      });

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        setState(() {
          isUploadingImage = false;
        });
        return;
      }

      // Upload to Firebase Storage
      String fileName = 'room_backgrounds/${widget.roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(File(image.path));
      
      // Show upload progress
      Get.snackbar(
        'Uploading',
        'Uploading background image...',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      // Update room document with new background
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            'backgroundImage': downloadURL,
            'backgroundColor': FieldValue.delete(), // Remove color when setting image
          });

      Get.snackbar(
        'Success',
        'Room background updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      print('Error uploading background: $e');
      Get.snackbar(
        'Error',
        'Failed to upload background image',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isUploadingImage = false;
      });
    }
  }

  Future<void> _resetRoomBackground() async {
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            'backgroundImage': FieldValue.delete(),
            'backgroundColor': FieldValue.delete(),
          });

      Get.snackbar(
        'Success',
        'Room background reset to default',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error resetting background: $e');
      Get.snackbar(
        'Error',
        'Failed to reset background',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Choose Background Color',
                style: style(
                  family: AppFonts.gBold,
                  size: 18,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: predefinedColors.length,
                  itemBuilder: (context, index) {
                    Color color = predefinedColors[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () {
                          Navigator.pop(context);
                          _setRoomBackgroundColor(color);
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: color == AppColor.red
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Tap any color to apply it as room background',
                style: style(
                  family: AppFonts.gMedium,
                  size: 14,
                  clr: Colors.grey[600]!,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setRoomBackgroundColor(Color color) async {
    try {
      // Store color as hex string
      String colorHex = '#${color.value.toRadixString(16).substring(2)}';

      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            'backgroundColor': colorHex,
            'backgroundImage': FieldValue.delete(), // Remove image when setting color
          });

      Get.snackbar(
        'Success',
        'Background color updated!',
        backgroundColor: color.withOpacity(0.9), // Use the selected color
        colorText: Colors.white,
        duration: Duration(seconds: 1), // Very quick notification
        animationDuration: Duration(milliseconds: 300), // Smooth animation
      );

    } catch (e) {
      print('Error setting background color: $e');
      Get.snackbar(
        'Error',
        'Failed to set background color',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }


  void _sendGift(String giftName, String giftAsset, int giftCost) async {
    await giftController.sendGift(giftName, giftAsset, widget.roomId, giftCost);
  }

  void _showGiftsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Send a Gift",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  var gift = gifts[index];
                  return InkWell(
                    onTap: () {
                      _sendGift(
                        gift['name'] as String, 
                        gift['asset'] as String,
                        gift['cost'] as int,
                      );
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          child: SvgPicture.asset(
                            gift['asset'] as String,
                            fit: BoxFit.contain,
                            placeholderBuilder: (context) => Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.card_giftcard,
                                size: 30,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          gift['name'] as String,
                          style: TextStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${gift['cost']} coins',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColor.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> showLeaveConfirmationDialog(BuildContext context, String userId, String roomId, String userRole) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button to dismiss
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Confirm Leave Room'),
        content: Text('Are you sure you want to leave the room?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss the dialog
            },
          ),
          TextButton(
            child: Text('Leave'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss the dialog
  leaveRoom(FirebaseAuth.instance.currentUser!.uid,
                            context, widget.roomId, user!.role);            },
          ),
        ],
      );
    },
  );
}


  void navigateToUserScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminScreen()),
    );
    // Get.snackbar('Oops', 'You Have Been Kicked By The Admin');
  }

  Future<void> _requestSeatChange(int targetSeatNumber) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Check if user is currently seated (Admin or Moderator)
      DocumentSnapshot userDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        Get.snackbar(
          'Error',
          'User not found in room',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      String userRole = userDoc['role'] ?? 'Participant';
      
      // Only allow Admin and Moderator to change seats
      if (userRole != 'Admin' && userRole != 'Moderator') {
        Get.snackbar(
          'Not Allowed',
          'Only speakers can change seats',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      
      // Update user's seat position
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({
            'seatPosition': targetSeatNumber,
            'seatChangedAt': FieldValue.serverTimestamp(),
          });
      
      Get.snackbar(
        'Seat Changed',
        'Moved to seat #$targetSeatNumber',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 1),
      );
      
      print('User $userId moved to seat $targetSeatNumber');
      
    } catch (e) {
      print('Error changing seat: $e');
      Get.snackbar(
        'Error',
        'Failed to change seat',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _minimizeRoom() {
    try {
      // Create minimized room overlay BEFORE navigating
      _createMinimizedRoomOverlay();
      
      // Navigate to user screen WITHOUT disposing the current room
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminScreen(),
          settings: RouteSettings(name: '/user_from_room'),
        ),
      );
      
      // Show a snackbar to confirm the room is minimized
      Get.snackbar(
        'Room Minimized',
        'You\'re still connected to voice • Tap floating widget to return',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
      
      print('Room minimized - staying connected to channel: ${widget.channelId}');
    } catch (e) {
      print('Error minimizing room: $e');
      // Fallback: navigate to user screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminScreen()),
      );
    }
  }

    Future<void> _disconnectAndLeaveRoom() async {
    try {
      // Get current user ID
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Disconnect from Agora channel completely
      await _engine.leaveChannel();
      await _engine.release();
      
      // Cancel the timestamp timer
      _timer?.cancel();
      
      // Leave room in Firestore
      await leaveRoom(userId, context, widget.roomId, user!.role);
      
      print('Successfully disconnected from room: ${widget.roomId}');
    } catch (e) {
      print('Error disconnecting from room: $e');
      rethrow;
    }
  }

  void _createMinimizedRoomOverlay() async {
    try {
      // Get room owner's profile picture
      DocumentSnapshot roomDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .get();
      
      String? ownerImage;
      if (roomDoc.exists) {
        String? ownerId = (roomDoc.data() as Map<String, dynamic>?)?['admin'] as String?;
        if (ownerId != null) {
          DocumentSnapshot ownerDoc = await firestore
              .collection('rooms')
              .doc(widget.roomId)
              .collection('joinedUsers')
              .doc(ownerId)
              .get();
          
          if (ownerDoc.exists) {
            ownerImage = (ownerDoc.data() as Map<String, dynamic>?)?['image'] as String?;
          }
        }
      }

      // Store room data for rejoining
      final roomData = {
        'roomName': widget.roomName,
        'roomDesc': widget.roomDesc,
        'roomId': widget.roomId,
        'channelId': widget.channelId,
      };

      // Create overlay entry
      final overlay = Overlay.of(context);
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => MinimizedRoomWidget(
          roomName: widget.roomName,
          roomId: widget.roomId,
          ownerImage: ownerImage,
          onTap: () {
            // Remove overlay
            overlayEntry?.remove();
            
            // Navigate back to the existing room (pop back to it)
            Navigator.of(context).popUntil((route) {
              return route.settings.name == '/room' || 
                     route.isFirst ||
                     (route.settings.arguments != null && 
                      route.settings.arguments is Map &&
                      (route.settings.arguments as Map)['roomId'] == roomData['roomId']);
            });
            
            // If we couldn't find the existing room, create a new one
            if (Navigator.of(context).canPop()) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomScreen(
                    roomName: roomData['roomName']!,
                    roomDesc: roomData['roomDesc']!,
                    roomId: roomData['roomId']!,
                    channelId: roomData['channelId']!,
                  ),
                  settings: RouteSettings(
                    name: '/room',
                    arguments: {'roomId': roomData['roomId']},
                  ),
                ),
              );
            }
          },
          onClose: () async {
            try {
              // Remove overlay first
              overlayEntry?.remove();
              
              // Disconnect completely from the room
              await _disconnectAndLeaveRoom();
              
              // Navigate back to user screen and clear room from stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => AdminScreen()),
                (route) => false,
              );
              
              // Show confirmation
              Get.snackbar(
                'Disconnected',
                'You have left the room completely',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: Duration(seconds: 2),
                snackPosition: SnackPosition.TOP,
              );
              
            } catch (e) {
              print('Error disconnecting from room: $e');
              // Fallback: remove overlay and navigate
              overlayEntry?.remove();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => AdminScreen()),
                (route) => false,
              );
            }
          },
        ),
      );

      // Insert overlay
      overlay.insert(overlayEntry);
    } catch (e) {
      print('Error creating minimized overlay: $e');
    }
  }

  Widget _buildGiftOverlay() {
    return Obx(() {
      if (!giftController.showGiftOverlay.value || giftController.currentGift.value == null) {
        return SizedBox();
      }

      return Positioned.fill(
        child: Container(
          color: Colors.black54,
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: Duration(seconds: 2),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.3 + (value * 1.2), // Scale from 0.3 to 1.5
                  child: Opacity(
                    opacity: value > 0.75 ? (1.0 - ((value - 0.75) * 4)) : 1.0, // Fade out in last 25%
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          child: SvgPicture.asset(
                            giftController.currentGift.value!,
                            fit: BoxFit.contain,
                            placeholderBuilder: (context) => Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.card_giftcard,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Gift from ${giftController.giftSenderName.value ?? "Someone"}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('rooms').doc(widget.roomId).snapshots(),
        builder: (context, backgroundSnapshot) {
          String? backgroundImageUrl;
          String? backgroundColor;
          
          if (backgroundSnapshot.hasData && backgroundSnapshot.data!.exists) {
            var roomData = backgroundSnapshot.data!.data() as Map<String, dynamic>?;
            backgroundImageUrl = roomData?['backgroundImage'] as String?;
            backgroundColor = roomData?['backgroundColor'] as String?;
          }

          // Helper function to convert hex string to Color
          Color? getColorFromHex(String? hexString) {
            if (hexString == null) return null;
            try {
              return Color(int.parse(hexString.replaceFirst('#', '0xFF')));
            } catch (e) {
              return null;
            }
          }

          Color? customColor = getColorFromHex(backgroundColor);

          return AnimatedContainer(
            duration: Duration(milliseconds: 350), // Smooth transition for all users
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              // Priority: Image > Custom Color > Default Gradient
              image: backgroundImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(backgroundImageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  )
                : null,
              gradient: backgroundImageUrl == null
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      customColor ?? AppColor.red,
                      (customColor ?? AppColor.red).withOpacity(0.7),
                    ],
                  )
                : null,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Top Bar
                      _buildTopBar(),
                      
                      // Main Room Content
                      Expanded(
                        child: FutureBuilder<DocumentSnapshot?>(
                          future: _getRoomDocumentt(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: Colors.white));
                            }
                            if (!snapshot.hasData || snapshot.data == null) {
                              return Center(child: Text("Room not found", style: TextStyle(color: Colors.white)));
                            }

                            DocumentSnapshot roomDoc = snapshot.data!;
                            String roomId = roomDoc.id;

                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(roomId)
                                  .snapshots(),
                              builder: (context, roomSnapshot) {
                                if (roomSnapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator(color: Colors.white));
                                }
                                
                                String? roomOwnerId;
                                if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
                                  var roomData = roomSnapshot.data!.data() as Map<String, dynamic>?;
                                  roomOwnerId = roomData?['admin'] as String?;
                                }

                                return StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(roomId)
                                      .collection('joinedUsers')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator(color: Colors.white));
                                    }
                                    if (!snapshot.hasData) {
                                      return Center(child: Text("No users in this room", style: TextStyle(color: Colors.white)));
                                    }

                                    // Check if the current user's document exists
                                    var userDocExists = snapshot.data!.docs.any((doc) => doc.id == userId);

                                    if (!userDocExists) {
                                      // If the user's document does not exist, navigate to the user screen
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        navigateToUserScreen();
                                      });
                                      return SizedBox();
                                    }
                                    
                                    var allUsers = snapshot.data!.docs;
                                    return _buildRoomLayout(allUsers, roomOwnerId);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      
                      // Bottom Bar
                      _buildBottomBar(userId),
                    ],
                  ),

                  // Gift overlay
                  _buildGiftOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  _minimizeRoom();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Minimize',
                        style: style(
                          family: AppFonts.gMedium,
                          size: 14,
                          clr: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Mic status legend
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.mic, color: Colors.white, size: 12),
                    SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.mic_off, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              showLeaveConfirmationDialog(context, FirebaseAuth.instance.currentUser!.uid, widget.roomId, user!.role);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Exit',
                style: style(
                  family: AppFonts.gMedium,
                  size: 14,
                  clr: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomLayout(List<QueryDocumentSnapshot> allUsers, String? roomOwnerId) {
    // Separate users by role - only speakers fill seats
    var owner = allUsers.where((user) => user.id == roomOwnerId).toList();
    var admins = allUsers.where((user) => user['role'] == 'Admin' && user.id != roomOwnerId).toList();
    var moderators = allUsers.where((user) => user['role'] == 'Moderator').toList();
    // Participants are hidden - don't show in seats

    // Combine admins and moderators for speaking positions
    var speakers = [...admins, ...moderators];

    return Column(
      children: [
        // Owner Section
        if (owner.isNotEmpty) _buildOwnerSection(owner.first, roomOwnerId),
        
        SizedBox(height: 20),
        
        // 40 Seats Grid - Always shown, filled with speakers only
        Expanded(
          child: _buildSpeakingSeats(speakers, roomOwnerId),
        ),
      ],
    );
  }

  Widget _buildOwnerSection(QueryDocumentSnapshot ownerDoc, String? roomOwnerId) {
    Map<String, dynamic> data = ownerDoc.data() as Map<String, dynamic>;
    bool isMicOn = data.containsKey('isMicOn') ? (data['isMicOn'] ?? false) : false;
    
    return Column(
      children: [
        InkWell(
          onLongPress: () {
            debugPrint('Owner ID: ${ownerDoc.id}');
            showOptionsBottomSheet(context, ownerDoc.id, ownerDoc['role']);
          },
          child: Stack(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMicOn ? Colors.green : Colors.white, 
                    width: 3
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                    if (isMicOn)
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage: NetworkImage(ownerDoc['image']),
                ),
              ),
              // Mic status indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isMicOn ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                      if (isMicOn)
                        BoxShadow(
                          color: Colors.green.withOpacity(0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.roomName,
          style: style(
            family: AppFonts.gBold,
            size: 16,
            clr: Colors.white,
          ),
        ),
        SizedBox(height: 2),
        Text(
          ownerDoc['username'],
          style: style(
            family: AppFonts.gMedium,
            size: 12,
            clr: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingRow(List<QueryDocumentSnapshot> speakers, String? roomOwnerId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: speakers.length <= 2 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left speaker
              if (speakers.length > 0) _buildSpeakerCard(speakers[0], roomOwnerId),
              
              // Center user indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.red,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    'U',
                    style: style(
                      family: AppFonts.gBold,
                      size: 24,
                      clr: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Right speaker
              if (speakers.length > 1) _buildSpeakerCard(speakers[1], roomOwnerId)
              else Container(width: 60), // Placeholder
            ],
          )
        : Column(
            children: [
              // First row with up to 3 speakers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (speakers.length > 0) _buildSpeakerCard(speakers[0], roomOwnerId),
                  if (speakers.length > 1) _buildSpeakerCard(speakers[1], roomOwnerId),
                  if (speakers.length > 2) _buildSpeakerCard(speakers[2], roomOwnerId),
                ],
              ),
              if (speakers.length > 3) ...[
                SizedBox(height: 16),
                // Second row for additional speakers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 3; i < speakers.length && i < 6; i++)
                      _buildSpeakerCard(speakers[i], roomOwnerId),
                  ],
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildSpeakerCard(QueryDocumentSnapshot speakerDoc, String? roomOwnerId) {
    String role = speakerDoc['role'];
    String displayRole = role == 'Moderator' ? 'Speaker' : 'Admin';
    Color roleColor = role == 'Moderator' ? Colors.orange : Colors.blue;
    
    return Column(
      children: [
        InkWell(
          onLongPress: () {
            showOptionsBottomSheet(context, speakerDoc.id, speakerDoc['role']);
          },
          child: Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(speakerDoc['image']),
                ),
              ),
              if (role == 'Moderator')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 6),
        Text(
          displayRole,
          style: style(
            family: AppFonts.gMedium,
            size: 12,
            clr: roleColor,
          ),
        ),
        Text(
          speakerDoc['username'],
          style: style(
            family: AppFonts.gMedium,
            size: 10,
            clr: Colors.white70,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAdminRow(List<QueryDocumentSnapshot> admins, String? roomOwnerId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left admin
          if (admins.length > 0) _buildAdminCard(admins[0], roomOwnerId),
          
          // Center user indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.red,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                'U',
                style: style(
                  family: AppFonts.gBold,
                  size: 24,
                  clr: Colors.white,
                ),
              ),
            ),
          ),
          
          // Right admin
          if (admins.length > 1) _buildAdminCard(admins[1], roomOwnerId)
          else Container(width: 60), // Placeholder
        ],
      ),
    );
  }

  Widget _buildAdminCard(QueryDocumentSnapshot adminDoc, String? roomOwnerId) {
    return Column(
      children: [
        InkWell(
          onLongPress: () {
            showOptionsBottomSheet(context, adminDoc.id, adminDoc['role']);
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(adminDoc['image']),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Admin',
          style: style(
            family: AppFonts.gMedium,
            size: 12,
            clr: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingSeats(List<QueryDocumentSnapshot> speakers, String? roomOwnerId) {
    // Create a map to track which seats are occupied
    Map<int, QueryDocumentSnapshot> seatMap = {};
    
    // Assign speakers to their preferred seats or auto-assign
    for (int i = 0; i < speakers.length; i++) {
      var speaker = speakers[i];
      var data = speaker.data() as Map<String, dynamic>;
      int? preferredSeat = data['seatPosition'] as int?;
      
      if (preferredSeat != null && preferredSeat >= 1 && preferredSeat <= 40) {
        // Check if preferred seat is available
        if (!seatMap.containsKey(preferredSeat)) {
          seatMap[preferredSeat] = speaker;
        } else {
          // Preferred seat taken, find next available
          for (int j = 1; j <= 40; j++) {
            if (!seatMap.containsKey(j)) {
              seatMap[j] = speaker;
              break;
            }
          }
        }
      } else {
        // No preferred seat, auto-assign to first available
        for (int j = 1; j <= 40; j++) {
          if (!seatMap.containsKey(j)) {
            seatMap[j] = speaker;
            break;
          }
        }
      }
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, // 8 columns for 40 seats
          mainAxisSpacing: 8,
          crossAxisSpacing: 6,
          childAspectRatio: 0.8,
        ),
        itemCount: 40, // Fixed 40 seats
        itemBuilder: (context, index) {
          int seatNumber = index + 1;
          
          if (seatMap.containsKey(seatNumber)) {
            // Occupied seat with speaker
            var speaker = seatMap[seatNumber]!;
            return _buildOccupiedSpeakerSeat(speaker, seatNumber, roomOwnerId);
          } else {
            // Empty seat
            return _buildEmptySeat(seatNumber);
          }
        },
      ),
    );
  }

  Widget _buildOccupiedSpeakerSeat(QueryDocumentSnapshot userDoc, int seatNumber, String? roomOwnerId) {
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    String role = data['role'] ?? 'Participant';
    bool isModerator = role == 'Moderator';
    bool isAdmin = role == 'Admin';
    bool isMicOn = data.containsKey('isMicOn') ? (data['isMicOn'] ?? false) : false;
    
    return Column(
      children: [
        InkWell(
          onLongPress: () {
            showOptionsBottomSheet(context, userDoc.id, userDoc['role']);
          },
          child: Stack(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMicOn 
                        ? Colors.green 
                        : isModerator 
                            ? Colors.orange 
                            : isAdmin 
                                ? Colors.blue 
                                : Colors.white, 
                    width: 2
                  ),
                  boxShadow: [
                    if (isMicOn)
                      BoxShadow(
                        color: Colors.green.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(userDoc['image']),
                ),
              ),
              // Role indicator (top right)
              if (isModerator)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      Icons.record_voice_over,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              if (isAdmin)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              // Mic status indicator (bottom right)
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isMicOn ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      if (isMicOn)
                        BoxShadow(
                          color: Colors.green.withOpacity(0.8),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                    ],
                  ),
                  child: Icon(
                    isMicOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2),
        Container(
          height: 12,
          child: Text(
            userDoc['username'],
            style: style(
              family: AppFonts.gMedium,
              size: 7,
              clr: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantSeats(List<QueryDocumentSnapshot> participants, String? roomOwnerId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 12, // Fixed 12 seats
        itemBuilder: (context, index) {
          if (index < participants.length) {
            // Occupied seat
            var participant = participants[index];
            return _buildOccupiedSeat(participant, index + 1, roomOwnerId);
          } else {
            // Empty seat
            return _buildEmptySeat(index + 1);
          }
        },
      ),
    );
  }

  Widget _buildOccupiedSeat(QueryDocumentSnapshot userDoc, int seatNumber, String? roomOwnerId) {
    return Column(
      children: [
        InkWell(
          onLongPress: () {
            showOptionsBottomSheet(context, userDoc.id, userDoc['role']);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 23,
              backgroundImage: NetworkImage(userDoc['image']),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          userDoc['username'],
          style: style(
            family: AppFonts.gMedium,
            size: 10,
            clr: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptySeat(int seatNumber) {
    return InkWell(
      onTap: () {
        _requestSeatChange(seatNumber);
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Icon(
              Icons.person_add,
              size: 20,
              color: Colors.white30,
            ),
          ),
          SizedBox(height: 2),
          Container(
            height: 12,
            child: Text(
              'No.$seatNumber',
              style: style(
                family: AppFonts.gMedium,
                size: 7,
                clr: Colors.white70,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore
          .collection('rooms')
          .doc(widget.roomId)
          .snapshots(),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return Container(height: 80);
        }

        String? roomOwnerId;
        if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
          var roomData = roomSnapshot.data!.data() as Map<String, dynamic>?;
          roomOwnerId = roomData?['admin'] as String?;
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: firestore
              .collection('rooms')
              .doc(widget.roomId)
              .collection('joinedUsers')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(height: 80);
            }

            String userRole = 'Participant';
            bool isMicOn = false;
            bool isOwner = userId == roomOwnerId;

            if (snapshot.hasData && snapshot.data!.exists) {
              Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                userRole = data.containsKey('role') ? (data['role'] ?? 'Participant') : 'Participant';
                isMicOn = data.containsKey('isMicOn') ? (data['isMicOn'] ?? false) : false;
              }
            }

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
                        _showBottomSheet();
                      } else {
                        _toggleMic(userRole);
                      }
                    },
                  ),
                  
                  // Gift Button
                  _buildBottomBarItem(
                    icon: Icons.card_giftcard,
                    label: 'Gift',
                    onTap: () {
                      _showGiftsBottomSheet();
                    },
                  ),
                  
                  // Speak Requests Button (for Owner and Admins)
                  if (canManageUsers)
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('rooms')
                          .doc(widget.roomId)
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
                            showSpeakRequestsBottomSheet(context, widget.roomId);
                          },
                        );
                      },
                    ),
                  
                  // Participants Management Button (for Owner and Admins)  
                  if (canManageUsers)
                    _buildBottomBarItem(
                      icon: Icons.group,
                      label: 'Users',
                      onTap: () {
                        _showUserManagementBottomSheet();
                      },
                    ),

                  // Background Change Button (for Owner only)
                  if (isOwner)
                    _buildBottomBarItem(
                      icon: isUploadingImage ? Icons.hourglass_empty : Icons.wallpaper,
                      label: 'Background',
                      isActive: isUploadingImage,
                      onTap: isUploadingImage ? null : () {
                        _changeRoomBackground();
                      },
                    ),
                  
                  // Coins Display
                  _buildCoinsDisplay(),
                ],
              ),
            );
          },
        );
      },
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

  void _showUserManagementBottomSheet() async {
    try {
      // Get room owner ID
      DocumentSnapshot roomDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
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
                    stream: firestore
                        .collection('rooms')
                        .doc(widget.roomId)
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
                                      showOptionsBottomSheet(context, userDoc.id, userRole);
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

class MinimizedRoomWidget extends StatefulWidget {
  final String roomName;
  final String roomId;
  final String? ownerImage;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const MinimizedRoomWidget({
    Key? key,
    required this.roomName,
    required this.roomId,
    this.ownerImage,
    required this.onTap,
    required this.onClose,
  }) : super(key: key);

  @override
  State<MinimizedRoomWidget> createState() => _MinimizedRoomWidgetState();
}

class _MinimizedRoomWidgetState extends State<MinimizedRoomWidget> {
  double _x = 20.0;
  double _y = 100.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Set initial position within safe bounds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureWithinBounds();
    });
  }

  void _ensureWithinBounds() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeArea = MediaQuery.of(context).padding;
    
    // Widget dimensions
    const widgetWidth = 200.0;
    const widgetHeight = 60.0;
    
    setState(() {
      // Ensure within horizontal bounds
      if (_x < 10) _x = 10;
      if (_x > screenWidth - widgetWidth - 10) _x = screenWidth - widgetWidth - 10;
      
      // Ensure within vertical bounds (considering safe area)
      if (_y < safeArea.top + 10) _y = safeArea.top + 10;
      if (_y > screenHeight - safeArea.bottom - widgetHeight - 10) {
        _y = screenHeight - safeArea.bottom - widgetHeight - 10;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      child: AnimatedScale(
        scale: _isDragging ? 1.1 : 1.0,
        duration: Duration(milliseconds: 200),
        child: Draggable(
          feedback: _buildFloatingWidget(),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildFloatingWidget(),
          ),
          onDragEnd: (details) {
            setState(() {
              _x = details.offset.dx;
              _y = details.offset.dy;
              _isDragging = false;
            });
            _ensureWithinBounds();
          },
          onDragStarted: () {
            setState(() {
              _isDragging = true;
            });
          },
          child: _buildFloatingWidget(),
        ),
      ),
    );
  }

  Widget _buildFloatingWidget() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 200,
        height: 60,
        decoration: BoxDecoration(
          color: AppColor.red,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Owner's profile picture or room icon
            Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: widget.ownerImage != null
                  ? ClipOval(
                      child: Image.network(
                        widget.ownerImage!,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 24,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            // Room info with animated text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.roomName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId)
                        .collection('joinedUsers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int userCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text(
                        '$userCount users • Tap to rejoin',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Close button
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 20,
                height: 20,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
