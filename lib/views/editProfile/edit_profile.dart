import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:live_13/models/user_model.dart';
import 'package:live_13/navigations/navigator.dart';
import 'package:live_13/views/splashScreen/splash_screen.dart'; // Adjust the import path as necessary

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? user = userData.currentUser; // Get the current user from the singleton
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
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
          SnackBar(content: Text('Image updated successfully!')),
        );
        CustomNavigator().pushReplacement(context, SplashScreen());
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating image')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : NetworkImage(user?.image ?? 'https://example.com/default_image.jpg') as ImageProvider,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              Text(
                'Email: ${user?.email ?? ''}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Username: ${user?.username ?? ''}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                'Role: ${user?.role ?? ''}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              if (_pickedImage != null)
                ElevatedButton(
                  onPressed: _updateImage,
                  child: Text('Update Image'),
                ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
