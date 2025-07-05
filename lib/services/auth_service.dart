import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:live_13/constants/constants.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/services/databaseService/database_services.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/views/splashScreen/splash_screen.dart';
import 'package:live_13/views/userNameScreen/user_name_screen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

import '../constants/constant_text.dart';
import '../views/superAdmin/super_admin_screen.dart';


class AuthService {
      final DatabaseServices _firestoreService = DatabaseServices();



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

      await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = FirebaseAuth.instance.currentUser;

      if(user!=null){
        Map<String,dynamic> userDataToSave = {
          'email': user.email,
          'role': 'Admin',
          'name': user.displayName,
          'userId': user.uid,
          'image': user.photoURL,
          'coins': 1000  // Give new users 1000 starter coins
        };
        await DatabaseServices().saveUserData(userDataToSave);
        DocumentSnapshot userDoc = await DatabaseServices().getUserData(user.uid);
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String userRole = userData.containsKey('role')?userData['role']:'Participant';

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String,
              dynamic>;
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
        }
        
        if (userData.containsKey('username') && userData['username'].toString().isNotEmpty) {
          if(user.uid == kAdminUid){
            CustomNavigator().pushReplacement(context, SuperAdminScreen());
          }
          else if (userRole == 'Admin') {
            CustomNavigator().pushTo(context, SplashScreen());
          } else {
            CustomNavigator().pushReplacement(context, SplashScreen());
          }
        }
        else {
          CustomNavigator().pushReplacement(context, UserNameScreen(navigationInteger: 1));
        }
              _fetchUserData();


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
     
      CustomNavigator().pushReplacement(context, welcomeScreen());
     
      return true;
    } on Exception catch (_) {
      return false;
    }
  }
  Future<void> _fetchUserData() async {
    UserModel? user = await _firestoreService.getCurrentUserData();
    if (user != null) {
      userData.currentUser = user;
    }
  }
}