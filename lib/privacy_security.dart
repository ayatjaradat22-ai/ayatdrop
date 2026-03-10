import 'package:flutter/material.dart';
import 'dart:ui';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111); // الأحمر الموحد للهوية

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
        title: const Text("Contact Us",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // الهيدر البصري (أيقونة التواصل)
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
            const SizedBox(height: 20),
            const Text("How can we help you?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("Our team is here to support you 24/7",
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),

            const SizedBox(height: 45),

            // خيارات التواصل (الكبسولات)
            _buildContactMethod(
              title: "Customer Support",
              subtitle: "Chat with us right now",
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () {},
            ),
            _buildContactMethod(
              title: "Email Us",
              subtitle: "support@drop-app.com",
              icon: Icons.mail_outline_rounded,
              onTap: () {},
            ),
            _buildContactMethod(
              title: "WhatsApp",
              subtitle: "+1 234 567 890",
              icon: Icons.phone_android_rounded,
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // وسائل التواصل الاجتماعي في الأسفل
            Text("Follow us on social media",
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(Icons.facebook_rounded),
                const SizedBox(width: 20),
                _buildSocialIcon(Icons.camera_alt_outlined), // Instagram
                const SizedBox(width: 20),
                _buildSocialIcon(Icons.alternate_email_rounded), // X/Twitter
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: dropRed, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.black87, size: 22),
    );
  }
}