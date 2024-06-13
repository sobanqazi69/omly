import 'package:flutter/material.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/commonWidgets/customElevedButton.dart';
import 'package:live_13/Config/app_colors.dart';
import 'package:live_13/Config/app_spacing.dart';
import 'package:live_13/Utils/custom_screen.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/services/auth_service.dart';

class welcomeScreen extends StatefulWidget {
  const welcomeScreen({super.key});

  @override
  State<welcomeScreen> createState() => _welcomeScreenState();
}

class _welcomeScreenState extends State<welcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/welcome.png',
              width: CustomScreenUtil.screenWidth * .8),
          SizedBox(
            height: space20,
          ),
          Text(
            textAlign: TextAlign.center,
            AppText.LetsMeetingNewPeopleAroundYou,
            style: style(family: AppFOnts.gBold, size: CustomScreenUtil.screenWidth * .09),
          ),
          SizedBox(
            height: space15,
          ),
          CustomButton(
            onPressed: () {AuthService().signInWithGoogle(context);},
            color: AppColor.red,
            icon: 'assets/Google.png',
            text: AppText.LoginWithPhone,
            borderRadius: 30.0,
          ),
        ],
      )),
    );
  }



}
