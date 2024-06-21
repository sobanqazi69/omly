import 'package:flutter/material.dart';
import 'package:live_13/Utils/custom_screen.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/config/app_theme.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final String icon;
  final String text;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.color,
    required this.icon,
    required this.text,
    this.borderRadius = 8.0, // Default border radius
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CustomScreenUtil.screenWidth * .8,
      height:CustomScreenUtil.screenHeight* .07 ,
      child: ElevatedButton(
        
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           Image.asset(icon),

            const SizedBox(width: 10),
            Text(
              text,
              style:style(family: AppFonts.gBold , size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
