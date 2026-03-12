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
  final TextEditingController otherCategoryController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String? _primaryCategory; // الفئة الأولى (إجبارية)
  String? _secondaryCategory; // الفئة الثانية (اختيارية)

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

    if (_primaryCategory == null) {
      _showError("يرجى اختيار التخصص الأساسي للمتجر!");
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
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        uid = userCredential.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
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

      // تجهيز الفئات النهائية (معالجة خيار "أخرى")
      List<String> finalCategories = [];
      
      // معالجة الفئة الأساسية
      if (_primaryCategory == 'cat_other' && otherCategoryController.text.isNotEmpty) {
        finalCategories.add(otherCategoryController.text.trim());
      } else {
        finalCategories.add(_primaryCategory!);
      }

      // معالجة الفئة الثانوية (اختيارية)
      if (_secondaryCategory != null) {
        if (_secondaryCategory == 'cat_other' && otherCategoryController.text.isNotEmpty) {
          String otherVal = otherCategoryController.text.trim();
          if (!finalCategories.contains(otherVal)) finalCategories.add(otherVal);
        } else {
          finalCategories.add(_secondaryCategory!);
        }
      }

      DateTime expiryDate = DateTime.now().add(const Duration(days: 30));

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'location': locationController.text.trim(),
        'categories': finalCategories,
        'role': 'store',
        'isSubscribed': true,
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!isExistingUser) 'createdAt': FieldValue.serverTimestamp(),
        'lastPaymentStatus': isDevMode ? 'dev_bypass' : 'success',
        'monthlyFee': isDevMode ? 0.0 : 5.0,
      }, SetOptions(merge: true));

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
              const SizedBox(height: 25),
              
              // اختيار التخصص الأساسي (إجباري)
              Align(alignment: Alignment.centerRight, child: Text("التخصص الأساسي (إجباري)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  bool isSelected = _primaryCategory == cat;
                  return ChoiceChip(
                    label: Text(cat.tr(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: dropRed,
                    onSelected: (selected) {
                      setState(() {
                        _primaryCategory = selected ? cat : null;
                        if (_secondaryCategory == cat) _secondaryCategory = null; // لا يمكن تكرار نفس التخصص
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // اختيار التخصص الثانوي (اختياري)
              Align(alignment: Alignment.centerRight, child: Text("تخصص إضافي (اختياري)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  bool isSelected = _secondaryCategory == cat;
                  bool isPrimary = _primaryCategory == cat;
                  return ChoiceChip(
                    label: Text(cat.tr(), style: TextStyle(color: isSelected ? Colors.white : (isPrimary ? Colors.grey.shade300 : Colors.black87), fontSize: 12)),
                    selected: isSelected,
                    selectedColor: Colors.black87,
                    onSelected: isPrimary ? null : (selected) {
                      setState(() {
                        _secondaryCategory = selected ? cat : null;
                      });
                    },
                  );
                }).toList(),
              ),

              if (_primaryCategory == 'cat_other' || _secondaryCategory == 'cat_other')
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: _buildStoreInputField(controller: otherCategoryController, hint: "اكتب التخصص الآخر هنا...", icon: Icons.edit_note_rounded),
                ),

              const SizedBox(height: 20),
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
