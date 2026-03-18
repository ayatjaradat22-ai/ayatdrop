import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'language.dart';
import 'aboutapp.dart';
import 'premium.dart';
import 'saved_stores.dart';
import 'FAQ.dart';
import 'drop.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  static const Color dropRed = Color(0xFFFF1111);
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() => _isPremium = doc.data()?['isPremium'] ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("settings".tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
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
            
            _buildModernTile(
              Icons.dark_mode_rounded, 
              "dark_mode".tr(), 
              () {
                if (!_isPremium) {
                  _showPremiumRequiredDialog();
                }
              },
              trailing: _isPremium 
                ? Switch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    activeColor: dropRed,
                    onChanged: (val) => themeProvider.toggleTheme(val),
                  )
                : const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
            ),

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

  Widget _buildModernTile(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white, 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: dropRed, size: 22),
        ),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
        ),
        onPressed: () => _logout(),
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

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("premium_feature".tr()),
        content: Text("dark_mode_premium_desc".tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("cancel_button".tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dropRed),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
            },
            child: Text("upgrade_now".tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
