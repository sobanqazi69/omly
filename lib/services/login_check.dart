import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:live_13/services/databaseService/database_services.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/views/superAdmin/super_admin_screen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

import '../constants/constant_text.dart';
import '../constants/constants.dart';

class LoginCheck {

  Future<void> checkLoginStatus(BuildContext context) async {
    await Future.delayed(Duration(seconds: 2));
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (user.uid == kAdminUid) {
        CustomNavigator().pushTo(context, SuperAdminScreen());
      } else {
        DatabaseServices databaseServices = DatabaseServices();
        DocumentSnapshot userDoc = await databaseServices.getUserData(user.uid);

        if (userDoc.exists && userDoc.data()!=null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String userRole = userData.containsKey('role')?userData['role']:'Participant';
         if(userData.containsKey('isBlocked') && userData['isBlocked'])
           {
             Get.snackbar(
               AppText.error,
               AppText.yourAccountHasBeenBlocked,
               backgroundColor: HexColor('#cccccc'),
             );
             Future.delayed(Duration(seconds: 2), () {
               SystemNavigator.pop();
             });
             return;
           }
          else if (userRole == 'Admin') {
            CustomNavigator().pushTo(context, AdminScreen());
          } else {
            CustomNavigator().pushTo(context, UserScreen());
          }
        } else {
          CustomNavigator().pushTo(context, UserScreen());
        }
      }
    } else {
      CustomNavigator().pushTo(context, welcomeScreen());
    }
  }
}