import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/services/fetch_rooms.dart';
import 'package:live_13/services/join_room.dart';

class UsersRoomsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No rooms found'));
          } else {
            List<Map<String, dynamic>> rooms = snapshot.data!;
            return ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final roomName = room['roomName'];
                final description = room['description'];
                final createdAt = room['createdAt']?.toDate(); // Assuming createdAt is a Timestamp
                final interests = room['interests'];
                final participants = room['participants'];
                final participantsCount = participants.length;

                return InkWell(
                  onTap: () async {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await joinRoom(roomName, user.uid , context , description);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                    child: Container(
                      height: Get.height * .23,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(217, 244, 67, 54),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 20, top: 10),
                                child: Text(
                                  'Live',
                                  style: style(
                                    clr: AppColor.white,
                                    family: AppFOnts.gMedium,
                                    size: 16,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20, top: 10),
                                child: Text(
                                  roomName,
                                  style: style(
                                    size: 28,
                                    clr: AppColor.white,
                                    family: AppFOnts.gBold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                                child: Text(
                                  '$participantsCount Members Joined',
                                  style: style(
                                    size: 20,
                                    clr: AppColor.white,
                                    family: AppFOnts.gMedium,
                                  ),
                                ),
                              ),
                              Container(width: double.infinity, height: 2, color: AppColor.white),
                              Padding(
                                padding: const EdgeInsets.only(left: 20, top: 10),
                                child: Wrap(
                                  spacing: 8.0,
                                  children: interests.map<Widget>((interest) {
                                    return Chip(
                                      label: Text(
                                        '#' + interest,
                                        style: style(family: AppFOnts.gMedium, size: 18),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
