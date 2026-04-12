import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_colors.dart';

class StoreAnalyticsScreen extends StatelessWidget {
  const StoreAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
          "performance_analytics".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deals')
            .where('storeId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.dropRed));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("no_deals_to_analyze".tr(), style: const TextStyle(color: Colors.grey)));
          }

          final deals = snapshot.data!.docs;
          int totalClicks = 0;
          int totalFavorites = 0;

          for (var doc in deals) {
            final data = doc.data() as Map<String, dynamic>;
            totalClicks += (data['clicks'] ?? 0) as int;
            totalFavorites += (data['favoritesCount'] ?? 0) as int;
          }

          return Column(
            children: [
              _buildSummaryHeader(totalClicks, totalFavorites),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("deals_performance".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    final data = deal.data() as Map<String, dynamic>;
                    return _buildDealStatsCard(context, data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(int clicks, int favs) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: AppColors.dropRed,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(Icons.touch_app_rounded, clicks.toString(), "total_clicks".tr()),
          _buildSummaryItem(Icons.favorite_rounded, favs.toString(), "total_favorites".tr()),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildDealStatsCard(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['product'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(data['category']?.toString().tr() ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _buildStatIndicator(Icons.touch_app_rounded, data['clicks'] ?? 0, Colors.blue),
          const SizedBox(width: 15),
          _buildStatIndicator(Icons.favorite_rounded, data['favoritesCount'] ?? 0, AppColors.dropRed),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(IconData icon, dynamic count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
