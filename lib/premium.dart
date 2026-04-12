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

  Future<void> _togglePremium(bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'isPremium': !currentStatus,
        'subscriptionDate': DateTime.now(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? "premium_member".tr() : "Premium deactivated"), 
          backgroundColor: !currentStatus ? Colors.green : Colors.orange
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).iconTheme.color),
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
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            dropRed.withValues(alpha: 0.2),
                            dropRed.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dropRed.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.stars_rounded, color: dropRed, size: 70),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  isPremium ? "premium_member".tr() : "premium_title".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "premium_features_desc".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.6),
                  ),
                ),
                const SizedBox(height: 40),

                _buildFeatureItem(Icons.auto_awesome_rounded, "ai_deal_hunter".tr()),
                _buildFeatureItem(Icons.local_offer_rounded, "vip_discounts".tr()),
                _buildFeatureItem(Icons.notifications_active_rounded, "early_access".tr()),

                const SizedBox(height: 50),

                // زر مؤقت للتبديل بين بريميوم وعادي
                _buildDebugToggleButton(isPremium),

                const SizedBox(height: 20),

                if (!isPremium)
                  GestureDetector(
                    onTap: () => _togglePremium(false),
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [dropRed, Color(0xFFCC0000)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: dropRed.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "join_premium".tr(), 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1.5),
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

  Widget _buildDebugToggleButton(bool isPremium) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text("🛠️ DEV TOOL (Temporary)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 5),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium ? Colors.grey : Colors.amber,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _togglePremium(isPremium),
            child: Text(isPremium ? "DEACTIVATE PREMIUM" : "ACTIVATE PREMIUM"),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: dropRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: dropRed, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(text, 
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w700,
              )),
          ),
          Icon(Icons.check_circle_outline_rounded, color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }
}
