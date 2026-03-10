import 'package:flutter/material.dart';
import 'dart:ui';
// تأكدي من تعديل الـ imports لتناسب أسماء الملفات في مشروعك الجديد ayatdrop
// import 'package:ayatdrop/store_home.dart';
// import 'package:ayatdrop/forgot_password.dart';

class StoreLoginScreen extends StatefulWidget {
  const StoreLoginScreen({super.key});

  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  bool _isPasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // اللون الأحمر الصارخ (Vibrant Red)
  static const Color dropRed = Color(0xFFFF0000);
  // لون الخلفية الكريمي من صور الستور
  static const Color scaffoldBg = Color(0xFFF9F6F2);

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // أيقونة المتجر (مطابقة للصورة)
              const Icon(Icons.store_rounded, size: 80, color: dropRed),
              const SizedBox(height: 15),
              const Text(
                "Store Login",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: dropRed,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Welcome back! Login to your store account",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 50),

              // حقول الإدخال بتصميم الصور
              _buildStoreInputField(
                controller: emailController,
                hint: "Store Email",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              _buildStoreInputField(
                controller: passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                  },
                  child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: dropRed, fontSize: 12, fontWeight: FontWeight.w600)
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // زر الدخول (الأحمر الصارخ)
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
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreHomeScreen()));
                  },
                  child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // قسم تسجيل الدخول عبر السوشيال ميديا كما في الصورة
              const Text(
                "Or login with",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIcon(Icons.g_mobiledata, Colors.red), // يمكنك استبدالها بصور assets لاحقاً
                  const SizedBox(width: 20),
                  _socialIcon(Icons.apple, Colors.black),
                  const SizedBox(width: 20),
                  _socialIcon(Icons.facebook, Colors.blue),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت الحقول (أبيض مع ظل)
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
            color: Colors.black.withOpacity(0.04),
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
          prefixIcon: Icon(icon, color: dropRed.withOpacity(0.7), size: 20),
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

  // ويدجت أيقونات السوشيال ميديا الدائرية
  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 30, color: color),
    );
  }
}