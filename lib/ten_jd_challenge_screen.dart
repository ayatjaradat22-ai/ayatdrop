import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class TenJdChallengeScreen extends StatelessWidget {
  const TenJdChallengeScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ten_jd_challenge".tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 20),
            _buildChallengeGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 50),
          const SizedBox(height: 15),
          Text(
            "ten_jd_challenge".tr(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "ten_jd_desc".tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final affordableDeals = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final product = (data['product'] ?? "").toString().toLowerCase();
          final discount = (data['discount'] ?? "").toString().toLowerCase();
          
          return product.contains('10') || product.contains('5') || 
                 discount.contains('10') || discount.contains('5') ||
                 data['category'] == 'cat_food' || data['category'] == 'cat_cafes';
        }).toList();

        if (affordableDeals.isEmpty) {
          return Center(child: Text("coming_soon".tr()));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: (affordableDeals.length / 2).ceil(),
          itemBuilder: (context, index) {
            int firstIdx = index * 2;
            int secondIdx = firstIdx + 1;
            
            return _buildBundleCard(
              context,
              affordableDeals[firstIdx],
              secondIdx < affordableDeals.length ? affordableDeals[secondIdx] : null,
            );
          },
        );
      },
    );
  }

  Widget _buildBundleCard(BuildContext context, DocumentSnapshot item1, DocumentSnapshot? item2) {
    final data1 = item1.data() as Map<String, dynamic>;
    final data2 = item2?.data() as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text("items_bundle".tr(args: [item2 == null ? "1" : "2"]), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Text("~ 10 JOD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 15),
          _buildItemRow(data1['storeName'] ?? "Store", data1['product'] ?? "Item"),
          if (data2 != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            _buildItemRow(data2['storeName'] ?? "Store", data2['product'] ?? "Item"),
          ],
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {},
              child: Text("get_them_now".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String store, String product) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(text: "$product ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "from_store".tr(args: [store]), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}