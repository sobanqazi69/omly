import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:live_13/constants/selected_tags.dart';
import 'package:live_13/controller/mic_controller.dart';
import 'package:live_13/controller/gift_controller.dart';
import 'package:live_13/controller/wallet_controller.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/services/agora_token_service.dart';
import 'package:live_13/services/speak_user_request.dart';
import 'package:live_13/views/userScreens/user_screen.dart';
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

  late RtcEngine _engine = createAgoraRtcEngine();
  bool isMicOn = false;
  String userRole = 'Participant'; // Default role
  int uId = 0;

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

  void showOptionsBottomSheet(BuildContext context, String userId, String userRole) {
  if (this.userRole != 'Admin') {
    return;
  }
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
           (userRole == 'Moderator')? ListTile(
              leading: Icon(Icons.remove_circle_outline),
              title: Text('Remove from Moderator'),
              onTap: () {
                _removeFromModerator(userId);
                Navigator.pop(context);
              },
            ): SizedBox(),
            ListTile(
              leading: Icon(Icons.remove_circle),
              title: Text('Kick from Room'),
              onTap: () {
                _kickFromRoom(userId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Block User'),
              onTap: () {
                _blockUser(userId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
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
    MaterialPageRoute(builder: (context) => UserScreen()),
  );
  // Get.snackbar('Oops', 'You Have Been Kicked By The Admin');
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
      backgroundColor: AppColor.white,
      body: Stack(
        children: [
          Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: space19,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: style(family: AppFonts.gBold, size: 30),
                    ),
                    SizedBox(height: space4),
                    Text(
                      widget.roomDesc,
                      style: style(family: AppFonts.gMedium, size: 18),
                    ),
                  ],
                ),
                Row(
                  children: [
                    //  (userRole == 'Admin')? IconButton(
                    //     onPressed: () async {
                    //      deleteRoomAndRedirect(context, widget.roomId , userId , userRole);
                    //     },
                    //     icon: Icon(Icons.delete)) : SizedBox(),
                    InkWell(
                      onTap: () {
                        // Example usage: Check and delete the room if it has no participants
                        // leaveRoom(FirebaseAuth.instance.currentUser!.uid,
                        //     context, widget.roomId, user!.role);
                        showLeaveConfirmationDialog(context,FirebaseAuth.instance.currentUser!.uid,widget.roomId,user!.role);
                      },
                      child: Text(
                        AppText.Leave,
                        style: style(
                            family: AppFonts.gBold,
                            clr: AppColor.red,
                            size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: space20),
            Expanded(
              child: FutureBuilder<DocumentSnapshot?>(
                future: _getRoomDocumentt(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text("Room not found"));
                  }

                  DocumentSnapshot roomDoc = snapshot.data!;
                  String roomId = roomDoc.id;

                  return StreamBuilder<QuerySnapshot>(
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
      return Center(child: Text("No users in this room"));
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
                      var filteredDocs = snapshot.data!.docs;

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          // mainAxisSpacing: 1.0,
                          //crossAxisSpacing: 10.0,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var userDoc = filteredDocs[index];
                          var userName = userDoc['username'];
                          var userImage = userDoc['image'];
                          var userRole = userDoc['role'];

                          return Column(
                            children: [
                              InkWell(
                                onLongPress: () {
                                 (userRole=='Admin')? SizedBox(): showOptionsBottomSheet(
                                      context, userDoc.id, userRole);
                                },
                                child: Center(
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(userImage),
                                  ),
                                ),
                              ),
                              SizedBox(height: space2),
                              Text(
                               userName,
                                style: style(
                                    family: AppFonts.gBold,
                                    size: Get.width * .030),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                userRole,
                                style: style(
                                    family: AppFonts.gMedium,
                                    size: Get.width * .03),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
           StreamBuilder<DocumentSnapshot>(
  stream: firestore
      .collection('rooms')
      .doc(widget.roomId)
      .collection('joinedUsers')
      .doc(userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }

    // Check for errors or no data
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    if (!snapshot.hasData || !snapshot.data!.exists) {
      return Text('User data not found');
    }

    // Safe access to data with null checks
    Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
    if (data == null) {
      return Text('No data available');
    }

    bool isMicOn = data['isMicOn'] as bool? ?? false;
    String userRole = data['role'] as String? ?? 'Participant'; // default to Participant if null

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            InkWell(
              onTap: () {
                _showGiftsBottomSheet();
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColor.black,
                    ),
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(140, 158, 158, 158)),
                child: Icon(
                  Icons.card_giftcard,
                  size: 25,
                ),
              ),
            ),
            SizedBox(height: 4),
            Obx(() => Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: AppColor.white,
                    size: 14,
                  ),
                  SizedBox(width: 2),
                  Text(
                    walletController.formatCoins(walletController.userCoins.value),
                    style: style(
                      family: AppFonts.gBold,
                      size: 12,
                      clr: AppColor.white,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
       Align(
        alignment: Alignment.bottomCenter,
        child: Obx(() {
          return InkWell(
            onTap: () {
              if (userRole == 'Participant') {
                _showBottomSheet();
              } else {
                _toggleMic(userRole);
              }
            },
            child: Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(
                  color: micController.isMicOn.value ? AppColor.red : AppColor.black,
                ),
                shape: BoxShape.circle,
                color: const Color.fromARGB(140, 158, 158, 158),
              ),
              child: Icon(
                userRole == 'Participant' ? Icons.mic_off : Icons.mic,
                size: 35,
                color: micController.isMicOn.value ? AppColor.red : AppColor.black,
              ),
            ),
          );
        }),
      ),
        (userRole == 'Admin') ? InkWell(
          onTap: () {
            showSpeakRequestsBottomSheet(context, widget.roomId);
          },
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
                border: Border.all(
                  color: AppColor.black,
                ),
                shape: BoxShape.circle,
                color: const Color.fromARGB(140, 158, 158, 158)),
            child: Icon(
              Icons.add_alert,
              size: 25,
            ),
          ),
        ) : SizedBox()
      ],
    );
  },
),

          ],
        ),
      ),

      // Gift overlay
      _buildGiftOverlay(),
    ],
  ),
    );
  }
}
