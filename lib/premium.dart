import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final user = FirebaseAuth.instance.currentUser;
  static const Color dropRed = Color(0xFFFF1111);

  Future<void> _activatePremium() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'isPremium': true,
        'subscriptionDate': DateTime.now(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("premium_member".tr()), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subscription failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          bool isPremium = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            isPremium = snapshot.data!.get('isPremium') ?? false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // أيقونة VIP بتصميم متناسق مع الأحمر
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dropRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: dropRed, size: 80),
                ),
                const SizedBox(height: 30),
                Text(
                  isPremium ? "premium_member".tr() : "premium_title".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  "premium_features_desc".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 50),

                _buildFeatureItem(Icons.auto_awesome_rounded, "ai_deal_hunter".tr()),
                _buildFeatureItem(Icons.local_offer_rounded, "vip_discounts".tr()),
                _buildFeatureItem(Icons.notifications_active_rounded, "early_access".tr()),

                const SizedBox(height: 60),

                if (!isPremium)
                  Container(
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: dropRed.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dropRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: _activatePremium,
                      child: Text("join_premium".tr(), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        Text("active_subscription".tr(), 
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: dropRed, size: 26),
          const SizedBox(width: 15),
          Expanded(
            child: Text(text, 
              style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
