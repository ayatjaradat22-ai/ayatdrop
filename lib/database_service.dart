import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // حفظ بيانات المستخدم
  Future<void> saveUserToFirestore({required String uid, required String name, required String email}) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': '', // تهيئة الحقل لتجنب أخطاء null
      'role': 'user', // تحديد الدور الافتراضي
      'isPremium': false,
      'totalSavings': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // حفظ بيانات المتجر
  Future<void> saveStoreToFirestore({
    required String uid,
    required String storeName,
    required String category,
    required String location,
    required String paymentMethod,
    required String email,
  }) async {
    await _db.collection('stores').doc(uid).set({
      'uid': uid,
      'storeName': storeName,
      'category': category,
      'location': location,
      'paymentMethod': paymentMethod,
      'email': email,
      'photoUrl': '', // تهيئة الحقل للمتاجر أيضاً
      'role': 'store',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
