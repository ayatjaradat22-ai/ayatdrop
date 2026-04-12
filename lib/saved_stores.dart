import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_colors.dart';

class SavedStoresScreen extends StatelessWidget {
  const SavedStoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = AppColors.getPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getScaffoldBackground(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getPrimaryTextColor(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "saved_offers".tr(),
          style: TextStyle(color: AppColors.getPrimaryTextColor(context), fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('favorites')
            .orderBy('savedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var dealDoc = snapshot.data!.docs[index];
              return _buildSavedDealCard(context, dealDoc);
            },
          );
        },
      ),
    );
  }

  Widget _buildSavedDealCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String? category = data['category']?.toString();
    final productName = data['product']?.toString() ?? "Product";
    final storeName = data['storeName']?.toString() ?? "Store";
    final discount = data['discount']?.toString() ?? "0%";
    final primaryColor = AppColors.getPrimaryColor(context);

    IconData categoryIcon = Icons.local_offer_rounded;
    if (category == 'cat_food' || productName.toLowerCase().contains('burger')) {
      categoryIcon = Icons.restaurant_rounded;
    } else if (category == 'cat_cafes' || productName.toLowerCase().contains('moca')) {
      categoryIcon = Icons.local_cafe_rounded;
    } else if (category == 'cat_fashion') {
      categoryIcon = Icons.shopping_bag_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(20),
        border: AppColors.getCommonBorderSide(context).toBorder(),
        boxShadow: AppColors.getCommonShadow(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(categoryIcon, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getPrimaryTextColor(context))),
                Text(storeName, style: TextStyle(color: AppColors.getSecondaryTextColor(context), fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Text(discount, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => _removeFavorite(doc.id),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavorite(String dealId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(dealId)
        .delete();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border_rounded, size: 80, color: Colors.red),
          const SizedBox(height: 15),
          Text("no_saved_offers".tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
