import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class SavedStoresScreen extends StatelessWidget {
  const SavedStoresScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "saved_offers".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
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
            return const Center(child: CircularProgressIndicator(color: dropRed));
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
    final productName = data['product'] ?? "Product";
    final storeName = data['storeName'] ?? "Store";
    final discount = data['discount'] ?? "0%";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData categoryIcon = Icons.local_offer_rounded;
    if (category == 'cat_food' || productName.toString().toLowerCase().contains('burger')) {
      categoryIcon = Icons.restaurant_rounded;
    } else if (category == 'cat_cafes' || productName.toString().toLowerCase().contains('moca')) {
      categoryIcon = Icons.local_cafe_rounded;
    } else if (category == 'cat_fashion') {
      categoryIcon = Icons.shopping_bag_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: dropRed.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(categoryIcon, color: dropRed),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                Text(storeName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Text(discount, style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 16)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 15),
          Text("no_saved_offers".tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
