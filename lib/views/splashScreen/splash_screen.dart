
import 'package:flutter/material.dart';
import 'package:live_13/services/login_check.dart';
import 'package:live_13/utils/custom_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    loginCheck();
  }
 void loginCheck(){
 LoginCheck().checkLoginStatus(context);
 }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Image.asset(
            'assets/Logo.png',
           // width: CustomScreenUtil.screenWidth* .8,
          ),
        ),
      ),
    );
  }
}
