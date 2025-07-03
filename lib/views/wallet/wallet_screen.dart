import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:live_13/Config/app_spacing.dart';
import 'package:live_13/Config/app_theme.dart';
import 'package:live_13/config/app_colors.dart';
import 'package:live_13/config/app_fonts.dart';
import 'package:live_13/controller/wallet_controller.dart';

class WalletScreen extends StatelessWidget {
  final WalletController walletController = Get.put(WalletController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: AppColor.black),
        ),
        title: Text(
          'Wallet',
          style: style(
            family: AppFonts.gBold,
            size: 20,
            clr: AppColor.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _showTransactionHistory(context),
            child: Text(
              'Record',
              style: style(
                family: AppFonts.gMedium,
                size: 16,
                clr: AppColor.red,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My Coins Card
            _buildCoinsCard(),
            SizedBox(height: space10),
            
            // Recharge Methods
            _buildRechargeMethodsSection(),
            SizedBox(height: space8),
            
            // Recharge Options
            _buildRechargeOptionsSection(),
            SizedBox(height: space10),
            
            // Recharge Button
            _buildRechargeButton(),
          ],
        ),
      ),
    );
  }



  Widget _buildCoinsCard() {
    return Obx(() => Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8A65),
            Color(0xFFFFB74D),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Coin icon background
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Coins',
                      style: style(
                        family: AppFonts.gMedium,
                        size: 16,
                        clr: AppColor.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => walletController.refreshCoins(),
                      child: Row(
                        children: [
                          Text(
                            'History',
                            style: style(
                              family: AppFonts.gMedium,
                              size: 14,
                              clr: AppColor.white,
                            ),
                          ),
                          SizedBox(width: space1),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColor.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  walletController.userCoins.value.toString(),
                  style: style(
                    family: AppFonts.gBold,
                    size: 36,
                    clr: AppColor.white,
                  ),
                ),
                SizedBox(height: space2),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildRechargeMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recharge Methods',
              style: style(
                family: AppFonts.gBold,
                size: 16,
                clr: AppColor.black,
              ),
            ),
            Text(
              'SriLanka',
              style: style(
                family: AppFonts.gMedium,
                size: 14,
                clr: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: space5),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                'Official Seller',
                Icons.verified,
                true,
                'Cheaper',
              ),
            ),
            SizedBox(width: space5),
            Expanded(
              child: _buildPaymentMethodCard(
                'GooglePlay',
                Icons.play_arrow,
                false,
                'Coming Soon',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, bool isSelected, String? tag) {
    return Container(
      padding: EdgeInsets.all(space6),
      decoration: BoxDecoration(
        color: isSelected ? AppColor.red.withOpacity(0.1) : Colors.grey[100],
        border: Border.all(
          color: isSelected ? AppColor.red : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (tag != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: space3, vertical: space1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: style(
                  family: AppFonts.gMedium,
                  size: 10,
                  clr: AppColor.white,
                ),
              ),
            ),
          SizedBox(height: space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColor.red : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: space2),
              Text(
                title,
                style: style(
                  family: AppFonts.gMedium,
                  size: 12,
                  clr: isSelected ? AppColor.red : Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recharge Options',
          style: style(
            family: AppFonts.gBold,
            size: 16,
            clr: AppColor.black,
          ),
        ),
        SizedBox(height: space5),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: space5,
            mainAxisSpacing: space5,
          ),
          itemCount: walletController.coinPackages.length,
          itemBuilder: (context, index) {
            return _buildCoinPackageCard(index);
          },
        ),
      ],
    );
  }

  Widget _buildCoinPackageCard(int index) {
    var package = walletController.coinPackages[index];
    bool hasBonus = package['bonus'] > 0;
    
    return Obx(() {
      bool isSelected = walletController.selectedCoins.value == package['coins'];
      
      return GestureDetector(
        onTap: () {
          walletController.selectCoinPackage(package['coins'], package['price']);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColor.red.withOpacity(0.1) : Colors.grey[50],
            border: Border.all(
              color: isSelected ? AppColor.red : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Coin icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 30,
              ),
            ),
            SizedBox(height: space3),
            
            // Coins amount
            Text(
              walletController.formatCoins(package['coins']),
              style: style(
                family: AppFonts.gBold,
                size: 18,
                clr: AppColor.black,
              ),
            ),
            
            // Bonus if available
            if (hasBonus) ...[
              SizedBox(height: space1),
              Text(
                '+${walletController.formatCoins(package['bonus'])}',
                style: style(
                  family: AppFonts.gMedium,
                  size: 12,
                  clr: Colors.orange,
                ),
              ),
            ],
            
            SizedBox(height: space3),
            
            // Price
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: space3),
              decoration: BoxDecoration(
                color: index == 0 ? AppColor.red : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                '${package['price']} LKR',
                textAlign: TextAlign.center,
                style: style(
                  family: AppFonts.gBold,
                  size: 14,
                  clr: index == 0 ? AppColor.white : AppColor.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    }); 
  }

  Widget _buildRechargeButton() {
    return Obx(() => Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: walletController.isLoading.value 
          ? null 
          : () => _handleRecharge(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: walletController.isLoading.value
          ? CircularProgressIndicator(color: AppColor.white)
          : Text(
              'Recharge Now',
              style: style(
                family: AppFonts.gBold,
                size: 16,
                clr: AppColor.white,
              ),
            ),
      ),
    ));
  }

  void _handleRecharge() async {
    if (walletController.selectedCoins.value == 0) {
      Get.snackbar('Select Package', 'Please select a coin package first');
      return;
    }
    
    // Find selected package index
    int selectedIndex = walletController.coinPackages.indexWhere(
      (package) => package['coins'] == walletController.selectedCoins.value
    );
    
    if (selectedIndex != -1) {
      // Show confirmation dialog
      bool confirmed = await _showPurchaseConfirmation(selectedIndex);
      if (confirmed) {
        await walletController.purchaseCoins(selectedIndex);
      }
    }
  }

  Future<bool> _showPurchaseConfirmation(int packageIndex) async {
    var package = walletController.coinPackages[packageIndex];
    int totalCoins = package['coins'] + package['bonus'];
    
    return await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Confirm Purchase',
          style: style(family: AppFonts.gBold, size: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to purchase:',
              style: style(family: AppFonts.gMedium, size: 14),
            ),
            SizedBox(height: space3),
            Text(
              '${walletController.formatCoins(totalCoins)} coins',
              style: style(family: AppFonts.gBold, size: 16, clr: AppColor.red),
            ),
            Text(
              'Price: ${package['price']} LKR',
              style: style(family: AppFonts.gMedium, size: 14),
            ),
            if (package['bonus'] > 0) ...[
              SizedBox(height: space2),
              Text(
                'Includes ${walletController.formatCoins(package['bonus'])} bonus coins!',
                style: style(family: AppFonts.gMedium, size: 12, clr: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.red),
            child: Text(
              'Purchase',
              style: style(family: AppFonts.gBold, clr: AppColor.white),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showTransactionHistory(BuildContext context) {
    Get.snackbar(
      'Coming Soon',
      'Transaction history feature will be available soon!',
      duration: Duration(seconds: 2),
    );
  }
} 