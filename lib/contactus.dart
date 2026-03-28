import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_colors.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    final primaryColor = AppColors.getPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getScaffoldBackground(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getPrimaryTextColor(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "contact_us".tr(),
          style: TextStyle(color: AppColors.getPrimaryTextColor(context), fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.headset_mic_rounded, color: primaryColor, size: 60),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "customer_support".tr(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.getPrimaryTextColor(context)),
            ),
            const SizedBox(height: 10),
            Text(
              "contact_support_desc".tr(), // تأكد من وجود هذا المفتاح في الترجمة
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.getSecondaryTextColor(context), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 50),

            // خيار الإيميل (Gmail)
            _buildContactTile(
              context,
              Icons.email_rounded,
              "email_us_title".tr(),
              "support@drop-app.com",
              primaryColor,
              () => _launchURL("mailto:support@drop-app.com"),
            ),

            // خيار الإنستجرام (الرابط المطلوب)
            _buildContactTile(
              context,
              Icons.camera_alt_rounded, // أيقونة قريبة من إنستجرام أو استخدم أيقونة مخصصة
              "Instagram",
              "@drop.app.jo",
              Colors.purple, // لون إنستجرام المميز
              () => _launchURL("https://www.instagram.com/drop.app.jo?igsh=NnpxanlvN3Y2dDg3"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactTile(BuildContext context, IconData icon, String title, String subtitle, Color iconColor, VoidCallback onTap) {
    final isDark = AppColors.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackground(context),
        borderRadius: BorderRadius.circular(20),
        border: AppColors.getCommonBorderSide(context).toBorder(),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getPrimaryTextColor(context))),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.getSecondaryTextColor(context), fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.getHintTextColor(context)),
      ),
    );
  }
}
