import 'package:flutter/material.dart';

class CustomNavigator {
  void pushTo(BuildContext context, Widget widget) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget),
    );
  }
}