import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:live_13/models/user_model.dart';

class WalletController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Reactive variables
  var userCoins = 0.obs;
  var isLoading = false.obs;
  var selectedCoins = 0.obs;
  var selectedPrice = 0.obs;
  
  // Coin packages with prices in LKR
  final List<Map<String, dynamic>> coinPackages = [
    {
      'coins': 20000,
      'price': 31,
      'bonus': 0,
      'isPopular': true,
    },
    {
      'coins': 200000,
      'price': 325,
      'bonus': 0,
      'isPopular': false,
    },
    {
      'coins': 1000000,
      'price': 1625,
      'bonus': 100000,
      'isPopular': false,
    },
    {
      'coins': 5000000,
      'price': 8075,
      'bonus': 1000000,
      'isPopular': false,
    },
    {
      'coins': 20000000,
      'price': 32250,
      'bonus': 5400000,
      'isPopular': false,
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _loadUserCoins();
  }

  void _loadUserCoins() {
    try {
      if (userData.currentUser != null) {
        userCoins.value = userData.currentUser!.coins;
      }
    } catch (e) {
      print('Error loading user coins: $e');
    }
  }

  Future<void> refreshCoins() async {
    try {
      isLoading.value = true;
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        int coins = data['coins'] ?? 0;
        userCoins.value = coins;
        
        // Update local user data
        if (userData.currentUser != null) {
          userData.currentUser = UserModel(
            userId: userData.currentUser!.userId,
            email: userData.currentUser!.email,
            name: userData.currentUser!.name,
            role: userData.currentUser!.role,
            username: userData.currentUser!.username,
            image: userData.currentUser!.image,
            coins: coins,
          );
        }
      }
    } catch (e) {
      print('Error refreshing coins: $e');
      Get.snackbar('Error', 'Failed to refresh coin balance');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCoinPackage(int coins, int price) {
    selectedCoins.value = coins;
    selectedPrice.value = price;
  }

  Future<void> purchaseCoins(int packageIndex) async {
    try {
      isLoading.value = true;
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      var package = coinPackages[packageIndex];
      int coinsToAdd = package['coins'] + package['bonus'];
      
      // Get current coins
      DocumentSnapshot userDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();
      
      int currentCoins = 0;
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        currentCoins = data['coins'] ?? 0;
      }
      
      int newCoinsTotal = currentCoins + coinsToAdd;
      
      // Update coins in Firestore
      await _firestore.collection('Users').doc(userId).set({
        'coins': newCoinsTotal,
      }, SetOptions(merge: true));
      
      // Record purchase transaction
      await _firestore
          .collection('Users')
          .doc(userId)
          .collection('coinTransactions')
          .add({
        'type': 'purchase',
        'coins': package['coins'],
        'bonus': package['bonus'],
        'totalCoins': coinsToAdd,
        'price': package['price'],
        'timestamp': FieldValue.serverTimestamp(),
        'packageIndex': packageIndex,
      });
      
      // Update local state
      userCoins.value = newCoinsTotal;
      
      // Update user data
      if (userData.currentUser != null) {
        userData.currentUser = UserModel(
          userId: userData.currentUser!.userId,
          email: userData.currentUser!.email,
          name: userData.currentUser!.name,
          role: userData.currentUser!.role,
          username: userData.currentUser!.username,
          image: userData.currentUser!.image,
          coins: newCoinsTotal,
        );
      }
      
      String bonusText = package['bonus'] > 0 ? ' (+${_formatNumber(package['bonus'])} bonus!)' : '';
      
      Get.snackbar(
        'Purchase Successful! 🎉',
        'You received ${_formatNumber(coinsToAdd)} coins$bonusText',
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      print('Error purchasing coins: $e');
      Get.snackbar(
        'Purchase Failed',
        'Something went wrong. Please try again.',
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> spendCoins(int amount, String description) async {
    try {
      if (userCoins.value < amount) {
        Get.snackbar('Insufficient Coins', 'You don\'t have enough coins');
        return;
      }
      
      String userId = FirebaseAuth.instance.currentUser!.uid;
      int newCoinsTotal = userCoins.value - amount;
      
      // Update coins in Firestore
      await _firestore.collection('Users').doc(userId).set({
        'coins': newCoinsTotal,
      }, SetOptions(merge: true));
      
      // Record spend transaction
      await _firestore
          .collection('Users')
          .doc(userId)
          .collection('coinTransactions')
          .add({
        'type': 'spend',
        'coins': amount,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update local state
      userCoins.value = newCoinsTotal;
      
      // Update user data
      if (userData.currentUser != null) {
        userData.currentUser = UserModel(
          userId: userData.currentUser!.userId,
          email: userData.currentUser!.email,
          name: userData.currentUser!.name,
          role: userData.currentUser!.role,
          username: userData.currentUser!.username,
          image: userData.currentUser!.image,
          coins: newCoinsTotal,
        );
      }
      
    } catch (e) {
      print('Error spending coins: $e');
      Get.snackbar('Error', 'Failed to spend coins');
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String formatCoins(int coins) {
    return _formatNumber(coins);
  }
} 