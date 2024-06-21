import 'package:flutter/material.dart';
import 'package:live_13/Config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/config/app_spacing.dart';
import 'package:live_13/config/app_theme.dart';
import 'package:live_13/constants/constant_text.dart';
import 'package:live_13/services/auth_service.dart';
import 'package:live_13/widgets/rool_list.dart';
import 'package:live_13/widgets/dialog_alert.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColor.red,
        onPressed: () {
          showCustomDialog(context: context);
        },
        label: Icon(Icons.add),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColor.red,
        actions: [
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
            Text(AppText.MyRoom, style: style(family: AppFonts.gBold , size: 30 , ),),
          SizedBox(height: space10,),
          Expanded(child: UsersRoomsList()),
        ],
      ),
    );
  }
}
