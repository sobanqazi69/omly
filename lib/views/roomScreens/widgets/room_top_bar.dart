import 'package:flutter/material.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/Config/app_theme.dart';

class RoomTopBar extends StatelessWidget {
  final VoidCallback onMinimize;
  final VoidCallback onExit;

  const RoomTopBar({
    Key? key,
    required this.onMinimize,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildMinimizeButton(),
              SizedBox(width: 8),
              _buildMicStatusLegend(),
            ],
          ),
          _buildExitButton(),
        ],
      ),
    );
  }

  Widget _buildMinimizeButton() {
    return InkWell(
      onTap: onMinimize,
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
    );
  }

  Widget _buildMicStatusLegend() {
    return Container(
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
    );
  }

  Widget _buildExitButton() {
    return InkWell(
      onTap: onExit,
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
    );
  }
} 