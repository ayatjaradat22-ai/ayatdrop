import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  String? _photoUrl;
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
        imageQuality: 50,
        maxWidth: 512, // تصغير الحجم لتسريع الرفع وتجنب الأخطاء
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

  // استخدام putData بدلاً من putFile لحل مشاكل مسارات أندرويد
  Future<String> _uploadImage(File image) async {
    final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = '${user!.uid}_$timeStamp.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('profile_pics').child(fileName);
    
    // تحويل الملف إلى Bytes
    Uint8List imageData = await image.readAsBytes();
    
    // الرفع مع تحديد نوع المحتوى
    UploadTask uploadTask = storageRef.putData(
      imageData,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    // انتظار اكتمال الرفع تماماً
    TaskSnapshot snapshot = await uploadTask;
    
    // جلب الرابط بعد التأكد من وجود الملف
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty || user == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalPhotoUrl = _photoUrl;

      if (_imageFile != null) {
        // سيقوم الكود الآن بالانتظار حتى انتهاء الرفع الفعلي
        finalPhotoUrl = await _uploadImage(_imageFile!);
      }
      
      final newName = _nameController.text.trim();

      // حفظ البيانات في Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': newName,
        'photoUrl': finalPhotoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // تحديث Auth
      await user!.updateDisplayName(newName);
      if (finalPhotoUrl != null) {
        await user!.updatePhotoURL(finalPhotoUrl);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("profile_updated_success".tr()), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        // إظهار الخطأ بشكل أوضح للمساعدة في التتبع
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("خطأ في الحفظ"),
            content: Text(e.toString()),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover)
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
