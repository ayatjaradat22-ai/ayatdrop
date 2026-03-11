import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const Color dropRed = Color(0xFFFF1111);

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
        title: Text(
          "our_story".tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_info')
            .doc('about')
            .snapshots(),
        builder: (context, snapshot) {
          String aboutText = "about_app_desc_fallback".tr();
          String versionNum = "1.0.0";
          String problemsSolved = "problems_solved_fallback".tr();

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!;
            aboutText = data['about_text'] ?? aboutText;
            versionNum = data['version'] ?? versionNum;
            problemsSolved = data['problems_solved'] ?? problemsSolved;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 30),

                _buildModernLogo(),

                const SizedBox(height: 15),
                const Text(
                  "DROP APP",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                Text(
                  "${"version".tr()} $versionNum",
                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12),
                ),

                const SizedBox(height: 40),

                _buildModernInfoSection("vision_mission".tr(), aboutText, Icons.auto_awesome_rounded),
                _buildModernInfoSection("why_drop".tr(), problemsSolved, Icons.verified_rounded),

                const SizedBox(height: 40),

                _buildDeveloperCard(["Ayat Jaradat", "Aya Shnnaq"]),

                const SizedBox(height: 40),
                Text(
                  "made_with_love".tr(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernLogo() {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: dropRed,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: dropRed.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 60),
      ),
    );
  }

  Widget _buildModernInfoSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: dropRed, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(List<String> names) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(
            "developed_by".tr().toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: names.map((name) => Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  radius: 20,
                  child: Text(name[0], style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}