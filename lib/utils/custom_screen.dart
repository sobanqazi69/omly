import 'package:flutter/widgets.dart';

class CustomScreenUtil {
  static late double screenWidth;
  static late double screenHeight;

  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  static double getWidthDimensions(double ratio) {
    return screenWidth * ratio;
  }

  static double getHeightDimensions(double ratio) {
    return screenHeight * ratio;
  }
}
