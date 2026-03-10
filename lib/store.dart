import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_home.dart'; // الانتقال لصفحة المتجر بعد التسجيل

class StoreRegistrationScreen extends StatefulWidget {
  const StoreRegistrationScreen({super.key});

  @override
  State<StoreRegistrationScreen> createState() => _StoreRegistrationScreenState();
}

class _StoreRegistrationScreenState extends State<StoreRegistrationScreen> {
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController paymentController = TextEditingController();

  bool _isLoading = false;
  static const Color dropRed = Color(0xFFFF0000);
  static const Color scaffoldBg = Color(0xFFF9F6F2);

  // دالة تسجيل المتجر في Firestore
  Future<void> registerStore() async {
    if (storeNameController.text.isEmpty || categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء البيانات الأساسية للمتجر")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // حفظ بيانات المتجر
      DocumentReference docRef = await FirebaseFirestore.instance.collection('stores').add({
        'storeName': storeNameController.text.trim(),
        'category': categoryController.text.trim(),
        'location': locationController.text.trim(),
        'paymentMethod': paymentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // حالة المتجر (تحت المراجعة)
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إرسال طلب تسجيل المتجر بنجاح!"), backgroundColor: Colors.green),
      );

      // الانتقال لشاشة لوحة تحكم المتجر
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const StoreHomeScreen())
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل التسجيل: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: dropRed))
        : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.store_rounded, size: 80, color: dropRed),
              const SizedBox(height: 20),
              const Text(
                "Store Registration",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: dropRed, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              const Text("Enter your business details below", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 40),

              _buildStoreField(storeNameController, "Store Name", Icons.business_rounded),
              const SizedBox(height: 18),
              _buildStoreField(categoryController, "Category (e.g. Clothes, Food)", Icons.category_rounded),
              const SizedBox(height: 18),
              _buildStoreField(locationController, "Store Location (City, Street)", Icons.location_on_rounded),
              const SizedBox(height: 18),
              _buildStoreField(paymentController, "Payment Method (Wallet/IBAN)", Icons.payment_rounded),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dropRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                  onPressed: registerStore,
                  child: const Text("Register My Store", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back to Login", style: TextStyle(color: dropRed, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
