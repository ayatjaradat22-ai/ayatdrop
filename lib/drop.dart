import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password.dart';
import 'signup.dart';
import 'home.dart';
import 'store.dart';

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
    print("بدء عملية تسجيل الدخول..."); // للتأكد أن الدالة استدعيت

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: dropRed),
      ),
    );

    try {
      print("محاولة تسجيل الدخول بـ: ${emailController.text}");
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("نجح تسجيل الدخول!");
      
      if (!mounted) return;
      Navigator.of(context).pop(); // إغلاق الـ Loading

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      print("خطأ من فيربيز: ${e.code}");
      if (mounted) Navigator.of(context).pop();

      String message = "خطأ في تسجيل الدخول";
      if (e.code == 'user-not-found') {
        message = "هذا الحساب غير موجود";
      } else if (e.code == 'wrong-password') {
        message = "كلمة المرور خاطئة";
      } else if (e.code == 'invalid-email') {
        message = "صيغة الإيميل غير صحيحة";
      }

      _showErrorSnackBar(message);
    } catch (e) {
      print("خطأ غير متوقع: $e");
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar("حدث خطأ غير متوقع");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "images/sign_in_screan.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.15),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.04,
                              horizontal: screenWidth * 0.06,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Log in",
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.08,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                _input(emailController, Icons.email_outlined, "Email"),
                                const SizedBox(height: 20),
                                _input(
                                  passwordController,
                                  Icons.lock_outline,
                                  "Password",
                                  hide: _isPasswordHidden,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.black54,
                                    ),
                                    onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                      );
                                    },
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: dropRed, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: dropRed,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 5,
                                    ),
                                    onPressed: () {
                                      print("تم النقر على زر تسجيل الدخول");
                                      if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                                        loginUser();
                                      } else {
                                        _showErrorSnackBar("يرجى ملء جميع الحقول");
                                      }
                                    },
                                    child: const Text(
                                        "Log In",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text("Don't have an account? ", style: TextStyle(color: Colors.black87)),
                                      Text("Sign Up", style: TextStyle(color: dropRed, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                const Divider(color: Colors.black12),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const StoreRegistrationScreen()),
                                    );
                                  },
                                  child: Column(
                                    children: const [
                                      Icon(Icons.storefront_outlined, color: dropRed, size: 30),
                                      Text("Store", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
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
      controller: cont,
      obscureText: hide,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black87),
        suffixIcon: suffix,
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}
