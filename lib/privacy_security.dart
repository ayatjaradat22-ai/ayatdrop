import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("contact_us".tr(),
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: dropRed.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic_rounded, color: dropRed, size: 60),
              ),
            ),
            const SizedBox(height: 20),
            Text("how_can_we_help".tr(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text("support_24_7".tr(),
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),

            const SizedBox(height: 45),

            _buildContactMethod(
              context,
              title: "customer_support".tr(),
              subtitle: "chat_now_subtitle".tr(),
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () {},
            ),
            _buildContactMethod(
              context,
              title: "email_us_title".tr(),
              subtitle: "email_us_subtitle".tr(),
              icon: Icons.mail_outline_rounded,
              onTap: () {},
            ),
            _buildContactMethod(
              context,
              title: "whatsapp_label".tr(),
              subtitle: "whatsapp_subtitle".tr(),
              icon: Icons.phone_android_rounded,
              onTap: () {},
            ),

            const SizedBox(height: 40),

            Text("follow_us_social".tr(),
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(context, Icons.facebook_rounded),
                const SizedBox(width: 20),
                _buildSocialIcon(context, Icons.camera_alt_outlined),
                const SizedBox(width: 20),
                _buildSocialIcon(context, Icons.alternate_email_rounded),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: dropRed, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
      ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 22),
    );
  }
}