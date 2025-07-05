import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_13/config/app_colors.dart';

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
            _buildOwnerAvatar(),
            // Room info with animated text
            Expanded(
              child: _buildRoomInfo(),
            ),
            // Close button
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerAvatar() {
    return Container(
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
    );
  }

  Widget _buildRoomInfo() {
    return Column(
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
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
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
    );
  }
} 