
import 'package:flutter/material.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/services/databaseService/database_services.dart';
import 'package:live_13/services/login_check.dart';
import 'package:live_13/utils/custom_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
    final DatabaseServices _firestoreService = DatabaseServices();


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    loginCheck();
  }
 void loginCheck(){
 LoginCheck().checkLoginStatus(context);
 }
 Future<void> _fetchUserData() async {
    UserModel? user = await _firestoreService.getCurrentUserData();
    if (user != null) {
      userData.currentUser = user;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Image.asset(
            'assets/Logo.jpeg',
           // width: CustomScreenUtil.screenWidth* .8,
          ),
        ),
      ),
    );
  }
}
