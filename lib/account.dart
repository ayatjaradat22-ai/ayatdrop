import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'setting.dart';
import 'order_history.dart';
import 'payment_methods.dart';
import 'edit_profile.dart';
import 'drop.dart';
import 'saved_addresses.dart';
import 'FAQ.dart';
import 'contactus.dart';
import 'store_home.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final user = FirebaseAuth.instance.currentUser;
  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: dropRed,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("drop", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          String name = "loading".tr();
          String email = user?.email ?? "no_email".tr();
          String role = "user"; // الرتبة الافتراضية

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? "no_name".tr();
            role = data['role'] ?? "user";
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text("my_account_title".tr(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 25),

                _buildInfoCard("name_label".tr(), name, Icons.edit_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                }),

                _buildInfoCard("email_label".tr(), email, Icons.email_outlined, null),

                const SizedBox(height: 20),

                // زر لوحة تحكم المتجر (يظهر فقط إذا كان المستخدم متجراً)
                if (role == 'store')
                  _buildStoreDashboardCard(),

                _buildActionCard("order_history".tr(), Icons.history, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                }),

                _buildActionCard("payment_methods".tr(), Icons.payment, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()));
                }),

                _buildActionCard("saved_addresses".tr(), Icons.location_on_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedAddressesScreen()));
                }),

                _buildActionCard("faq_title".tr(), Icons.help_outline, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
                }),

                _buildActionCard("contact_us".tr(), Icons.headset_mic_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
                }),

                _buildActionCard("settings".tr(), Icons.settings_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),

                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dropRed,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text("edit_profile".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: () => _logout(),
                      child: Text("logout_button".tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // ويدجت مميز للوحة تحكم المتجر
  Widget _buildStoreDashboardCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.black87, Colors.black]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: dropRed.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreHomeScreen())),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 24),
        ),
        title: Text("store_dashboard".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("manage_deals_and_subs".tr(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("logout_title".tr()),
        content: Text("logout_confirmation".tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("cancel_button".tr())),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text("logout_button".tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            if (onTap != null) Icon(icon, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: dropRed, size: 22),
                const SizedBox(width: 15),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
