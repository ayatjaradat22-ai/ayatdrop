import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "contact_us".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
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
                  color: dropRed.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic_rounded, color: dropRed, size: 60),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "contact_support_title".tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              "contact_support_desc".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 50),

            _buildContactTile(
              context,
              Icons.email_outlined,
              "email_us_title".tr(),
              "support@drop-app.com",
              () => _launchURL("mailto:support@drop-app.com"),
            ),
            _buildContactTile(
              context,
              Icons.phone_outlined,
              "call_us_title".tr(),
              "+962 79 000 0000",
              () => _launchURL("tel:+962790000000"),
            ),
            _buildContactTile(
              context,
              Icons.chat_bubble_outline_rounded,
              "whatsapp_title".tr(),
              "WhatsApp Support",
              () => _launchURL("https://wa.me/962790000000"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildContactTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white,
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: dropRed, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }
}
