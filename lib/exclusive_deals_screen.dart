import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class ExclusiveDealsScreen extends StatelessWidget {
  const ExclusiveDealsScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "drop_exclusive".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deals')
            .where('isExclusive', isEqualTo: true)
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
              final deal = snapshot.data!.docs[index];
              return _buildExclusiveCard(context, deal);
            },
          );
        },
      ),
    );
  }

  Widget _buildExclusiveCard(BuildContext context, DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: dropRed.withOpacity(0.2), width: 2),
        boxShadow: [BoxShadow(color: dropRed.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dropRed.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23)),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_num_rounded, color: dropRed, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['storeName'] ?? "Store", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                      Text(data['product'] ?? "Deal", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(12)),
                  child: Text(data['discount'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  "show_at_cashier".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 24, color: isDark ? Colors.white : Colors.black),
                      const SizedBox(width: 10),
                      Text("DROP-${doc.id.substring(0, 5).toUpperCase()}", 
                        style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 15),
          Text("coming_soon".tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text("exclusive_deals_soon".tr(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
