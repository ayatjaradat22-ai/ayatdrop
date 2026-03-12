import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'language.dart';
import 'drop.dart';
import 'aboutapp.dart';
import 'premium.dart';
import 'saved_stores.dart';
import 'FAQ.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("settings".tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildPremiumCard(context),
            const SizedBox(height: 30),
            _buildSectionHeader("account_settings_section".tr()),
            _buildModernTile(Icons.person_outline_rounded, "personal_account".tr(), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildModernTile(Icons.edit_outlined, "edit_profile".tr(), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildModernTile(Icons.key_outlined, "security_password".tr(), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            }),
            _buildModernTile(Icons.bookmark_border_rounded, "saved_offers".tr(), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedStoresScreen()));
            }),
            const SizedBox(height: 25),
            _buildSectionHeader("preferences_section".tr()),
            _buildModernTile(Icons.language_rounded, "app_language".tr(), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageScreen()));
            }),
            _buildModernTile(Icons.notifications_none_rounded, "notifications".tr(), () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("notifications_coming_soon".tr()), backgroundColor: dropRed),
              );
            }),
            const SizedBox(height: 25),
            _buildSectionHeader("support_section".tr()),
            _buildModernTile(Icons.help_outline_rounded, "help_center".tr(), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
            }),
            _buildModernTile(Icons.info_outline_rounded, "about_drop".tr(), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppScreen()));
            }),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1)),
    );
  }

  Widget _buildModernTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: dropRed, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
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
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.2)],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("premium_title".tr(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text("premium_subtitle".tr(), style: TextStyle(color: Colors.grey[200], fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dropRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
                    child: Text("get_started".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
        ),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: dropRed, size: 20),
            const SizedBox(width: 10),
            Text("logout_button".tr(), style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
