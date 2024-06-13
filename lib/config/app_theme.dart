import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData appTheme = ThemeData(
  colorScheme: colorScheme,
  appBarTheme: appBarTheme,
  useMaterial3: false,
  iconTheme: iconThemeData,
  // listTileTheme: listTileTheme,
  // cardTheme: appCardTheme,
  // bottomAppBarTheme: bottomAppBarTheme,
  // bottomNavigationBarTheme: bottomNavigationBarTheme,
  // outlinedButtonTheme: outlinedButtonThemeData,
  // textButtonTheme: textButtonTheme,
  // scaffoldBackgroundColor: AppColor.ghostWhite,
  // elevatedButtonTheme: elevatedButtonThemeData,
  // floatingActionButtonTheme: floatingActionButtonThemeData,
  // expansionTileTheme: expansionTileThemeData,
  // iconButtonTheme: iconButtonThemeData,
);

ColorScheme colorScheme = ColorScheme.light(primary: AppColor.red);

AppBarTheme appBarTheme = AppBarTheme(
    elevation: 0, backgroundColor: AppColor.white, iconTheme: iconThemeData);
IconThemeData iconThemeData = IconThemeData(color: AppColor.black);
TextStyle style({
  FontWeight fontWeight = FontWeight.w400, 
  double? height, 
  Color? clr, 
  double size = 14.0, // Default value for size
  String? family
}) {
  return TextStyle(
    fontWeight: fontWeight,
    height: height,
    fontFamily: family,
    fontSize: size,
    color: clr,
  );
}



