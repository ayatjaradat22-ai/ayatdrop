import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class TenJdChallengeScreen extends StatelessWidget {
  const TenJdChallengeScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color ?? Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ten_jd_challenge".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        
        final allDeals = snapshot.data!.docs;
        
        // تصفية العروض التي سعرها أقل من 10 دنانير بشكل فردي أو يمكن دمجها
        final List<List<DocumentSnapshot>> bundles = [];
        List<DocumentSnapshot> currentBundle = [];
        double currentTotal = 0;

        for (var doc in allDeals) {
          final data = doc.data() as Map<String, dynamic>;
          final price = double.tryParse(data['newPrice']?.toString() ?? "0") ?? 0;

          if (price > 0 && price <= 10) {
            if (currentTotal + price <= 10) {
              currentBundle.add(doc);
              currentTotal += price;
            } else {
              if (currentBundle.isNotEmpty) bundles.add(List.from(currentBundle));
              currentBundle = [doc];
              currentTotal = price;
            }
          }
        }
        if (currentBundle.isNotEmpty) bundles.add(currentBundle);

        if (bundles.isEmpty) {
          return Center(child: Text("coming_soon".tr()));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: bundles.length,
          itemBuilder: (context, index) {
            return _buildBundleCard(context, bundles[index]);
          },
        );
      },
    );
  }

  Widget _buildBundleCard(BuildContext context, List<DocumentSnapshot> items) {
    double total = 0;
    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;
      total += double.tryParse(data['newPrice']?.toString() ?? "0") ?? 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                child: Text("items_bundle".tr(args: [items.length.toString()]), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Text("< 10 JOD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 15),
          ...items.map((item) {
            final data = item.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildItemRow(data['storeName'] ?? "Store", data['product'] ?? "Item", data['newPrice']?.toString() ?? "0"),
            );
          }).toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("total_price".tr(args: [total.toStringAsFixed(2)]), style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {},
                child: Text("get_them_now".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String store, String product, String price) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(text: "$product ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "from_store".tr(args: [store]), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        Text("$price JOD", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
