import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RecommendationService {
  final String apiKey;
  late final GenerativeModel _model;

  RecommendationService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  Future<String> findBestOfferForUser(String userQuery) async {
    try {
      debugPrint("🔍 Starting AI Search for: $userQuery");
      
      // التأكد من وجود بيانات في Firestore أولاً
      final snapshot = await FirebaseFirestore.instance.collection('deals').limit(15).get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint("⚠️ No deals found in Firestore");
        return "عذراً، لا توجد عروض متاحة حالياً في إربد.";
      }

      final List<Map<String, dynamic>> deals = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final dealsContext = deals.map((d) => 
        "- ${d['product']} في ${d['storeName']}: ${d['description']} (السعر: ${d['price']} دينار)"
      ).join("\n");

      final prompt = """
أنت مساعد ذكي واسمك "Drop AI"، خبير في عروض مدينة إربد وتعرف كل زوارقها ومحلاتها.
طلب المستخدم هو: "$userQuery"

إليك قائمة بالعروض المتاحة حالياً من تطبيق Drop:
$dealsContext

بناءً على طلب المستخدم، قم باختيار أفضل 3 عروض تناسبه. 
- إذا كان يبحث عن سعر رخيص، ركز على التوفير.
- إذا كان يبحث عن صنف معين، ركز عليه.
- أجب بلهجة إربداوية قُح، ودودة جداً، واستخدم كلمات مثل (يا قرابة، لقطة، يا كبير، على راسي، نغاشة، زقرت، يا هملالي، ليرة بتنطح ليرة).
- اجعل الرد يبدو وكأنك صديق لابن إربد يدله على أحسن العروض.
- إذا لم تجد طلباً مطابقاً تماماً، اقترح أقرب شيء "بمشي الحال" وشجعه بروح إيجابية.
""";

      debugPrint("📡 Sending to Gemini...");
      final response = await _model.generateContent([Content.text(prompt)]);
      debugPrint("✅ Gemini Response Received");

      if (response.text == null) {
        return "لم أستطع تحليل العروض حالياً، حاول مرة أخرى.";
      }

      return response.text!;

    } catch (e) {
      debugPrint("❌❌ AI ERROR: $e");
      // هذا السطر مهم جداً، رح يحكيلنا ليش الـ AI ما اشتغل بالضبط (مثلاً: Invalid API Key)
      if (e.toString().contains("API_KEY_INVALID")) {
        return "خطأ: مفتاح الـ API غير صالح. تأكدي من الملف .env";
      }
      return "يا ريت تحكيلي شو طلع معك خطأ بالزبط: ${e.toString()}";
    }
  }

  Future<String> getTenJdChallengeSuggestion(List<Map<String, dynamic>> deals) async {
    try {
      final dealsContext = deals.map((d) =>
          "- ${d['product']} في ${d['storeName']}: ${d['description']} (السعر: ${d['newPrice']} دينار)"
      ).join("\n");

      final prompt = """
أنت "ملك التوفير" في إربد، بتعرف كيف تصرف الـ 10 دنانير وتعمل فيها "ملك". ميزانية المستخدم هي 10 دنانير فقط (10 JD).
بناءً على قائمة العروض المتاحة التالية:
$dealsContext

قم باقتراح "خطة خرافية" (سهرة، غدوة، أو طلشة) للمستخدم بميزانية 10 دنانير.
- ادمج العروض بذكاء (مثلاً: ساندويشات من محل، وتحلية من محل ثاني، وعصير من مكان ثالث).
- احسب المجموع بدقة واحكيله كم بضل معه "فراطة".
- أجب بلهجة إربداوية فكاهية جداً وكأنك بتنصحه "يدبّر حاله" بأفضل طريقة.
- استخدم تعبيرات مثل: "يا بلاش"، "ولّعت"، "خاوه بتكفي"، "اربط حزامك"، "صافية وافية"، "دبّر حالك".
- إذا الميزانية صعبة على العروض الموجودة، أعطيه أفضل "لقطات" ممكنة ونكّت على الموضوع شوي.
""";

      debugPrint("📡 Sending 10 JD Challenge to Gemini...");
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "مش عارف أجمعلك عرض بـ 10 دنانير حالياً، بس جرب دور بالعروض المتاحة!";
    } catch (e) {
      debugPrint("❌ 10 JD Challenge AI Error: $e");
      return "صار مشكلة وأنا بحسبلك الـ 10 دنانير: ${e.toString()}";
    }
  }

  /// وظيفة مساعدة لتحويل البحث النصي لنتائج مباشرة (بدون AI) إذا لزم الأمر
  Future<List<Map<String, dynamic>>> searchDealsSimple(String query) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('deals')
          .where('product', isGreaterThanOrEqualTo: query)
          .where('product', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // نأخذ المعرف لنتمكن من الانتقال لصفحة العرض لاحقاً
        return data;
      }).toList();
    } catch (e) {
      debugPrint("❌ Simple Search Error: $e");
      return [];
    }
  }
}
