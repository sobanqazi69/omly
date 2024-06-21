import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:live_13/data/user_names_model.dart';


class DatabaseServices {

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  void saveUserData(Map<String,dynamic> userData) {
    _firestore.collection('Users').doc(user!.uid).set(userData);
  }

  Future<List<UserNamesModel>> fetchUsernames() async {
    List<UserNamesModel> userNames = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Users').get();
    for (var doc in snapshot.docs) {
      UserNamesModel userName = UserNamesModel.fromJson(doc.data() as Map<String,dynamic>);
      userNames.add(userName);
    }
    return userNames;
  }

}