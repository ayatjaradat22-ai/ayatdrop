import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
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
        title: Text(
          "payment_methods".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),
            Text(
              "payment_security_note".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            _buildModernPaymentTile(
              title: "credit_debit_card".tr(),
              subtitle: "card_networks".tr(),
              icon: Icons.credit_card_rounded,
              isExpanded: true,
              children: [
                const SizedBox(height: 10),
                _buildModernTextField("card_number_hint".tr(), Icons.credit_card_rounded),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildModernTextField("expiry_hint".tr(), Icons.calendar_today_rounded)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildModernTextField("cvv_hint".tr(), Icons.lock_person_rounded)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDropButton("save_link_card".tr()),
              ],
            ),

            const SizedBox(height: 15),

            _buildModernPaymentTile(
              title: "apple_pay".tr(),
              subtitle: "express_checkout".tr(),
              icon: Icons.apple_rounded,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.face_unlock_rounded, color: isDark ? Colors.white70 : Colors.black),
                      const SizedBox(width: 12),
                      Text("pay_faster_faceid".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _buildDropButton("set_as_primary".tr()),
              ],
            ),

            const SizedBox(height: 15),

            _buildModernPaymentTile(
              title: "paypal".tr(),
              subtitle: "secure_online_payment".tr(),
              icon: Icons.account_balance_wallet_rounded,
              children: [
                _buildModernTextField("paypal_email_hint".tr(), Icons.alternate_email_rounded),
                const SizedBox(height: 15),
                _buildDropButton("connect_paypal".tr()),
              ],
            ),

            const SizedBox(height: 40),

            _buildAddNewMethod(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPaymentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool isExpanded = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          iconColor: dropRed,
          collapsedIconColor: isDark ? Colors.white24 : Colors.black26,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.grey[50], borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 24),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          children: children,
        ),
      ),
    );
  }

  Widget _buildModernTextField(String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: TextField(
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white38 : Colors.black45),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

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

  Widget _buildAddNewMethod() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? Colors.white : Colors.black87),
      label: Text("add_new_method".tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}