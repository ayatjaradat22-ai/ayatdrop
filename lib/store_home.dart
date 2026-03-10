import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // أضفت هذا السطر

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  final TextEditingController _percentController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  
  String discountPercent = "0% OFF";
  String productName = "on Product Name";
  Duration _duration = const Duration(hours: 24);
  Timer? _timer;

  static const Color dropRed = Color(0xFFFF0000);
  static const Color scaffoldBg = Color(0xFFF9F6F2);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration.inSeconds > 0) {
        if (mounted) setState(() => _duration = _duration - const Duration(seconds: 1));
      } else {
        _timer?.cancel();
      }
    });
  }

  // دالة نشر الخصم في Firestore
  Future<void> publishDiscount() async {
    if (_percentController.text.isEmpty || _productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إكمال بيانات الخصم")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: dropRed)),
    );

    try {
      await FirebaseFirestore.instance.collection('deals').add({
        'discount': _percentController.text,
        'product': _productController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'expiryTime': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'storeName': "اسم المتجر التجريبي", // يمكن تغييره لاحقاً لاسم المتجر الحقيقي
      });

      if (!mounted) return;
      Navigator.pop(context); // إغلاق الـ Loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم نشر الخصم بنجاح!"), backgroundColor: Colors.green),
      );

      // إعادة تعيين الحقول
      _percentController.clear();
      _productController.clear();

    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل النشر: $e")),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _percentController.dispose();
    _productController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Store Dashboard",
            style: TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text("Live Discount Preview",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: dropRed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: dropRed.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    Text(discountPercent,
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(productName,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(_formatDuration(_duration),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              const Text("Create Your Discount",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 20),

              _buildStoreInput(_percentController, "Discount % (e.g. 50%)", (v) => setState(() => discountPercent = "$v OFF")),
              const SizedBox(height: 18),
              _buildStoreInput(_productController, "Product Name", (v) => setState(() => productName = "on $v")),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dropRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    shadowColor: dropRed.withOpacity(0.3),
                  ),
                  onPressed: publishDiscount,
                  child: const Text("Publish Discount",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreInput(TextEditingController controller, String hint, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
