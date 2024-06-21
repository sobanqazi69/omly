import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

import '../constants/constants.dart';

class LoginCheck {

   Future<void> checkLoginStatus( BuildContext context) async {
    // Simulate a delay for splash screen (e.g., 2 seconds)
    await Future.delayed(Duration(seconds: 2));

    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      CustomNavigator().pushTo(context, UserScreen());
      if (user.uid == kAdminUid) {
        CustomNavigator().pushTo(context, AdminScreen());
      } else {
       CustomNavigator().pushTo(context, UserScreen());
      }
    } else {
      CustomNavigator().pushTo(context, welcomeScreen());
    }
  }
}