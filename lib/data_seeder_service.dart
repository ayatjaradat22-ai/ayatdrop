import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // دالة لقراءة ملف الـ JSON ورفعه إلى Firestore
  Future<void> seedUserBehaviorData() async {
    try {
      // 1. تحميل الملف من الـ Assets
      String jsonString = await rootBundle.loadString('assets/users_behavior.json');
      List<dynamic> data = json.decode(jsonString);

      // 2. رفع كل عنصر إلى Collection مخصصة
      for (var userAction in data) {
        await _db.collection('user_behavior').add({
          ...userAction,
          'timestamp': FieldValue.serverTimestamp(), // لإعطاء الـ AI تسلسل زمني
        });
      }
      print("✅ Done: Data uploaded for Vector Search!");
    } catch (e) {
      print("❌ Error seeding data: $e");
    }
  }
}
