import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:live_13/config/app_fonts.dart';
import '../../config/app_colors.dart';
import '../../navigations/navigator.dart';
import '../../services/auth_service.dart';
import '../adminScreens/admin_home.dart';
import '../userScreens/user_screen.dart';

class UserNameScreen extends StatefulWidget {
  final int navigationInteger;
  const UserNameScreen({super.key, required this.navigationInteger});

  @override
  State<UserNameScreen> createState() => _UserNameScreenState();
}

class _UserNameScreenState extends State<UserNameScreen> {
  TextEditingController controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> usernames = [];
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchUsernames();
  }

  Future<void> fetchUsernames() async {
    final querySnapshot = await _firestore.collection('Users').get();
    for (var doc in querySnapshot.docs) {
      if(doc.data().containsKey('username')) {
        usernames.add(doc.data()['username'] as String);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.red,
        actions: [
          IconButton(
              onPressed: () {
                AuthService().signOutFromGoogle(context);
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter your username', style: TextStyle(fontFamily: AppFonts.gBold, color: Colors.black, fontSize: 22)),
            SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Enter Username',
                errorText: error.isNotEmpty ? error : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.red),
                ),
                suffixIcon: controller.text.isEmpty
                    ? Container(width: 0)
                    : IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => controller.clear(),
                ),
              ),
              onChanged: (value) {
                if (RegExp(r'^[A-Za-z0-9_.-]{4,30}$').hasMatch(value.trim())) {
                  setState(() {
                    error = '';
                  });
                } else {
                  if (value.length < 4) {
                    setState(() {
                      error = 'Username can\'t be less than 4 characters';
                    });
                  } else {
                    setState(() {
                      error = 'Username only accepts letters, numbers, periods, and underscores and should be 4-30 characters long';
                    });
                  }
                }
              },
            ),
            SizedBox(height: 20),
            if (controller.text.isNotEmpty && error.isEmpty)
              Text(
                usernames.contains(controller.text) ? 'Username is taken' : 'Username is available',
                style: TextStyle(color: usernames.contains(controller.text) ? Colors.red : Colors.green),
              ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: controller.text.isNotEmpty && !usernames.contains(controller.text) && error.isEmpty
                  ? () async {
                String userId = FirebaseAuth.instance.currentUser!.uid;
                await _firestore.collection('Users').doc(userId).update({
                  'username': controller.text
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Username updated successfully!"),
                    duration: Duration(seconds: 2),
                  ),
                );
                if (widget.navigationInteger == 0) {
                  CustomNavigator().pushReplacement(context, AdminScreen());
                } else {
                  CustomNavigator().pushReplacement(context, UserScreen());
                }
              }
                  : null,
              child: Text('Continue', style: TextStyle(fontFamily: AppFonts.gRegular)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.disabled))
                      return Colors.grey;
                    return Theme.of(context).primaryColor;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
