import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: dropRed, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "faq_title".tr(),
          style: const TextStyle(color: dropRed, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFAQItem("faq_q1".tr(), "faq_a1".tr()),
          _buildFAQItem("faq_q2".tr(), "faq_a2".tr()),
          _buildFAQItem("faq_q3".tr(), "faq_a3".tr()),
          _buildFAQItem("faq_q4".tr(), "faq_a4".tr()),
          _buildFAQItem("faq_q5".tr(), "faq_a5".tr()),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: dropRed),
        ),
        iconColor: dropRed,
        collapsedIconColor: dropRed.withOpacity(0.5),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
