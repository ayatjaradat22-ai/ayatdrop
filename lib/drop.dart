import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'forgot_password.dart';
import 'signup.dart';
import 'home.dart';
import 'store.dart';
import 'store_login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  static const Color dropRed = Color(0xFFFF1111);

  Future<void> loginUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: dropRed)),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );

    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop();
      String message = "login_failed".tr() + ": ${e.message}";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("images/sign_in_screan.png", fit: BoxFit.cover)),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.15),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Text("login_title".tr(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 30),
                                _input(emailController, Icons.email_outlined, "email_hint".tr()),
                                const SizedBox(height: 20),
                                _input(
                                  passwordController, Icons.lock_outline, "password_hint".tr(),
                                  hide: _isPasswordHidden,
                                  suffix: IconButton(
                                    icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity, height: 55,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                    onPressed: loginUser,
                                    child: Text("login_button".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("signup_prompt".tr() + " "),
                                      Text("signup_action".tr(), style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 25),
                                // أيقونة المتجر الحمراء تحت جملة إنشاء الحساب
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreLoginScreen())),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.storefront_rounded, color: dropRed, size: 30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _input(TextEditingController cont, IconData icon, String hint, {bool hide = false, Widget? suffix}) {
    return TextField(
      controller: cont, obscureText: hide,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black87),
        suffixIcon: suffix, hintText: hint, filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}
