import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:live_13/config/app_theme.dart';
import 'package:live_13/Utils/custom_screen.dart';
import 'package:live_13/firebase_options.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/views/splashScreen/splash_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
     CustomScreenUtil.init(context);
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      title: 'Live 13',
      home: SplashScreen()
    );
  }
}
