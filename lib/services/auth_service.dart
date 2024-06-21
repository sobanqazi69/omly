import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:live_13/constants/constants.dart';
import 'package:live_13/services/databaseService/database_services.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';


class AuthService {

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = FirebaseAuth.instance.currentUser;

      if(user!=null){
        Map<String,dynamic> userData = {
          'email': user.email,
          'role': 'Participant',
          'name': user.displayName,
          'userId': user.uid
        };
        DatabaseServices().saveUserData(userData);
        if (user.uid == kAdminUid) {
          CustomNavigator().pushTo(context, AdminScreen());
        } else {
          CustomNavigator().pushTo(context, UserScreen());
        }
      }
      else {
        AuthService().signInWithGoogle(context);
        Get.snackbar('Error', 'Unable to login, try again later', backgroundColor: HexColor('#cccccc'));
      }

    } on Exception catch (e) {
      print('exception->$e');
    }
  }

  Future<bool> signOutFromGoogle(BuildContext context) async {
    try {
     final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
     await googleSignIn.signOut();
     FirebaseAuth.instance.signOut();
     
      CustomNavigator().pushTo(context, welcomeScreen());
     
      return true;
    } on Exception catch (_) {
      return false;
    }
  }
}