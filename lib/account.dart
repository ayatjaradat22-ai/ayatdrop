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
import 'saved_stores.dart';
import 'premium.dart';
import 'store_home.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const Color dropRed = Color(0xFFFF1111);
  static const Color goldColor = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light ? const Color(0xFFF8F9FA) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: dropRed,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("app_name".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: dropRed));
          }

          String name = "no_name".tr();
          String email = user?.email ?? "no_email".tr();
          String role = "user";
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? data['storeName'] ?? "no_name".tr();
            role = data['role'] ?? "user";
            photoUrl = data['photoUrl'];
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildProfileHeader(photoUrl, name, email),
                const SizedBox(height: 30),

                if (role == 'store')
                  _buildSpecialDashboardCard(
                    title: "store_dashboard".tr(),
                    subtitle: "manage_deals_and_subs".tr(),
                    icon: Icons.storefront_rounded,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreHomeScreen()));
                    },
                  ),

                if (role == 'store') const SizedBox(height: 15),

                _buildSpecialDashboardCard(
                  title: "premium_title".tr(),
                  subtitle: "premium_subtitle".tr(),
                  icon: Icons.stars_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
                ),

                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("preferences_section".tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                const SizedBox(height: 10),

                _buildActionCard("saved_offers".tr(), Icons.favorite_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedStoresScreen()));
                }),

                _buildActionCard("order_history".tr(), Icons.history, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                }),

                _buildActionCard("payment_methods".tr(), Icons.payment, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()));
                }),

                _buildActionCard("saved_addresses".tr(), Icons.location_on_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedAddressesScreen()));
                }),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("support_section".tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                const SizedBox(height: 10),

                _buildActionCard("faq_title".tr(), Icons.help_outline, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
                }),

                _buildActionCard("contact_us".tr(), Icons.headset_mic_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
                }),

                _buildActionCard("settings".tr(), Icons.settings_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen()));
                }),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text("logout_button".tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileHeader(String? photoUrl, String name, String email) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: dropRed, width: 2),
                  image: photoUrl != null && photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(photoUrl), 
                        fit: BoxFit.cover,
                      ) 
                    : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person, color: dropRed, size: 50) 
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: dropRed, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildSpecialDashboardCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: const DecorationImage(
          image: AssetImage("images/splash_screen.png"),
          fit: BoxFit.cover,
        ),
        boxShadow: [BoxShadow(color: dropRed.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.4)],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: goldColor.withOpacity(0.5), width: 1),
            ),
            child: Icon(icon, color: goldColor, size: 28),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[300], fontSize: 13)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: goldColor, size: 16),
        ),
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

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
