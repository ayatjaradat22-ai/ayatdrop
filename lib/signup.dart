import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'database_service.dart';
import 'home.dart';

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
  static const Color dropRed = Color(0xFFFF1111);

  Future<void> signUpUser() async {
    if (_passController.text != _confirmPassController.text) {
      _showSnackBar("passwords_not_match".tr());
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: dropRed)),
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      if (userCredential.user != null) {
        await DatabaseService().saveUserToFirestore(
          uid: userCredential.user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );

    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('images/signup.png', fit: BoxFit.cover)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
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
                              Text("signup_title".tr(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 25),
                              _buildModernField(_nameController, "full_name_hint".tr(), Icons.person_outline),
                              const SizedBox(height: 15),
                              _buildModernField(_emailController, "email_hint".tr(), Icons.email_outlined),
                              const SizedBox(height: 15),
                              _buildModernField(_passController, "password_hint".tr(), Icons.lock_outline, isPass: _isPasswordHidden,
                                  suffix: IconButton(
                                    icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                                  )),
                              const SizedBox(height: 15),
                              _buildModernField(_confirmPassController, "confirm_password_hint".tr(), Icons.lock_reset_outlined, isPass: _isPasswordHidden),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity, height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                  onPressed: signUpUser,
                                  child: Text("signup_button".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
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

  Widget _buildModernField(TextEditingController controller, String hint, IconData icon, {bool isPass = false, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller, obscureText: isPass,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon), suffixIcon: suffix, border: InputBorder.none, contentPadding: const EdgeInsets.all(15)),
      ),
    );
  }
}
