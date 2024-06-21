import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:live_13/services/speak_user_request.dart';
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
    "007eJxTYJCdxjdHj7eF11o5zzBpT8n/m9varVY0q/6P3d3qYJC6OVGBwcDQwsLQ1MDAIDU5ycQiKTUpOdXYLC3ZMjXVwsTC2CAl/l1uWkMgI4NV+GIGRigE8fkYSlKLS5IzEvPyUnMMjYwZGADrXSFE"; // Replace with your actual Agora Token

const reactions = ['laugh', 'cry', 'thumbs_up'];

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String roomDesc;
  final String roomId;

  RoomScreen(
      {Key? key,
        required this.roomName,
        required this.roomDesc,
        required this.roomId})
      : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {

  int? _remoteUid;
  bool isReceiver = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  late RtcEngine _engine;
  bool isMicOn = false;
  String userRole = 'Participant';

  @override
  void initState() {
    super.initState();
    initAgora();
    _getUserRole();
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


  Future<void> initAgora() async {
    var status = await [Permission.microphone].request();
    if (status[Permission.microphone] != PermissionStatus.granted) {
      print('Microphone permission not granted');
      return;
    }

    try {
      _engine = await RtcEngine.create(appId);
      await _engine.enableVideo();
      print('Agora engine initialized');
    } catch (e) {
      print('Error initializing Agora engine: $e');
      return;
    }



    // await _engine.setClientRole(ClientRole.Broadcaster);
    await _engine.enableAudio();
    debugPrint('Audio enabled');

    DocumentSnapshot? roomDoc = await _getRoomDocument();
    if (roomDoc == null) {
      print("Room document not found");
      return;
    }
    String channelId = roomDoc['channelId'];
    print("Channel ID: $channelId");
    int uid = generateUnique15DigitInteger();
    await _engine.joinChannel(token, channelId, null, 0);

    debugPrint('Joined channel: testchannel123');

  }

  int generateUnique15DigitInteger() {
    Random random = Random();

    int randomPart = random.nextInt(9000000) + 1000000;
    int timestampPart = DateTime.now().millisecondsSinceEpoch;

    String uniqueIdString = '$timestampPart$randomPart';

    uniqueIdString = uniqueIdString.substring(0, 15);

    return int.parse(uniqueIdString);
  }

  Future<DocumentSnapshot?> _getRoomDocument() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .where('roomId', isEqualTo: widget.roomId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  void _toggleMic(String? role) {
    if (role != 'Admin' || role == 'Moderator') {
      setState(() {
        isMicOn = !isMicOn;
      });
      print("Toggling mic. New state: ${isMicOn ? 'ON' : 'OFF'}");
      _engine.muteLocalAudioStream(!isMicOn).then((value) {
        print("muteLocalAudioStream called with: ${!isMicOn}");
      }).catchError((error) {
        print("Error in muteLocalAudioStream: $error");
      });
    } else {
      _showBottomSheet();
      print("Access Denied. Microphone state: ${isMicOn ? 'ON' : 'OFF'}");
    }
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

  Future<void> _requestToSpeak() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userName = user.displayName ?? 'Unknown';
      String userImage = user.photoURL ?? '';

      await firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('speakRequests')
          .doc(userId)
          .set({
        'isRequest': true,
        'name': userName,
        'image': userImage,
      });
    } else {
      print('No user signed in');
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    leaveRoom(widget.roomName, widget.roomId, context, widget.roomDesc  ,widget.roomId);
    super.dispose();
  }

  void showOptionsBottomSheet(
      BuildContext context, String userId, String userRole) {
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
              ListTile(
                leading: Icon(Icons.remove_circle_outline),
                title: Text('Remove from Moderator'),
                onTap: () {
                  _removeFromModerator(userId);
                  Navigator.pop(context);
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.remove_circle),
              //   title: Text('Kick from Room'),
              //   onTap: () {
              //     _kickFromRoom(userId);
              //     Navigator.pop(context);
              //   },
              // ),
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
    await firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('joinedUsers')
        .doc(userId)
        .delete();
  }

  void _sendReaction(String reaction) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('joinedUsers')
        .doc(userId)
        .update({'latestReaction': reaction});

    // Clear the reaction after 1 second
    Future.delayed(Duration(seconds: 2), () {
      firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('joinedUsers')
          .doc(userId)
          .update({'latestReaction': FieldValue.delete()});
    });
  }

  void _showReactionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: reactions.map((reaction) {
            return ListTile(
              leading: _getReactionIcon(reaction),
              title: Text(reaction),
              onTap: () {
                _sendReaction(reaction);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getReactionIcon(String reaction) {
    switch (reaction) {
      case 'laugh':
        return AnimatedEmoji(
          AnimatedEmojis.laughing,
          size: 68,
          animate: true,
          repeat: true,
        );
    // return Icon(
    //   Icons.emoji_emotions,
    //   color: Colors.yellow,
    //   size: 30,
    // );
      case 'cry':
        return AnimatedEmoji(
          AnimatedEmojis.cry,
          size: 65,
          animate: true,
          repeat: true,
        );
      case 'thumbs_up':
        return AnimatedEmoji(
          AnimatedEmojis.thumbsUp,
          size: 65,
          animate: true,
          repeat: true,
        );
      default:
        return Icon(
          Icons.emoji_emotions,
          color: Colors.yellow,
          size: 30,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;
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
                      style: style(family: AppFonts.gBold, size: 30),
                    ),
                    SizedBox(height: space4),
                    Text(
                      widget.roomDesc,
                      style: style(family: AppFonts.gMedium, size: 18),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {

                    // Example usage: Check and delete the room if it has no participants
                    leaveRoom(
                        widget.roomName,
                        FirebaseAuth.instance.currentUser!.uid,
                        context,
                        widget.roomDesc,
                        widget.roomId
                    );
                  },
                  child: Text(
                    AppText.Leave,
                    style: style(
                        family: AppFonts.gBold, clr: AppColor.red, size: 20),
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
                          crossAxisCount: 3,
                          // mainAxisSpacing: 1.0,
                          //crossAxisSpacing: 10.0,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var userDoc = filteredDocs[index];
                          var userName = userDoc['name'];
                          var userImage = userDoc['image'];
                          var userRole = userDoc['role'];
                          var data = userDoc.data() as Map<String, dynamic>?;
                          var latestReaction =
                          data != null && data.containsKey('latestReaction')
                              ? data['latestReaction']
                              : null;

                          return Column(
                            children: [
                              InkWell(
                                onLongPress: () {

                                  showOptionsBottomSheet(
                                      context, userDoc.id, userRole);
                                },
                                child: Stack(
                                  children: [
                                    Center(
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundImage:
                                        NetworkImage(userImage),
                                        child: (latestReaction != null) ?  _getReactionIcon(latestReaction) :SizedBox(),
                                      ),
                                    ),
                                    // if (latestReaction != null)
                                    //   Center(
                                    //       child:
                                    //           _getReactionIcon(latestReaction)),
                                  ],
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
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text('User data not found');
                }
                var userRole = snapshot.data!['role'];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        _showReactionsBottomSheet();
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColor.black,
                            ),
                            shape: BoxShape.circle,
                            color:
                            const Color.fromARGB(140, 158, 158, 158)),
                        child: Icon(
                          Icons.emoji_emotions,
                          size: 25,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: InkWell(
                        onTap: () {
                          _toggleMic(userRole);
                        },
                        child: Container(
                          padding: EdgeInsets.all(18),
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: isMicOn ? AppColor.red : AppColor.black,
                              ),
                              shape: BoxShape.circle,
                              color: const Color.fromARGB(140, 158, 158, 158)),
                          child: Icon(
                            (userRole == 'Participant')
                                ? Icons.mic_off
                                : Icons.mic,
                            size: 35,
                            color: isMicOn ? AppColor.red : AppColor.black,
                          ),
                        ),
                      ),
                    ),
                    (userRole == 'Admin')
                        ? InkWell(
                      onTap: () {
                        showSpeakRequestsDialog(context, widget.roomId);
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColor.black,
                            ),
                            shape: BoxShape.circle,
                            color:
                            const Color.fromARGB(140, 158, 158, 158)),
                        child: Icon(
                          Icons.add_alert,
                          size: 25,
                        ),
                      ),
                    )
                        : SizedBox()
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
