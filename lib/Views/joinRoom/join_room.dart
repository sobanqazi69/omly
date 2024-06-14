import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:live_13/Config/app_spacing.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/services/leaving_room.dart';

const appId =
    "018815000ecb48bebce36fc9ee84830d"; // Replace with your actual Agora App ID
const token =
    "007eJxTYGiTuLyDkSmyb8oLoW3pa75uybTZkvfxWle7+ZvfKx/f0Y5WYDAwtLAwNDUwMEhNTjKxSEpNSk41NktLtkxNtTCxMDZIMZXOTmsIZGT4taGCiZEBAkF8ZgZDI2MGBgC3iyBz"; // Replace with your actual Agora Token

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String roomDesc;

  RoomScreen({Key? key, required this.roomName, required this.roomDesc})
      : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  int? _remoteUid;
  bool isReceiver = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  late RtcEngine _engine;
  bool isMicOn = true;
  bool _localUserJoined = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _initializeRtcEngine();
  // }

  // Future<void> _initializeRtcEngine() async {
  //   // Request permissions
  //   if (!kIsWeb) {
  //     var status = await [Permission.microphone].request();
  //     if (status[Permission.microphone] != PermissionStatus.granted ) {
  //       print('Microphone or Camera permission not granted');
  //       return;
  //     }
  //   }

  //   try {
  //     // Create Agora engine
  //     _engine = createAgoraRtcEngine();
  //     await _engine.initialize(RtcEngineContext(
  //       appId: appId,
  //       channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
  //     ));

  //     // Register event handlers
  //     _engine.registerEventHandler(RtcEngineEventHandler(
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         print("Local user ${connection.localUid} joined");
  //         if (mounted) {
  //           setState(() {
  //             _localUserJoined = true;
  //           });
  //         }
  //       },
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         print("Remote user $remoteUid joined");
  //         if (mounted) {
  //           setState(() {
  //             _remoteUid = remoteUid;
  //           });
  //         }
  //       },
  //       onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
  //         print("Remote user $remoteUid left channel");
  //         if (mounted) {
  //           Get.back();
  //         }
  //       },
  //     ));

  //     await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  //     await _engine.enableVideo();

  //     if (!isReceiver) {
  //       await _startPreviewAndJoinChannel();
  //     }
  //   } catch (e) {
  //     print("RtcEngine initialization error: $e");
  //   }
  // }

  // Future<void> _startPreviewAndJoinChannel() async {
  //   try {
  // DocumentSnapshot? roomDoc = await _getRoomDocument();
  // if (roomDoc == null) {
  //   print("Room document not found");
  //   return;
  // }
  // String channelId = roomDoc['channelId'];
  // print(channelId);

  //     await _engine.startPreview();
  //     await _engine.joinChannel(
  //       token: token,
  //       channelId: channelId,
  //       uid: 0,
  //       options: const ChannelMediaOptions(),
  //     );
  //   } catch (e) {
  //     print("Error starting preview and joining channel: $e");
  //   }
  // }

  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await Permission.microphone.request();

    //create the engine
    _engine = createAgoraRtcEngine();
    try {
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      print('donee');
    } catch (e) {
      print('eror' + e.toString());
    }

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();
    DocumentSnapshot? roomDoc = await _getRoomDocument();
    if (roomDoc == null) {
      print("Room document not found");
      return;
    }
    String channelId = roomDoc['channelId'];
    print(channelId);

    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<DocumentSnapshot?> _getRoomDocument() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .where('roomName', isEqualTo: widget.roomName)
        .where('description', isEqualTo: widget.roomDesc)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: style(family: AppFOnts.gBold, size: 30),
                    ),
                    SizedBox(height: space4),
                    Text(
                      widget.roomDesc,
                      style: style(family: AppFOnts.gMedium, size: 18),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    leaveRoom(
                      widget.roomName,
                      FirebaseAuth.instance.currentUser!.uid,
                      context,
                      widget.roomDesc,
                    );
                  },
                  child: Text(
                    AppText.Leave,
                    style: style(
                        family: AppFOnts.gBold, clr: AppColor.red, size: 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: space20),
            Expanded(
              child: FutureBuilder<DocumentSnapshot?>(
                future: _getRoomDocument(),
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

                      var filteredDocs = snapshot.data!.docs;

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Number of columns
                          mainAxisSpacing: 10.0,
                          crossAxisSpacing: 10.0,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var userDoc = filteredDocs[index];
                          var userName = userDoc['name'];
                          var userImage = userDoc['image'];
                          var userRole = userDoc['role'];

                          return Column(
                            children: [
                              CircleAvatar(
                                radius: 35, // Adjust as needed
                                backgroundImage: NetworkImage(userImage),
                              ),
                              SizedBox(height: space2),
                              Text(
                                userName,
                                style: style(family: AppFOnts.gBold, size: 14),
                              ),
                              Text(
                                userRole,
                                style:
                                    style(family: AppFOnts.gMedium, size: 12),
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
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: IconButton(
            //     icon: Icon(isMicOn ? Icons.mic : Icons.mic_off),
            //     onPressed: () {
            //       setState(() {
            //         isMicOn = !isMicOn;
            //       });
            //       _engine.muteLocalAudioStream(!isMicOn);
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
