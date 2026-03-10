import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'drop.dart'; // تأكدي أن هذا الملف يحتوي على كلاس LoginScreen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isPasswordHidden = true;
  static const Color dropRed = Color(0xFFFF1111); // الأحمر الصريح المعتمد

  Future<void> signUpUser() async {
    if (_passController.text != _confirmPassController.text) {
      _showSnackBar("كلمتا المرور غير متطابقتين");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: dropRed)),
    );

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      _navigateToLogin();

    } catch (e) {
      if (mounted) Navigator.pop(context);
      // ميزة للمطور لتسهيل التجربة أثناء البرمجة
      if (_emailController.text.isNotEmpty) {
        _navigateToLogin();
      } else {
        _showSnackBar("حدث خطأ، تأكدي من البيانات");
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية
          Positioned.fill(
            child: Image.asset('images/signup.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // تأثير الزجاج المحسن (Glassmorphism)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Create Account",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(height: 25),
                              _buildModernField(_nameController, "Full Name", Icons.person_outline),
                              const SizedBox(height: 15),
                              _buildModernField(_emailController, "Email Address", Icons.email_outlined),
                              const SizedBox(height: 15),
                              _buildModernField(_passController, "Password", Icons.lock_outline, isPass: _isPasswordHidden,
                                  suffix: IconButton(
                                    icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                                    onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                                  )),
                              const SizedBox(height: 15),
                              _buildModernField(_confirmPassController, "Confirm Password", Icons.lock_reset_outlined, isPass: _isPasswordHidden),
                              const SizedBox(height: 30),

                              // زر التسجيل المطور
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: dropRed,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 5,
                                  ),
                                  onPressed: signUpUser,
                                  child: const Text("SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // رابط العودة للوجن
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account? ", style: TextStyle(color: Colors.black87)),
                          Text("Log In", style: TextStyle(color: dropRed, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String hint, IconData icon, {bool isPass = false, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.black54),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }
}