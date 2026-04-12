import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'database_service.dart';
import 'home.dart';
import 'theme/app_colors.dart';

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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> signUpUser() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passController.text.trim();
    final String confirmPassword = _confirmPassController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("fill_all_fields_error".tr());
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar("invalid_email_format".tr());
      return;
    }

    if (password.length < 6) {
      _showSnackBar("password_too_short".tr());
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("passwords_not_match".tr());
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.dropRed)),
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await DatabaseService().saveUserToFirestore(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);

      // تم حذف const هنا أيضاً
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // التأكد من إغلاق الـ Dialog تحديداً
      String errorMessage = "error_occurred".tr();
      if (e.code == 'email-already-in-use') {
        errorMessage = "email_already_used".tr();
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.dropRed),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Text("signup_title".tr(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 25),
                              _buildModernField(_nameController, "full_name_hint".tr(), Icons.person_outline, limit: 40),
                              const SizedBox(height: 15),
                              _buildModernField(_emailController, "email_hint".tr(), Icons.email_outlined, limit: 50),
                              const SizedBox(height: 15),
                              _buildModernField(_passController, "password_hint".tr(), Icons.lock_outline, isPass: _isPasswordHidden, limit: 32,
                                  suffix: IconButton(
                                    icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                                  )),
                              const SizedBox(height: 15),
                              _buildModernField(_confirmPassController, "confirm_password_hint".tr(), Icons.lock_reset_outlined, isPass: _isPasswordHidden, limit: 32),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity, height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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

  Widget _buildModernField(TextEditingController controller, String hint, IconData icon, {bool isPass = false, Widget? suffix, int? limit, List<TextInputFormatter>? formatters}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller, 
        obscureText: isPass,
        maxLength: limit,
        inputFormatters: formatters,
        decoration: InputDecoration(
          hintText: hint, 
          prefixIcon: Icon(icon), 
          suffixIcon: suffix, 
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.all(15),
          counterText: "",
        ),
      ),
    );
  }
}
