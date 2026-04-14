import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CheckoutScreen extends StatefulWidget {
  final double amount;
  final int days;
  final VoidCallback onSuccess;

  const CheckoutScreen({
    super.key,
    required this.amount,
    required this.days,
    required this.onSuccess,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _isProcessing = false;

  static const Color dropRed = Color(0xFFFF1111);

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_cardController.text.length < 16 || _expiryController.text.isEmpty || _cvvController.text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("invalid_card".tr()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // محاكاة عملية الدفع البنكية
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      widget.onSuccess();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("payment_info".tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ملخص العملية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dropRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dropRed.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("تجديد الاشتراك", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 5),
                      Text("${widget.days} ${"hours_short".tr().replaceAll('ساعة', 'يوم')}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Text("${widget.amount} JOD", style: const TextStyle(color: dropRed, fontWeight: FontWeight.w900, fontSize: 24)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            Text("card_number_hint".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildField(_cardController, "xxxx xxxx xxxx xxxx", Icons.credit_card, true),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("تاريخ الانتهاء", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildField(_expiryController, "MM/YY", Icons.calendar_month, false),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CVV", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildField(_cvvController, "***", Icons.lock_outline, true),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dropRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _pay,
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("pay_and_signup".tr(args: ["${widget.amount} JOD"]), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text("دفع آمن ومسفر عبر Drop", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, bool isNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }
}
