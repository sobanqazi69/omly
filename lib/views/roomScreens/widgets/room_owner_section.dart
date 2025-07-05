import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/Config/app_theme.dart';

class RoomOwnerSection extends StatelessWidget {
  final QueryDocumentSnapshot ownerDoc;
  final String? roomOwnerId;
  final Function(String userId, String userRole) onLongPress;

  const RoomOwnerSection({
    Key? key,
    required this.ownerDoc,
    required this.roomOwnerId,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = ownerDoc.data() as Map<String, dynamic>;
    bool isMicOn = data.containsKey('isMicOn') ? (data['isMicOn'] ?? false) : false;
    
    return Column(
      children: [
        InkWell(
          onLongPress: () {
            debugPrint('Owner ID: ${ownerDoc.id}');
            onLongPress(ownerDoc.id, ownerDoc['role']);
          },
          child: Stack(
            children: [
              _buildOwnerAvatar(isMicOn),
              _buildMicStatusIndicator(isMicOn),
            ],
          ),
        ),
        SizedBox(height: 8),
        _buildOwnerTitle(),
        SizedBox(height: 2),
        _buildOwnerName(),
      ],
    );
  }

  Widget _buildOwnerAvatar(bool isMicOn) {
    return AnimatedContainer(
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
    );
  }

  Widget _buildMicStatusIndicator(bool isMicOn) {
    return Positioned(
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
    );
  }

  Widget _buildOwnerTitle() {
    return Text(
      'Group Owner',
      style: style(
        family: AppFonts.gBold,
        size: 16,
        clr: Colors.white,
      ),
    );
  }

  Widget _buildOwnerName() {
    return Text(
      ownerDoc['username'],
      style: style(
        family: AppFonts.gMedium,
        size: 12,
        clr: Colors.white70,
      ),
    );
  }
} 