import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataSeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // دالة لقراءة ملف الـ JSON ورفعه إلى Firestore
  Future<void> seedUserBehaviorData() async {
    try {
      // 1. تحميل الملف من الـ Assets
      String jsonString = await rootBundle.loadString('assets/users_behavior.json');
      List<dynamic> data = json.decode(jsonString);

      // 2. رفع كل عنصر إلى Collection الـ deals
      for (var userAction in data) {
        await _db.collection('deals').add({
          'shop_name': userAction['shop_name'] ?? 'متجر غير معروف',
          'offer': userAction['offer'] ?? 'خصم حصري',
          'description': userAction['description'] ?? 'عرض رائع من Drop',
          'category': userAction['category'] ?? 'عام',
          'location': userAction['location'] ?? 'إربد',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      debugPrint("✅ Done: Data uploaded to 'deals' collection for AI Search!");
    } catch (e) {
      debugPrint("❌ Error seeding data: $e");
    }
  }
}
