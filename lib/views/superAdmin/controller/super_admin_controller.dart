import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/user_names_model.dart';

class SuperAdminController extends GetxController {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;



  Future<bool> assignAdminRole(List<UserNamesModel> userData) async {
    try {
      for (var data in userData) {
        await _firestore.collection('Users').doc(data.userId).set({
          'role': 'Admin',
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      print('Error in assignAdminRole: $e');
      return false;
    }
  }

  Future<bool> assignParticipantRole(List<UserNamesModel> userData) async {
    try {
      for (var data in userData) {
        await _firestore.collection('Users').doc(data.userId).set({
          'role': 'Participant',
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      print('Error in assignParticipantRole: $e');
      return false;
    }
  }

  Future<bool> blockUsers(List<UserNamesModel> userData) async {
    try {
      for (var data in userData) {
        await _firestore.collection('Users').doc(data.userId).set({
          'isBlocked': true,
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      print('Error in blockUsers: $e');
      return false;
    }
  }

  Future<bool> unblockUsers(List<UserNamesModel> userData) async {
    try {
      for (var data in userData) {
        await _firestore.collection('Users').doc(data.userId).set({
          'isBlocked': false,
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      print('Error in unblockUsers: $e');
      return false;
    }
  }
}
