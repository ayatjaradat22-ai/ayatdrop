import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  static const Color dropRed = Color(0xFFFF1111);
  
  File? _imageFile;
  String? _photoUrl; // سيحتوي على نص Base64 أو رابط قديم
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _nameController.text = data?['name'] ?? "";
          _photoUrl = data?['photoUrl'];
        });
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 25, // جودة منخفضة لأن Firestore لا يقبل ملفات ضخمة
        maxWidth: 300,   // تصغير العرض لتوفير المساحة
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }

  // تحويل الصورة إلى نص Base64 بدلاً من رفعها للستوريج
  Future<String> _convertImageToBase64(File image) async {
    Uint8List imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty || user == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalPhotoData = _photoUrl;

      if (_imageFile != null) {
        // بدلاً من الرفع، نحول الصورة لنص
        finalPhotoData = await _convertImageToBase64(_imageFile!);
      }
      
      final newName = _nameController.text.trim();

      // حفظ النص في Firestore مباشرة
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': newName,
        'photoUrl': finalPhotoData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // تحديث Auth (الاسم فقط، لأن الرابط النصي قد يكون طويلاً جداً لـ Auth)
      await user!.updateDisplayName(newName);
      await user!.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("profile_updated_success".tr()), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("تنبيه"),
            content: const Text("حدث خطأ أثناء الحفظ، يرجى التأكد من حجم الصورة المحملة."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("حسناً"))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, centerTitle: true, title: Text("edit_profile_title".tr())),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: dropRed))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildProfileImagePicker(),
                const SizedBox(height: 40),
                _buildInputField(context, "full_name_label".tr(), Icons.person_outline_rounded, _nameController),
                const SizedBox(height: 50),
                _buildSaveButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: dropRed, width: 2),
                image: _imageFile != null 
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : (_photoUrl != null && _photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: _photoUrl!.startsWith('http') 
                                ? NetworkImage(_photoUrl!) 
                                : MemoryImage(base64Decode(_photoUrl!)) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              child: (_imageFile == null && (_photoUrl == null || _photoUrl!.isEmpty))
                  ? const Icon(Icons.person, size: 60, color: dropRed)
                  : null,
            ),
            const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: dropRed, child: Icon(Icons.camera_alt, color: Colors.white, size: 18))),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String label, IconData icon, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      TextField(controller: controller, decoration: InputDecoration(prefixIcon: Icon(icon, color: dropRed), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
    ]);
  }

  Widget _buildSaveButton() {
    return SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
      onPressed: _updateProfile,
      style: ElevatedButton.styleFrom(backgroundColor: dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: Text("save_changes_button".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ));
  }
}
