import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreProfileScreen extends StatelessWidget {
  final String storeId;
  final String storeName;

  const StoreProfileScreen({super.key, required this.storeId, required this.storeName});

  Future<void> _openMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.dropRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(storeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(storeId).snapshots(),
        builder: (context, storeSnapshot) {
          if (!storeSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final storeData = storeSnapshot.data?.data() as Map<String, dynamic>?;
          final lat = storeData?['lat'] as num?;
          final lng = storeData?['lng'] as num?;
          final aboutText = storeData?['about']?.toString() ?? "";

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildStoreHeader(storeData, context),
                
                // About Section
                if (aboutText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.getSecondaryBackground(context),
                        borderRadius: BorderRadius.circular(15),
                        border: AppColors.getCommonBorderSide(context).toBorder(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("about_store_label".tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dropRed)),
                          const SizedBox(height: 8),
                          Text(aboutText, style: TextStyle(fontSize: 14, color: AppColors.getSecondaryTextColor(context), height: 1.5)),
                        ],
                      ),
                    ),
                  ),

                if (lat != null && lng != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ElevatedButton.icon(
                      onPressed: () => _openMaps(lat.toDouble(), lng.toDouble()),
                      icon: const Icon(Icons.map_rounded),
                      label: Text("show_on_map".tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Divider(color: Theme.of(context).dividerColor),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("active_deals".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getPrimaryTextColor(context))),
                  ),
                ),
                
                _buildDealsList(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreHeader(Map<String, dynamic>? data, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30, top: 10, left: 25, right: 25),
      decoration: const BoxDecoration(
        color: AppColors.dropRed,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.storefront_rounded, color: AppColors.dropRed, size: 40),
          ),
          const SizedBox(height: 15),
          Text(storeName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(data?['categories'] != null ? (data!['categories'] as List).first.toString().tr() : "", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDealsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deals')
          .where('storeId', isEqualTo: storeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text("no_deals_yet".tr(), style: const TextStyle(color: Colors.grey))),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(context),
                borderRadius: BorderRadius.circular(18),
                border: AppColors.getCommonBorderSide(context).toBorder(),
                boxShadow: AppColors.getCommonShadow(context),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['product'] ?? "", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getPrimaryTextColor(context))),
                        Text("${data['discount']}% OFF", style: const TextStyle(color: AppColors.dropRed, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text("${data['newPrice']} ${"jod_currency".tr()}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.getPrimaryTextColor(context))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
