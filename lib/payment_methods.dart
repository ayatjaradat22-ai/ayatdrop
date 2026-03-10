import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // الأحمر المعتمد لتطبيق Drop
  static const Color dropRed = Color(0xFFFF1111);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء نقية لفخامة التصميم
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment Methods",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),
            const Text(
              "Secure your transactions with our trusted partners.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            // 1. بطاقة الكريدت كارد (مفتوحة افتراضياً)
            _buildModernPaymentTile(
              title: "Credit / Debit Card",
              subtitle: "Visa, Mastercard, Amex",
              icon: Icons.credit_card_rounded,
              isExpanded: true,
              children: [
                const SizedBox(height: 10),
                _buildModernTextField("Card Number", Icons.credit_card_rounded),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildModernTextField("MM/YY", Icons.calendar_today_rounded)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildModernTextField("CVV", Icons.lock_person_rounded)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDropButton("Save & Link Card"),
              ],
            ),

            const SizedBox(height: 15),

            // 2. آبل باي - Apple Pay
            _buildModernPaymentTile(
              title: "Apple Pay",
              subtitle: "Express Checkout",
              icon: Icons.apple_rounded,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.face_unlock_rounded, color: Colors.black), // تم تصحيح الأيقونة هنا
                      SizedBox(width: 12),
                      Text("Pay faster with FaceID", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _buildDropButton("Set as Primary"),
              ],
            ),

            const SizedBox(height: 15),

            // 3. باي بال - PayPal
            _buildModernPaymentTile(
              title: "PayPal",
              subtitle: "Secure online payment",
              icon: Icons.account_balance_wallet_rounded,
              children: [
                _buildModernTextField("PayPal Email", Icons.alternate_email_rounded),
                const SizedBox(height: 15),
                _buildDropButton("Connect PayPal Account"),
              ],
            ),

            const SizedBox(height: 40),

            // زر إضافة طريقة دفع جديدة
            _buildAddNewMethod(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ودجت بناء بطاقة الدفع القابلة للتوسع
  Widget _buildModernPaymentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool isExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          iconColor: dropRed,
          collapsedIconColor: Colors.black26,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          children: children,
        ),
      ),
    );
  }

  // ودجت حقول الإدخال بتصميم مودرن
  Widget _buildModernTextField(String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: Colors.black45),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // الزر الأحمر الأساسي للتطبيق
  Widget _buildDropButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: dropRed,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  // زر الإضافة الشفاف
  Widget _buildAddNewMethod() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87),
      label: const Text("Add New Method", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}