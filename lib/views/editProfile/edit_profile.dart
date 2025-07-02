import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/splashScreen/splash_screen.dart'; // Adjust the import path as necessary
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:lottie/lottie.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  UserModel? user = userData.currentUser; // Get the current user from the singleton
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _updateImage() async {
    if (_pickedImage != null && user != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Check if document exists
        DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user!.userId).get();
        if (!userDoc.exists) {
          throw Exception('User document does not exist');
        }

        // Upload the new image to Firebase Storage
        Reference storageRef = _storage.ref().child('user_images').child('${user!.userId}.jpg');
        await storageRef.putFile(_pickedImage!);

        // Get the download URL of the new image
        String newImageUrl = await storageRef.getDownloadURL();

        // Update the user's image URL in Firestore
        await _firestore.collection('Users').doc(user!.userId).update({
          'image': newImageUrl,
        });

        // Update the local user model and UI
        setState(() {
          user = UserModel(
            userId: user!.userId,
            email: user!.email,
            name: user!.name,
            role: user!.role,
            username: user!.username,
            image: newImageUrl,
          );
          userData.currentUser = user;
          _pickedImage = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        CustomNavigator().pushReplacement(context, SplashScreen());
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Hero(
            tag: 'profileImage',
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(color: AppColor.white, width: 4),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : NetworkImage(user?.image ?? 'https://example.com/default_image.jpg') as ImageProvider,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              title == 'Email' ? Icons.email 
              : title == 'Username' ? Icons.person 
              : Icons.star,
              color: AppColor.red,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: AppFonts.gMedium,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppFonts.gBold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontFamily: AppFonts.gBold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildProfileImage(),
              ),
              SizedBox(height: 30),
              _buildInfoCard('Email', user?.email ?? ''),
              _buildInfoCard('Username', user?.username ?? ''),
              _buildInfoCard('Role', user?.role ?? ''),
              SizedBox(height: 30),
              if (_pickedImage != null)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Update Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: AppFonts.gBold,
                              ),
                            ),
                    ),
                  ),
                ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Lottie.network(
                    'https://assets1.lottiefiles.com/packages/lf20_p8bfn5to.json',
                    height: 100,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
