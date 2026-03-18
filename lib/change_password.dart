import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  static const Color dropRed = Color(0xFFFF1111);

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_newPasswordController.text);
        if (mounted) {
          _showSnackBar("Password updated successfully!", Colors.green);
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showSnackBar(e.message ?? "An error occurred", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Security Center",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // أيقونة الأمان المطورة
              _buildModernSecurityIcon(),

              const SizedBox(height: 30),
              Text(
                "Update Password",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                "Ensure your account is using a strong password to stay safe.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 40),

              // الحقول بستايل Drop الموحد
              _buildPasswordField("Current Password", _currentPasswordController, _obscureCurrent, () {
                setState(() => _obscureCurrent = !_obscureCurrent);
              }),
              const SizedBox(height: 20),
              _buildPasswordField("New Password", _newPasswordController, _obscureNew, () {
                setState(() => _obscureNew = !_obscureNew);
              }),
              const SizedBox(height: 20),
              _buildPasswordField("Confirm New Password", _confirmPasswordController, _obscureConfirm, () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              }),

              const SizedBox(height: 50),

              // زر الحفظ الاحترافي
              _buildSaveButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSecurityIcon() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: dropRed.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.shield_rounded, color: dropRed, size: 70),
          Positioned(
            top: 22,
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isObscure, VoidCallback onToggle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: dropRed, size: 20),
              suffixIcon: IconButton(
                icon: Icon(isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey[400], size: 20),
                onPressed: onToggle,
              ),
              hintText: "••••••••",
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey[300]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updatePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: dropRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          "SAVE CHANGES",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
        ),
      ),
    );
  }
}