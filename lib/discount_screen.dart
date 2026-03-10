import 'package:flutter/material.dart';
import 'dart:math';

class DiscountScreen extends StatefulWidget {
  final bool isPremium;

  const DiscountScreen({super.key, required this.isPremium});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  late String dynamicCode;

  // ألوان براند Drop
  static const Color dropRed = Color(0xFFFF1111);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color premiumBlack = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _generateNewCode();
  }

  void _generateNewCode() {
    setState(() {
      String prefix = widget.isPremium ? "VIP-" : "DROP-";
      dynamicCode = prefix + (1000 + Random().nextInt(8999)).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isPremium ? premiumBlack : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isPremium ? premiumBlack : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: widget.isPremium ? goldAccent : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPremium ? "PREMIUM PASS" : "STANDARD DROP",
          style: TextStyle(
            color: widget.isPremium ? goldAccent : Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 1. قسم الـ QR المصمم كبطاقة (Ticket)
            _buildDiscountTicket(),

            const SizedBox(height: 40),

            // 2. تفاصيل العرض (Intensity Card)
            _buildInfoCard(),

            const SizedBox(height: 40),

            // 3. تعليمات الاستخدام بأسلوب عصري
            _buildModernInstructions(),

            const SizedBox(height: 50),

            // 4. الزر التفاعلي
            _buildActionIcon(),

            const SizedBox(height: 20),
            Text(
              "Tap to refresh after use",
              style: TextStyle(
                color: widget.isPremium ? Colors.white30 : Colors.black26,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountTicket() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: widget.isPremium ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: widget.isPremium ? goldAccent.withOpacity(0.5) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isPremium ? goldAccent.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        children: [
          // QR Code بلمسة جمالية
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 180,
              color: widget.isPremium ? premiumBlack : dropRed,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            widget.isPremium ? "EXCLUSIVE CODE" : "YOUR CODE",
            style: TextStyle(
              letterSpacing: 3,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.isPremium ? Colors.white54 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dynamicCode,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: widget.isPremium ? goldAccent : dropRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isPremium ? goldAccent.withOpacity(0.1) : dropRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(
            widget.isPremium ? Icons.auto_awesome_rounded : Icons.local_offer_rounded,
            color: widget.isPremium ? goldAccent : dropRed,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isPremium ? "UP TO 50% DISCOUNT" : "15% DISCOUNT ACTIVE",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: widget.isPremium ? goldAccent : dropRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Applicable at all partner stores.",
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isPremium ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInstructions() {
    return Column(
      children: [
        _instructionItem(Icons.qr_code_scanner_rounded, "Show QR to the cashier"),
        const SizedBox(height: 15),
        _instructionItem(Icons.verified_user_outlined, "Wait for verification"),
        const SizedBox(height: 15),
        _instructionItem(Icons.celebration_rounded, "Enjoy your savings!"),
      ],
    );
  }

  Widget _instructionItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: widget.isPremium ? goldAccent : Colors.grey),
        const SizedBox(width: 15),
        Text(
          text,
          style: TextStyle(
            color: widget.isPremium ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon() {
    return GestureDetector(
      onTap: _generateNewCode,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: widget.isPremium ? goldAccent : dropRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (widget.isPremium ? goldAccent : dropRed).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 35),
      ),
    );
  }
}