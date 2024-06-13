import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

class LoginCheck {
  static const String adminUid = 'w44C44KnLpYgcaaLqah2CFG4QU93';

   Future<void> checkLoginStatus( BuildContext context) async {
    // Simulate a delay for splash screen (e.g., 2 seconds)
    await Future.delayed(Duration(seconds: 2));

    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, navigate to main screen
      if (user.uid == adminUid) {
        // Navigate to admin screen
        CustomNavigator().pushTo(context, AdminScreen());
      } else {
        // Navigate to user screen
       CustomNavigator().pushTo(context, UserScreen());
      }
     
    } else {
      CustomNavigator().pushTo(context, welcomeScreen());
      
    }
  }
}