import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/Config/app_theme.dart';

class RoomSeatsGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> speakers;
  final String? roomOwnerId;
  final Function(String userId, String userRole) onLongPress;
  final Function(int seatNumber) onSeatTap;

  const RoomSeatsGrid({
    Key? key,
    required this.speakers,
    required this.roomOwnerId,
    required this.onLongPress,
    required this.onSeatTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          _assignToNextAvailableSeat(seatMap, speaker);
        }
      } else {
        // No preferred seat, auto-assign to first available
        _assignToNextAvailableSeat(seatMap, speaker);
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
            return OccupiedSeat(
              userDoc: speaker,
              seatNumber: seatNumber,
              roomOwnerId: roomOwnerId,
              onLongPress: onLongPress,
            );
          } else {
            // Empty seat
            return EmptySeat(
              seatNumber: seatNumber,
              onTap: onSeatTap,
            );
          }
        },
      ),
    );
  }

  void _assignToNextAvailableSeat(Map<int, QueryDocumentSnapshot> seatMap, QueryDocumentSnapshot speaker) {
    for (int j = 1; j <= 40; j++) {
      if (!seatMap.containsKey(j)) {
        seatMap[j] = speaker;
        break;
      }
    }
  }
}

class OccupiedSeat extends StatelessWidget {
  final QueryDocumentSnapshot userDoc;
  final int seatNumber;
  final String? roomOwnerId;
  final Function(String userId, String userRole) onLongPress;

  const OccupiedSeat({
    Key? key,
    required this.userDoc,
    required this.seatNumber,
    required this.roomOwnerId,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    String role = data['role'] ?? 'Participant';
    bool isModerator = role == 'Moderator';
    bool isAdmin = role == 'Admin';
    bool isMicOn = data.containsKey('isMicOn') ? (data['isMicOn'] ?? false) : false;
    
    return Column(
      children: [
        InkWell(
          onLongPress: () {
            onLongPress(userDoc.id, userDoc['role']);
          },
          child: Stack(
            children: [
              _buildUserAvatar(isMicOn, isModerator, isAdmin),
              if (isModerator) _buildModeratorIndicator(),
              if (isAdmin) _buildAdminIndicator(),
              _buildMicStatusIndicator(isMicOn),
            ],
          ),
        ),
        SizedBox(height: 2),
        _buildUsername(),
      ],
    );
  }

  Widget _buildUserAvatar(bool isMicOn, bool isModerator, bool isAdmin) {
    return AnimatedContainer(
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
    );
  }

  Widget _buildModeratorIndicator() {
    return Positioned(
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
    );
  }

  Widget _buildAdminIndicator() {
    return Positioned(
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
    );
  }

  Widget _buildMicStatusIndicator(bool isMicOn) {
    return Positioned(
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
    );
  }

  Widget _buildUsername() {
    return Container(
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
    );
  }
}

class EmptySeat extends StatelessWidget {
  final int seatNumber;
  final Function(int seatNumber) onTap;

  const EmptySeat({
    Key? key,
    required this.seatNumber,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap(seatNumber);
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
} 