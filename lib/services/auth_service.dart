import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_13/views/adminScreens/admin_home.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/views/userScreens/user_screen.dart';

class AuthService {
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final email = userCredential.user?.email;

      if (uid == 'w44C44KnLpYgcaaLqah2CFG4QU93') {
             CustomNavigator().pushTo(context, AdminScreen());

      } else {
             CustomNavigator().pushTo(context, UserScreen());

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => UserScreen()),
        // );
      }
    } on Exception catch (e) {
      // Handle exception
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