// ignore_for_file: prefer_const_constructors

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:live_13/config/app_theme.dart';
import 'package:live_13/Utils/custom_screen.dart';
import 'package:live_13/services/delete_room.dart';
import 'package:live_13/views/authScreens/welcomeScreen.dart';
import 'package:live_13/firebase_options.dart';
import 'package:live_13/views/splashScreen.dart/splash_screen.dart';

Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(    options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     CustomScreenUtil.init(context);
    return GetMaterialApp(

      debugShowCheckedModeBanner: false,
      theme: appTheme,
      title: 'Flutter Demo',
      home: SplashScreen()
    );
  }
}
