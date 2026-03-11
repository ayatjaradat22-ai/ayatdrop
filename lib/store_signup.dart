import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';

class StoreSignUpScreen extends StatefulWidget {
  const StoreSignUpScreen({super.key});

  @override
  State<StoreSignUpScreen> createState() => _StoreSignUpScreenState();
}

class _StoreSignUpScreenState extends State<StoreSignUpScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = [
    'cat_food',
    'cat_fashion',
    'cat_cafes',
    'cat_tech',
    'cat_games',
    'cat_other'
  ];

  static const Color dropRed = Color(0xFFFF0000);
  static const Color scaffoldBg = Color(0xFFF9F6F2);

  Future<void> _registerStore({bool isDevMode = false}) async {
    if (passwordController.text != confirmPasswordController.text) {
      _showError("passwords_not_match".tr());
      return;
    }

    if (_selectedCategory == null) {
      _showError("select_category_error".tr());
      return;
    }

    if (!isDevMode && cardNumberController.text.length < 16) {
      _showError("invalid_card".tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      String uid;
      bool isExistingUser = false;

      try {
        // محاولة إنشاء حساب جديد
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        uid = userCredential.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // إذا كان البريد موجوداً مسبقاً، نحاول تسجيل الدخول لتحديث البيانات
          // ملاحظة: في تطبيق حقيقي يفضل استخدام تدفق التحقق، لكننا هنا سنقوم بالتحديث
          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
          uid = userCredential.user!.uid;
          isExistingUser = true;
        } else {
          rethrow;
        }
      }

      DateTime expiryDate = DateTime.now().add(const Duration(days: 30));

      // تحديث أو إنشاء وثيقة المستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'location': locationController.text.trim(),
        'category': _selectedCategory,
        'role': 'store', // سيصبح متجراً (ويمكنه الاستمرار كمشتري أيضاً)
        'isSubscribed': true,
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!isExistingUser) 'createdAt': FieldValue.serverTimestamp(),
        'lastPaymentStatus': isDevMode ? 'dev_bypass' : 'success',
        'monthlyFee': isDevMode ? 0.0 : 5.0,
      }, SetOptions(merge: true)); // دمج البيانات للحفاظ على البيانات القديمة للمشتري

      if (!mounted) return;
      
      String message = isExistingUser ? "account_upgraded_to_store".tr() : "store_registered_success".tr();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper(initialIndex: 0)),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "error_occurred".tr());
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
        actions: [
          TextButton(
            onPressed: () => _registerStore(isDevMode: true),
            child: const Text("DEV BYPASS", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: dropRed))
        : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Icon(Icons.add_business_rounded, size: 70, color: dropRed),
              const SizedBox(height: 15),
              Text(
                "store_signup_title".tr(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: dropRed),
              ),
              const SizedBox(height: 8),
              Text(
                "store_subscription_notice".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
              ),

              const SizedBox(height: 30),

              _buildStoreInputField(controller: nameController, hint: "store_name_hint".tr(), icon: Icons.store_outlined),
              const SizedBox(height: 15),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    hint: Text("select_category_hint".tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    items: _categories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              _buildStoreInputField(controller: emailController, hint: "store_email_hint".tr(), icon: Icons.email_outlined),
              const SizedBox(height: 15),
              _buildStoreInputField(controller: locationController, hint: "store_location_hint".tr(), icon: Icons.map_outlined),
              
              const Divider(height: 40),
              Align(alignment: Alignment.centerLeft, child: Text("payment_info".tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              _buildStoreInputField(controller: cardNumberController, hint: "card_number_hint".tr(), icon: Icons.credit_card, isNumber: true),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildStoreInputField(controller: expiryDateController, hint: "MM/YY", icon: Icons.date_range)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStoreInputField(controller: cvvController, hint: "CVV", icon: Icons.lock_person_outlined, isNumber: true)),
                ],
              ),
              const Divider(height: 40),

              _buildStoreInputField(
                controller: passwordController,
                hint: "password_hint".tr(),
                icon: Icons.lock_outline,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              const SizedBox(height: 15),
              _buildStoreInputField(
                controller: confirmPasswordController,
                hint: "confirm_password_hint".tr(),
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                isVisible: _isPasswordVisible,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dropRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => _registerStore(isDevMode: false),
                  child: Text("pay_and_signup".tr(args: ['5\$']), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
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
    bool isNumber = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: dropRed.withOpacity(0.7), size: 20),
          suffixIcon: isPassword ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.grey), onPressed: onToggle) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
