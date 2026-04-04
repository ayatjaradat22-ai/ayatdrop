import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'aboutapp.dart';
import 'premium.dart';
import 'saved_stores.dart';
import 'FAQ.dart';
import 'store_login.dart';
import 'drop.dart'; // استيراد شاشة تسجيل الدخول الصحيحة
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_colors.dart'; // استخدام المسار الجديد فقط

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
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
    final primaryColor = AppColors.getPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getScaffoldBackground(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getPrimaryTextColor(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("settings".tr(), style: TextStyle(color: AppColors.getPrimaryTextColor(context), fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildPremiumCard(context, primaryColor),
            const SizedBox(height: 30),
            _buildSectionHeader("account_settings_section".tr()),
            _buildModernTile(Icons.edit_outlined, "edit_profile".tr(), primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildModernTile(Icons.key_outlined, "security_password".tr(), primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            }),
            _buildModernTile(Icons.bookmark_border_rounded, "saved_offers".tr(), primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedStoresScreen()));
            }),
            const SizedBox(height: 25),
            _buildSectionHeader("preferences_section".tr()),
            
            _buildModernTile(
              Icons.palette_outlined, 
              "app_theme".tr(), 
              primaryColor,
              () {
                if (!_isPremium) {
                  _showPremiumRequiredDialog(primaryColor);
                } else {
                  _showThemeSelector();
                }
              },
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ),

            _buildModernTile(Icons.notifications_none_rounded, "notifications".tr(), primaryColor, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("notifications_coming_soon".tr()), backgroundColor: primaryColor),
              );
            }),
            const SizedBox(height: 25),
            _buildSectionHeader("support_section".tr()),
            _buildModernTile(Icons.help_outline_rounded, "help_center".tr(), primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
            }),
            _buildModernTile(Icons.info_outline_rounded, "about_drop".tr(), primaryColor, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppScreen()));
            }),
            const SizedBox(height: 40),
            _buildLogoutButton(context, primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getScaffoldBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text(
              "choose_theme".tr(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.getPrimaryTextColor(context)),
            ),
            const SizedBox(height: 8),
            Text(
              "customize_app_appearance".tr(),
              style: TextStyle(fontSize: 14, color: AppColors.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildThemeCard(AppTheme.light, "theme_light".tr(), Colors.white, AppColors.dropRed),
                  _buildThemeCard(AppTheme.dark, "theme_dark".tr(), const Color(0xFF1E1E1E), AppColors.dropRed),
                  _buildThemeCard(AppTheme.midnight, "theme_midnight".tr(), const Color(0xFF0D1117), const Color(0xFF1A237E)),
                  _buildThemeCard(AppTheme.forest, "theme_forest".tr(), const Color(0xFFF1F8E9), const Color(0xFF2E7D32)),
                  _buildThemeCard(AppTheme.purple, "theme_purple".tr(), const Color(0xFF120024), const Color(0xFF4A148C)),
                  _buildThemeCard(AppTheme.pink, "theme_pink".tr(), const Color(0xFFFFF1F6), const Color(0xFFE91E63)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(AppTheme theme, String name, Color bg, Color accent) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isSelected = themeProvider.currentTheme == theme;

    return GestureDetector(
      onTap: () {
        themeProvider.setTheme(theme);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : Colors.grey.withOpacity(0.2),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(height: 15, color: accent.withOpacity(0.8)),
              ),
              Positioned(
                bottom: 12, left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 40, height: 6, decoration: BoxDecoration(color: isSelected ? accent : Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(5))),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme == AppTheme.light || theme == AppTheme.forest || theme == AppTheme.pink ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 20, right: 10,
                  child: Icon(Icons.check_circle, color: accent, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.getHintTextColor(context), letterSpacing: 1)),
    );
  }

  Widget _buildModernTile(IconData icon, String title, Color primaryColor, VoidCallback onTap, {Widget? trailing}) {
    final isDark = AppColors.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackground(context),
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
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.getPrimaryTextColor(context))),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, Color primaryColor) {
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
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
                    child: Text("get_started".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.stars_rounded, color: AppColors.goldColor, size: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: AppColors.getCommonBorderSide(context)),
        ),
        onPressed: () => _logout(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Text("logout_button".tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    AppColors.showThemedDialog(
      context: context,
      title: "logout_title".tr(),
      description: "logout_confirmation".tr(),
      primaryButtonText: "logout_button".tr(),
      primaryButtonColor: Colors.red,
      icon: Icons.logout_rounded,
      onPrimaryPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()), // التوجه لشاشة تسجيل الدخول الصحيحة
          (route) => false,
        );
      },
    );
  }

  void _showPremiumRequiredDialog(Color primaryColor) {
    AppColors.showThemedDialog(
      context: context,
      title: "premium_feature".tr(),
      description: "themes_premium_desc".tr(),
      primaryButtonText: "upgrade_now".tr(),
      primaryButtonColor: primaryColor,
      icon: Icons.stars_rounded,
      onPrimaryPressed: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
      },
    );
  }
}
