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
import 'package:live_13/views/userNameScreen/user_name_screen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';
import '../constants/constant_text.dart';
import '../constants/constants.dart';


class LoginCheck {

  Future<void> checkLoginStatus(BuildContext context) async {
    await Future.delayed(Duration(seconds: 2));
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DatabaseServices databaseServices = DatabaseServices();
      DocumentSnapshot userDoc = await databaseServices.getUserData(user.uid);

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('isBlocked') && userData['isBlocked']) {
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

        // Check if username is set and not empty
        if (userData.containsKey('username') && userData['username'].toString().isNotEmpty) {
          if (user.uid == kAdminUid) {
            CustomNavigator().pushReplacement(context, SuperAdminScreen());
          } else if (userData['role'] == 'Admin') {
            CustomNavigator().pushReplacement(context, AdminScreen());
          } else {
            CustomNavigator().pushReplacement(context, UserScreen());
          }
        } else {
          // Navigate to UserNameScreen if username is not set or empty
          CustomNavigator().pushReplacement(context, UserNameScreen(navigationInteger: 1));
        }
      } else {
        // If userDoc does not exist or is null, also navigate to UserNameScreen
        CustomNavigator().pushReplacement(context, UserNameScreen(navigationInteger: 1));
      }
    } else {
      CustomNavigator().pushReplacement(context, welcomeScreen());
    }
  }
}