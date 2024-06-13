import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final String? initialValue;
  final TextInputType keyboardType;
  final bool obscureText;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: EdgeInsets.all(16.0),
      ),
    );
  }
}
