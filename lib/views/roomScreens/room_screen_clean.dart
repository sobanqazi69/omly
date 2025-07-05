import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:live_13/views/userScreens/user_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/services/leaving_room.dart';

// Import our extracted widgets
import 'widgets/room_top_bar.dart';
import 'widgets/room_owner_section.dart';
import 'widgets/room_seats_grid.dart';
import 'widgets/room_bottom_bar.dart';
import 'widgets/minimized_room_widget.dart';
import 'widgets/room_dialogs.dart';

const appId = "f0ac4696784a47baa71c64381cabbacd";

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

class RoomScreenClean extends StatefulWidget {
  final String roomName;
  final String roomDesc;
  final String roomId;
  final String channelId;

  const RoomScreenClean({
    Key? key,
    required this.roomName,
    required this.roomDesc,
    required this.roomId,
    required this.channelId,
  }) : super(key: key);

  @override
  State<RoomScreenClean> createState() => _RoomScreenCleanState();
}

class _RoomScreenCleanState extends State<RoomScreenClean> with WidgetsBindingObserver {
  // Controllers
  final MicController micController = Get.put(MicController());
  final GiftController giftController = Get.put(GiftController());
  final WalletController walletController = Get.put(WalletController());

  // Firebase instances
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Agora and user state
  late RtcEngine _engine = createAgoraRtcEngine();
  UserModel? user = userData.currentUser;
  String userRole = 'Participant';
  int uId = 0;
  Timer? _timer;
  bool isUploadingImage = false;

  // Predefined colors for room backgrounds
  final List<Color> predefinedColors = [
    AppColor.red,
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
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
    Color(0xFF533483),
    Color(0xFF7209B7),
    Color(0xFF2D1B69),
    Color(0xFF11698E),
    Color(0xFF19A7CE),
  ];

  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    try {
      await _getUserRole();
      await _initAgora();
      _startUpdatingTimestamp();
      uId = _generateUnique15DigitInteger();
      await _storeUid();
      giftController.initializeGiftListener(widget.roomId);
    } catch (e) {
      print('Error initializing room: $e');
    }
  }

  Future<void> _getUserRole() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          userRole = userDoc['role'] ?? 'Participant';
        });
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
  }

  Future<void> _initAgora() async {
    try {
      String token = await _generateToken();

      var status = await [Permission.microphone].request();
      if (status[Permission.microphone] != PermissionStatus.granted) {
        print('Microphone permission not granted');
        return;
      }

      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

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
        ),
      );

      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine.enableAudio();

      await _engine.joinChannel(
        token: token,
        channelId: widget.channelId,
        uid: uId,
        options: const ChannelMediaOptions(),
      );

      _engine.enableLocalAudio(userRole != 'Participant');
    } catch (e) {
      print('Error initializing Agora: $e');
    }
  }

  Future<String> _generateToken() async {
    try {
      final token = await fetchAgoraToken(
        channelName: widget.channelId,
        uid: uId,
      );

      if (token != null && token.isNotEmpty) {
        return token;
      } else {
        throw Exception('Failed to generate Agora token');
      }
    } catch (e) {
      print('Error generating Agora token: $e');
      rethrow;
    }
  }

  int _generateUnique15DigitInteger() {
    Random random = Random();
    int randomPart = random.nextInt(9000000) + 1000000;
    int timestampPart = DateTime.now().millisecondsSinceEpoch;
    String uniqueIdString = '$timestampPart$randomPart';
    uniqueIdString = uniqueIdString.substring(0, 15);
    return int.parse(uniqueIdString);
  }

  Future<void> _storeUid() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference userDocRef = firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId);

      DocumentSnapshot userDoc = await userDocRef.get();
      if (userDoc.exists) {
        await userDocRef.set({'uId': uId}, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error storing UID: $e');
    }
  }

  void _startUpdatingTimestamp() {
    _updateTimestampIfUserExists();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _updateTimestampIfUserExists();
    });
  }

  Future<void> _updateTimestampIfUserExists() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference userDocRef = firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId);

      DocumentSnapshot userDoc = await userDocRef.get();
      if (userDoc.exists) {
        await userDocRef.set({
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating timestamp: $e');
    }
  }

  void _toggleMic(String userRole) {
    try {
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

            userDocRef.update({'isMicOn': newMicStatus}).then((_) {
              micController.isMicOn.value = newMicStatus;
              _engine.enableLocalAudio(newMicStatus);
            }).catchError((error) {
              print("Error updating mic status: $error");
            });
          }
        }
      }).catchError((error) {
        print("Error fetching user document: $error");
      });
    } catch (e) {
      print('Error toggling mic: $e');
    }
  }

  Future<void> _requestToSpeak() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('speakRequests')
          .doc(userId)
          .set({
        'isRequest': true,
        'name': user!.username,
        'image': user?.image ?? '',
      });
    } catch (e) {
      print('Error requesting to speak: $e');
    }
  }

  Future<void> _requestSeatChange(int targetSeatNumber) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      DocumentSnapshot userDoc = await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        Get.snackbar('Error', 'User not found in room',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      String userRole = userDoc['role'] ?? 'Participant';
      
      if (userRole != 'Admin' && userRole != 'Moderator') {
        Get.snackbar('Not Allowed', 'Only speakers can change seats',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({
            'seatPosition': targetSeatNumber,
            'seatChangedAt': FieldValue.serverTimestamp(),
          });
      
      Get.snackbar('Seat Changed', 'Moved to seat #$targetSeatNumber',
          backgroundColor: Colors.green, colorText: Colors.white, duration: Duration(seconds: 1));
    } catch (e) {
      print('Error changing seat: $e');
      Get.snackbar('Error', 'Failed to change seat',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _minimizeRoom() {
    try {
      _createMinimizedRoomOverlay();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserScreen(),
          settings: RouteSettings(name: '/user_from_room'),
        ),
      );
      
      Get.snackbar(
        'Room Minimized',
        'You\'re still connected to voice • Tap floating widget to return',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      print('Error minimizing room: $e');
      Navigator.push(context, MaterialPageRoute(builder: (context) => UserScreen()));
    }
  }

  void _createMinimizedRoomOverlay() async {
    try {
      DocumentSnapshot roomDoc = await firestore.collection('rooms').doc(widget.roomId).get();
      
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

      final roomData = {
        'roomName': widget.roomName,
        'roomDesc': widget.roomDesc,
        'roomId': widget.roomId,
        'channelId': widget.channelId,
      };

      final overlay = Overlay.of(context);
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => MinimizedRoomWidget(
          roomName: widget.roomName,
          roomId: widget.roomId,
          ownerImage: ownerImage,
          onTap: () {
            overlayEntry?.remove();
            Navigator.of(context).popUntil((route) {
              return route.settings.name == '/room' || 
                     route.isFirst ||
                     (route.settings.arguments != null && 
                      route.settings.arguments is Map &&
                      (route.settings.arguments as Map)['roomId'] == roomData['roomId']);
            });
          },
          onClose: () async {
            try {
              overlayEntry?.remove();
              await _disconnectAndLeaveRoom();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => UserScreen()),
                (route) => false,
              );
              Get.snackbar('Disconnected', 'You have left the room completely',
                  backgroundColor: Colors.orange, colorText: Colors.white);
            } catch (e) {
              print('Error disconnecting: $e');
            }
          },
        ),
      );

      overlay.insert(overlayEntry);
    } catch (e) {
      print('Error creating minimized overlay: $e');
    }
  }

  Future<void> _disconnectAndLeaveRoom() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await _engine.leaveChannel();
      await _engine.release();
      _timer?.cancel();
      await leaveRoom(userId, context, widget.roomId, user!.role);
    } catch (e) {
      print('Error disconnecting from room: $e');
      rethrow;
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
            Text("Send a Gift", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      _sendGift(gift['name'] as String, gift['asset'] as String, gift['cost'] as int);
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
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.card_giftcard, size: 30, color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(gift['name'] as String, style: TextStyle(fontSize: 9), textAlign: TextAlign.center),
                        Text('${gift['cost']} coins', 
                            style: TextStyle(fontSize: 8, color: AppColor.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
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

  // User management methods
  Future<void> _promoteToAdmin(String userId) async {
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({'role': 'Admin'});
      
      Get.snackbar('Success', 'User promoted to Admin',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('Error promoting user: $e');
      Get.snackbar('Error', 'Failed to promote user',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _demoteToParticipant(String userId) async {
    try {
      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({'role': 'Moderator'});
      
      Get.snackbar('Success', 'User demoted to Speaker',
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      print('Error demoting user: $e');
      Get.snackbar('Error', 'Failed to demote user',
          backgroundColor: Colors.red, colorText: Colors.white);
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
      
      Get.snackbar('Success', 'Speaking permission removed',
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      print('Error removing moderator permission: $e');
      Get.snackbar('Error', 'Failed to remove speaking permission',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _kickFromRoom(String userId) async {
    try {
      final roomRef = firestore.collection('rooms').doc(widget.roomId);
      WriteBatch batch = firestore.batch();
      
      batch.delete(roomRef.collection('joinedUsers').doc(userId));
      
      DocumentSnapshot roomDoc = await roomRef.get();
      if (roomDoc.exists) {
        var data = roomDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          List participants = List.from(data['participants'] ?? []);
          participants.remove(userId);
          batch.update(roomRef, {'participants': participants});
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error kicking user: $e');
    }
  }

  Future<void> _blockUser(String userId) async {
    try {
      final roomRef = firestore.collection('rooms').doc(widget.roomId);
      await roomRef.update({
        'blockedUsers': FieldValue.arrayUnion([userId])
      });
      await _kickFromRoom(userId);
    } catch (e) {
      print('Error blocking user: $e');
    }
  }

  void _navigateToUserScreen() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserScreen()));
  }

  @override
  void dispose() {
    try {
      _engine.leaveChannel();
      _engine.release();
      _timer?.cancel();
      if (user != null) {
        leaveRoom(widget.roomId, context, widget.roomId, user!.role);
      }
    } catch (e) {
      print('Error in dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('rooms').doc(widget.roomId).snapshots(),
        builder: (context, backgroundSnapshot) {
          return _buildRoomBackground(backgroundSnapshot, userId);
        },
      ),
    );
  }

  Widget _buildRoomBackground(AsyncSnapshot<DocumentSnapshot> backgroundSnapshot, String userId) {
    String? backgroundImageUrl;
    String? backgroundColor;
    
    if (backgroundSnapshot.hasData && backgroundSnapshot.data!.exists) {
      var roomData = backgroundSnapshot.data!.data() as Map<String, dynamic>?;
      backgroundImageUrl = roomData?['backgroundImage'] as String?;
      backgroundColor = roomData?['backgroundColor'] as String?;
    }

    Color? customColor = _getColorFromHex(backgroundColor);

    return AnimatedContainer(
      duration: Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        image: backgroundImageUrl != null
          ? DecorationImage(
              image: NetworkImage(backgroundImageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
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
                RoomTopBar(
                  onMinimize: _minimizeRoom,
                  onExit: () => RoomDialogs.showLeaveConfirmationDialog(
                    context, 
                    userId, 
                    widget.roomId, 
                    user?.role ?? 'Participant'
                  ),
                ),
                
                // Main Room Content
                Expanded(child: _buildMainRoomContent(userId)),
                
                // Bottom Bar
                _buildBottomBarSection(userId),
              ],
            ),
            
            // Gift overlay
            _buildGiftOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainRoomContent(String userId) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getRoomDocument(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text("Room not found", style: TextStyle(color: Colors.white)));
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection('rooms').doc(widget.roomId).snapshots(),
          builder: (context, roomSnapshot) {
            String? roomOwnerId;
            if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
              var roomData = roomSnapshot.data!.data() as Map<String, dynamic>?;
              roomOwnerId = roomData?['admin'] as String?;
            }

            return StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('joinedUsers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (!snapshot.hasData) {
                  return Center(child: Text("No users in this room", style: TextStyle(color: Colors.white)));
                }

                var userDocExists = snapshot.data!.docs.any((doc) => doc.id == userId);
                if (!userDocExists) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _navigateToUserScreen();
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
    );
  }

  Widget _buildRoomLayout(List<QueryDocumentSnapshot> allUsers, String? roomOwnerId) {
    var owner = allUsers.where((user) => user.id == roomOwnerId).toList();
    var admins = allUsers.where((user) => user['role'] == 'Admin' && user.id != roomOwnerId).toList();
    var moderators = allUsers.where((user) => user['role'] == 'Moderator').toList();
    var speakers = [...admins, ...moderators];

    return Column(
      children: [
        if (owner.isNotEmpty) 
          RoomOwnerSection(
            ownerDoc: owner.first,
            roomOwnerId: roomOwnerId,
            onLongPress: (userId, userRole) => RoomDialogs.showOptionsBottomSheet(
              context,
              widget.roomId,
              userId,
              userRole,
              _promoteToAdmin,
              _demoteToParticipant,
              _removeModeratorPermission,
              _kickFromRoom,
              _blockUser,
            ),
          ),
        
        SizedBox(height: 20),
        
        Expanded(
          child: RoomSeatsGrid(
            speakers: speakers,
            roomOwnerId: roomOwnerId,
            onLongPress: (userId, userRole) => RoomDialogs.showOptionsBottomSheet(
              context,
              widget.roomId,
              userId,
              userRole,
              _promoteToAdmin,
              _demoteToParticipant,
              _removeModeratorPermission,
              _kickFromRoom,
              _blockUser,
            ),
            onSeatTap: _requestSeatChange,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBarSection(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, roomSnapshot) {
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
            String userRole = 'Participant';
            bool isMicOn = false;
            bool isOwner = userId == roomOwnerId;

            if (snapshot.hasData && snapshot.data!.exists) {
              Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                userRole = data['role'] ?? 'Participant';
                isMicOn = data['isMicOn'] ?? false;
              }
            }

            return RoomBottomBar(
              roomId: widget.roomId,
              userId: userId,
              userRole: userRole,
              isMicOn: isMicOn,
              isOwner: isOwner,
              isUploadingImage: isUploadingImage,
              onMicToggle: () => _toggleMic(userRole),
              onShowGifts: _showGiftsBottomSheet,
              onShowUserManagement: () => RoomDialogs.showUserManagementBottomSheet(
                context,
                widget.roomId,
                (userId, userRole) => RoomDialogs.showOptionsBottomSheet(
                  context,
                  widget.roomId,
                  userId,
                  userRole,
                  _promoteToAdmin,
                  _demoteToParticipant,
                  _removeModeratorPermission,
                  _kickFromRoom,
                  _blockUser,
                ),
              ),
              onChangeBackground: () {}, // TODO: Implement background change
              onShowBottomSheet: () => RoomDialogs.showMicRequestBottomSheet(context, _requestToSpeak),
            );
          },
        );
      },
    );
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
                  scale: 0.3 + (value * 1.2),
                  child: Opacity(
                    opacity: value > 0.75 ? (1.0 - ((value - 0.75) * 4)) : 1.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          child: SvgPicture.asset(
                            giftController.currentGift.value!,
                            fit: BoxFit.contain,
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

  Color? _getColorFromHex(String? hexString) {
    if (hexString == null) return null;
    try {
      return Color(int.parse(hexString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  Future<DocumentSnapshot?> _getRoomDocument() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('roomId', isEqualTo: widget.roomId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
      print('Error getting room document: $e');
      return null;
    }
  }
} 