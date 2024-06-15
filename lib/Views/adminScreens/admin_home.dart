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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.red,
        onPressed: () {
          showCustomDialog(context: context);
        },
        child: Icon(Icons.add),
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
            Text(AppText.MyRoom , style: style(family: AppFOnts.gBold , size: 30 , ),),          SizedBox(height: space10,),


          Expanded(child: UsersRoomsList()),
        ],
      ),
    );
  }
}
