import 'package:flutter/material.dart';

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "FAQ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // هيدر بصري جذاب
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dropRed.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: dropRed, size: 50),
                ),
                const SizedBox(height: 15),
                const Text(
                  "How can we help?",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  "Search for common questions below",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // قائمة الأسئلة بداخل Expanded
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildModernFAQTile("What is Drop App?", "Drop is an app that provides exclusive discounts and offers for various stores in Jordan."),
                _buildModernFAQTile("How to use a coupon?", "Choose the store, click on the offer, and show the code to the cashier or use it online."),
                _buildModernFAQTile("Is the app free?", "Yes, the basic version is free, but we have a Premium version for extra exclusive deals."),
                _buildModernFAQTile("How to contact support?", "You can contact us via the 'Contact Us' page through email or Instagram."),
                _buildModernFAQTile("Where are my saved stores?", "You can find them in the 'Saved Stores' section inside your Settings."),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: dropRed,
          collapsedIconColor: Colors.black45,
          leading: const Icon(Icons.help_outline_rounded, color: dropRed, size: 24),
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}