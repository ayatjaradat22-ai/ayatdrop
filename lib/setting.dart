import 'package:flutter/material.dart';
import 'dart:ui';
import 'account.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'language.dart';
import 'drop.dart';
import 'contactus.dart';
import 'aboutapp.dart';
import 'premium.dart';
import 'saved_stores.dart';
import 'privacy_security.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color dropRed = Color(0xFFFF1111); // الأحمر المعتمد

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء لنظافة التصميم
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // بطاقة بريميوم بتصميم ملكي
            _buildPremiumCard(context),

            const SizedBox(height: 30),
            _buildSectionHeader("Account Settings"),
            _buildModernTile(Icons.person_outline_rounded, "Personal Account", () {}), // AccountScreen
            _buildModernTile(Icons.edit_outlined, "Edit Profile", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildModernTile(Icons.key_outlined, "Security & Password", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            }),
            _buildModernTile(Icons.bookmark_border_rounded, "Saved Offers", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedStoresScreen()));
            }),

            const SizedBox(height: 25),
            _buildSectionHeader("Preferences"),
            _buildModernTile(Icons.language_rounded, "App Language", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageScreen()));
            }),
            _buildModernTile(Icons.notifications_none_rounded, "Notifications", () {}),

            const SizedBox(height: 25),
            _buildSectionHeader("Support"),
            _buildModernTile(Icons.help_outline_rounded, "Help Center", () {}),
            _buildModernTile(Icons.info_outline_rounded, "About Drop App", () {
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
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black, // أسود ملكي
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: dropRed.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Drop Premium", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text("Unlock exclusive deals & AI features", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dropRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
                  child: const Text("Get Started", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 60),
        ],
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: dropRed, size: 20),
            SizedBox(width: 10),
            Text("Logout Account", style: TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}