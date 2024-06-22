import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_13/data/user_names_model.dart';


class DatabaseServices {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  Future<bool> saveUserData(Map<String,dynamic> userData) async {
    DocumentSnapshot userDoc = await _firestore.collection('Users').doc(user!.uid).get();
    if (!userDoc.exists) {
      await _firestore.collection('Users').doc(user!.uid).set(userData);
      return true;
    }
    return false;
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('Users').doc(uid).get();
  }

  Future<List<UserNamesModel>> fetchParticipantUserNames() async {
    List<UserNamesModel> userNames = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Users')
        .where('role',isEqualTo: 'Participant').get();
    for (var doc in snapshot.docs) {
      UserNamesModel userName = UserNamesModel.fromJson(doc.data() as Map<String,dynamic>);
      userNames.add(userName);
    }
    return userNames;
  }

  Future<List<UserNamesModel>> fetchAdminUserNames() async {
    List<UserNamesModel> userNames = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Users')
        .where('role',isEqualTo: 'Admin').get();
    for (var doc in snapshot.docs) {
      UserNamesModel userName = UserNamesModel.fromJson(doc.data() as Map<String,dynamic>);
      userNames.add(userName);
    }
    return userNames;
  }

}