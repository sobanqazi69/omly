import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_13/Config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/config/app_spacing.dart';
import 'package:live_13/config/app_theme.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/services/auth_service.dart';
import 'package:live_13/widgets/rool_list.dart';
import 'package:live_13/widgets/dialog_alert.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
     UserModel? userr = userData.currentUser;
          User? user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.red,
        actions: [
                    Center(child: Text(userr?.username ?? user!.displayName ?? 'Unknow User' , style: TextStyle(fontFamily: AppFonts.gMedium , fontSize: 16, letterSpacing: 1),)),

          IconButton(
              onPressed: () {
                AuthService().signOutFromGoogle(context);
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: space10,),
            Text(AppText.JoinAnyRoom , style: style(family: AppFonts.gBold , size: 30 , ),),          SizedBox(height: space10,),
          Expanded(child: UsersRoomsList()),
        ],
      ),
    );
  }
}
