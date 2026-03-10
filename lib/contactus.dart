import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'faq.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch $urlString");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Support Center", // اسم أكثر احترافية
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_settings')
            .doc('contact_info')
            .snapshots(),
        builder: (context, snapshot) {
          // قيم افتراضية قوية
          String email = "drop.app.connect@gmail.com";
          String instagramHandle = "@drop.app.jo";
          String instagramUrl = "https://www.instagram.com/drop.app.jo";

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!;
            email = data['email'] ?? email;
            instagramHandle = data['instagram_handle'] ?? instagramHandle;
            instagramUrl = data['instagram_url'] ?? instagramUrl;
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // أيقونة الدعم الفني العصرية
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: dropRed.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: dropRed, size: 60),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "We're here to help!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Have a question or facing an issue?\nOur team is ready to assist you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  // بطاقات التواصل
                  _buildModernContactCard(
                    context,
                    "Email Support",
                    email,
                    Icons.alternate_email_rounded,
                        () => _launchURL("mailto:$email"),
                  ),

                  _buildModernContactCard(
                    context,
                    "Instagram",
                    instagramHandle,
                    Icons.camera_alt_rounded,
                        () => _launchURL(instagramUrl),
                  ),

                  _buildModernContactCard(
                    context,
                    "Common Questions",
                    "Browse FAQ",
                    Icons.help_outline_rounded,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FAQScreen()),
                      );
                    },
                    isHighlight: true,
                  ),

                  const SizedBox(height: 40),

                  // لمسة جمالية في الأسفل
                  Text(
                    "Response time: Within 24 hours",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernContactCard(
      BuildContext context,
      String title,
      String data,
      IconData icon,
      VoidCallback onTap,
      {bool isHighlight = false}
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isHighlight ? dropRed.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isHighlight ? dropRed.withOpacity(0.2) : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHighlight ? dropRed : Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: isHighlight ? Colors.white : dropRed, size: 24),
        ),
        title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)
        ),
        subtitle: Text(
            data,
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
      ),
    );
  }
}