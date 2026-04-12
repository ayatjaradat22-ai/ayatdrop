import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  static const Color dropRed = Color(0xFFFF1111);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> handleResetRequest() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Please enter a valid email address", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSent = true;
      });

      _showSnackBar("Reset link sent! Check your inbox.", Colors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar("Error: ${e.toString()}", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // أيقونة الأمان العصرية
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: dropRed.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded, color: dropRed, size: 60),
            ),

            const SizedBox(height: 30),
            const Text(
              "Forgot Password?",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "No worries! Enter your email and we'll send you a link to reset your password.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 40),

            // حقل الإيميل بتصميم Drop الموحد
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: dropRed, size: 22),
                  hintText: "Email Address",
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // زر الإرسال التفاعلي
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : handleResetRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSent ? Colors.green : dropRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isSent ? "LINK SENT ✅" : "RESET PASSWORD",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1
                  ),
                ),
              ),
            ),

            if (_isSent) ...[
              const SizedBox(height: 40),
              _buildSuccessMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 40),
          const SizedBox(height: 15),
          const Text(
            "Check Your Inbox",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a secure link to your email. Please follow the instructions to reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green[700], fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}