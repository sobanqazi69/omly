import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:live_13/Config/app_colors.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/Utils/custom_screen.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/constant_text.dart';
class SmallCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  SmallCustomButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: CustomScreenUtil.screenWidth * .35,
        height: CustomScreenUtil.screenHeight * .04,
        decoration: BoxDecoration(
            color: AppColor.red, borderRadius: BorderRadius.circular(20) ,),
        child: Center(
          child: Text(
            text,
            style: style(
              family: AppFOnts.gBold,
              size: Get.width* .04,
              clr: AppColor.white
            ),
          ),
        ),
      ),
    );
  }
}