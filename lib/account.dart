import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'setting.dart';
import 'order_history.dart';
import 'payment_methods.dart';
import 'edit_profile.dart';
import 'saved_addresses.dart';
import 'FAQ.dart';
import 'contactus.dart';
import 'saved_stores.dart';
import 'premium.dart';
import 'store_home.dart';
import 'store_login.dart';
import 'app_colors.dart';
import 'screens/merchant/merchant_scanner_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = AppColors.getPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("app_name".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
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
                _buildProfileHeader(photoUrl, name, email, primaryColor),
                const SizedBox(height: 30),

                if (role == 'store')
                  _buildSpecialDashboardCard(
                    title: "store_dashboard".tr(),
                    subtitle: "manage_deals_and_subs".tr(),
                    icon: Icons.storefront_rounded,
                    primaryColor: primaryColor,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreHomeScreen()));
                    },
                  ),

                if (role == 'store') const SizedBox(height: 15),

                _buildSpecialDashboardCard(
                  title: "premium_title".tr(),
                  subtitle: "premium_subtitle".tr(),
                  icon: Icons.stars_rounded,
                  primaryColor: primaryColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
                ),

                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("preferences_section".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getHintTextColor(context)))),
                const SizedBox(height: 10),

                // زر تبديل اللغة الجديد (نفس التصميم المطلوب)
                _buildLanguageToggleCard(primaryColor),

                _buildActionCard("saved_offers".tr(), Icons.favorite_rounded, primaryColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedStoresScreen()));
                }),

                _buildActionCard("order_history".tr(), Icons.history, primaryColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                }),

                _buildActionCard("payment_methods".tr(), Icons.payment, primaryColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()));
                }),

                _buildActionCard("saved_addresses".tr(), Icons.location_on_outlined, primaryColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedAddressesScreen()));
                }),

                // الزر السري لتجربة ماسح المحلات (Hacker Mode 🚀)
                _buildActionCard("merchant_scanner".tr(), Icons.qr_code_scanner_rounded, Colors.blueGrey, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MerchantScannerScreen()));
                }),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("support_section".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getHintTextColor(context)))),
                const SizedBox(height: 10),

                _buildActionCard("faq_title".tr(), Icons.help_outline, primaryColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
                }),

                _buildActionCard("contact_us".tr(), Icons.headset_mic_outlined, primaryColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
                }),

                _buildActionCard("settings".tr(), Icons.settings_outlined, primaryColor, () {
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

  Widget _buildLanguageToggleCard(Color primaryColor) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(15),
        border: AppColors.getCommonBorderSide(context).toBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.translate_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 15),
              Text(
                "language_label".tr(), // تأكد من وجود مفتاح language_label في الترجمة
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.getPrimaryTextColor(context)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildLangBtn("EN", !isArabic),
                _buildLangBtn("AR", isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangBtn(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          context.setLocale(label == "EN" ? const Locale('en') : const Locale('ar'));
          setState(() {});
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String? photoUrl, String name, String email, Color primaryColor) {
    ImageProvider? imageProvider;
    
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        imageProvider = NetworkImage(photoUrl);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(photoUrl));
        } catch (e) {
          imageProvider = null;
        }
      }
    }

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
                  color: AppColors.getCardBackground(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                  image: imageProvider != null 
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover) 
                    : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: (imageProvider == null)
                  ? Icon(Icons.person, color: primaryColor, size: 50) 
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.getPrimaryTextColor(context))),
        Text(email, style: TextStyle(color: AppColors.getSecondaryTextColor(context), fontSize: 14)),
      ],
    );
  }

  Widget _buildSpecialDashboardCard({required String title, required String subtitle, required IconData icon, required Color primaryColor, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: const DecorationImage(
          image: AssetImage("images/splash_screen.png"),
          fit: BoxFit.cover,
        ),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
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
              color: AppColors.goldColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.goldColor.withOpacity(0.5), width: 1),
            ),
            child: Icon(icon, color: AppColors.goldColor, size: 28),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[300], fontSize: 13)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.goldColor, size: 16),
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
                MaterialPageRoute(builder: (context) => const StoreLoginScreen()),
                (route) => false,
              );
            },
            child: Text("logout_button".tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color primaryColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(15),
          border: AppColors.getCommonBorderSide(context).toBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 22),
                const SizedBox(width: 15),
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.getPrimaryTextColor(context))),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.getHintTextColor(context), size: 16),
          ],
        ),
      ),
    );
  }
}
