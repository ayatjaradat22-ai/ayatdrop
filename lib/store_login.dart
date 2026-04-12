import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_signup.dart';
import 'home.dart';

class StoreLoginScreen extends StatefulWidget {
  const StoreLoginScreen({super.key});

  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  static const Color dropRed = Color(0xFFFF0000);
  static const Color scaffoldBg = Color(0xFFF9F6F2);

  Future<void> _loginStore() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("fill_all_fields_error".tr()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. تسجيل الدخول عبر Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. التحقق من دور المستخدم في Firestore للتأكد أنه متجر
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc.get('role') ?? 'user';
        if (role == 'store') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
        } else {
          // إذا كان حساب عادي يحاول الدخول من بوابة المتاجر
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This account is not registered as a store."), backgroundColor: Colors.orange),
          );
        }
      } else {
        _showError("error_occurred".tr());
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "login_failed".tr());
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
              const SizedBox(height: 15),
              Text(
                "store_login_title".tr(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: dropRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "store_login_subtitle".tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 50),

              _buildStoreInputField(
                controller: emailController,
                hint: "store_email_hint".tr(),
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              _buildStoreInputField(
                controller: passwordController,
                hint: "password_hint".tr(),
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dropRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _loginStore,
                  child: Text(
                    "login_button".tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("no_store_account".tr(), style: const TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreSignUpScreen())),
                    child: Text(
                      " ${"signup_action".tr()}",
                      style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: dropRed.withValues(alpha: 0.7), size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.grey),
            onPressed: onToggle,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}