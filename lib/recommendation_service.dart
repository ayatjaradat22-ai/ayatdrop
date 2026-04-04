import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationService {
  final String apiKey;
  late final GenerativeModel _embeddingModel;

  RecommendationService({required this.apiKey}) {
    _embeddingModel = GenerativeModel(
      model: 'text-embedding-004',
      apiKey: apiKey,
    );
  }

  /// يحول نص البحث إلى Vector (Embedding)
  Future<List<double>> getVectorForQuery(String userQuery) async {
    try {
      final content = Content.text(userQuery);
      final response = await _embeddingModel.embedContent(content);
      return response.embedding.values;
    } catch (e) {
      print("❌ Error generating embedding: $e");
      return [];
    }
  }

  /// البحث عن أقرب النتائج في Firestore
  Future<List<Map<String, dynamic>>> findSimilarOffers(String userText) async {
    try {
      // 1. الحصول على الـ Vector للاستعلام
      List<double> userVector = await getVectorForQuery(userText);
      if (userVector.isEmpty) return [];

      // 2. البحث في Firestore
      // ملاحظة: يجب أن يكون لديك حقل 'embedding' من نوع VectorValue في Firestore
      // ويجب إنشاء الفهرس (Index) المناسب في Firebase Console
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_behavior') // نستخدم نفس الـ collection التي رفعنا إليها البيانات
          .findNearest(
            vectorField: 'embedding', // الحقل الذي تنشئه إضافة Firebase تلقائياً
            queryVector: VectorValue(userVector),
            distanceMeasure: DistanceMeasure.cosine,
            limit: 5,
          )
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("❌ Error during vector search: $e");
      return [];
    }
  }
}
