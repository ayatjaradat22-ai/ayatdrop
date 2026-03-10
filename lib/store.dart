import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'store_home.dart';

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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  static const Color dropRed = Color(0xFFFF1111);

  Future<void> registerStore() async {
    if (storeNameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. إنشاء حساب المتجر في Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. حفظ بيانات المتجر في Firestore
      if (userCredential.user != null) {
        await DatabaseService().saveStoreToFirestore(
          uid: userCredential.user!.uid,
          storeName: storeNameController.text.trim(),
          category: categoryController.text.trim(),
          location: locationController.text.trim(),
          paymentMethod: paymentController.text.trim(),
          email: emailController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StoreHomeScreen()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey), onPressed: () => Navigator.pop(context))),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: dropRed))
      : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Icon(Icons.store_rounded, size: 80, color: dropRed),
              const SizedBox(height: 20),
              const Text("Store Registration", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: dropRed)),
              const SizedBox(height: 40),
              _buildField(storeNameController, "Store Name", Icons.business),
              const SizedBox(height: 15),
              _buildField(emailController, "Email", Icons.email),
              const SizedBox(height: 15),
              _buildField(passwordController, "Password", Icons.lock, isPass: true),
              const SizedBox(height: 15),
              _buildField(categoryController, "Category", Icons.category),
              const SizedBox(height: 15),
              _buildField(locationController, "Location", Icons.location_on),
              const SizedBox(height: 15),
              _buildField(paymentController, "Payment Info", Icons.payment),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: registerStore,
                  child: const Text("Register My Store", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool isPass = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: TextField(controller: controller, obscureText: isPass, decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.grey[400]), hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(18))),
    );
  }
}
