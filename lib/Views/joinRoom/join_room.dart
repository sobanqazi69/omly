import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_13/Config/app_spacing.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/services/leaving_room.dart';

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String roomDesc;

  RoomScreen({Key? key, required this.roomName, required this.roomDesc}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        title: Text(widget.roomName),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       leaveRoom(
        //         widget.roomName,
        //         FirebaseAuth.instance.currentUser!.uid,
        //         context,
        //         widget.roomDesc,
        //       );
        //     },
        //     icon: Icon(Icons.logout_outlined),
        //   ),
        // ],
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
],),
InkWell(
  onTap: (){
leaveRoom(
                widget.roomName,
                FirebaseAuth.instance.currentUser!.uid,
                context,
                widget.roomDesc,
              );
  },
  child: Text(AppText.Leave , style: style(family: AppFOnts.gBold,clr: AppColor.red , size: 20))),
          ],),
           
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
                                style: style(family: AppFOnts.gBold, size: 16),
                              ),
                              Text(
                                userRole,
                                style: style(family: AppFOnts.gMedium, size: 14),
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
          ],
        ),
      ),
    );
  }
}


