import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../recommendation_service.dart';

class AISearchScreen extends StatefulWidget {
  const AISearchScreen({super.key});

  @override
  State<AISearchScreen> createState() => _AISearchScreenState();
}

class _AISearchScreenState extends State<AISearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late RecommendationService _recommendationService;
  String _aiResponse = "";
  bool _isLoading = false;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _recommendationService = RecommendationService(apiKey: dotenv.get('GEMINI_API_KEY'));
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _aiResponse = "";
    });

    try {
      final results = await _recommendationService.findSimilarOffers(_searchController.text);
      
      setState(() {
        _isLoading = false;
        if (results.isNotEmpty) {
          final bestMatch = results.first;
          _aiResponse = "لقد وجدت لك عرضاً مميزاً! بناءً على بحثك عن '${_searchController.text}'، نقترح لك '${bestMatch['last_purchase']}' في منطقة ${bestMatch['location']}. هذا المكان يتناسب مع اهتمامك بـ ${bestMatch['interest']}.";
        } else {
          _aiResponse = "عذراً، لم أجد نتائج مطابقة تماماً حالياً، لكن يمكنك تجربة البحث عن كلمات أخرى مثل 'قهوة' أو 'ملابس'.";
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _aiResponse = "حدث خطأ أثناء البحث، يرجى المحاولة لاحقاً.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // طابع الـ AI الفخم
      appBar: AppBar(
        title: const Text("Drop AI Search", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // شريط الحالة المتحرك (Gradient Loading)
          if (_isLoading)
            AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [Colors.blue, Colors.purple, Colors.pink, Colors.blue],
                      begin: Alignment(-2.0 + _gradientController.value * 4, 0.0),
                      end: Alignment(0.0 + _gradientController.value * 4, 0.0),
                    ),
                  ),
                );
              },
            ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "شو جاي عبالك اليوم في إربد؟",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                  onPressed: _handleSearch,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _handleSearch(),
            ),
          ),

          Expanded(
            child: Center(
              child: _aiResponse.isEmpty && !_isLoading
                ? const Text("بانتظار طلبك...", style: TextStyle(color: Colors.grey, fontSize: 16))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 20.0,
                        color: Colors.white,
                        height: 1.6,
                        fontFamily: 'Cairo', // إذا كان متوفراً في مشروعك
                      ),
                      child: AnimatedTextKit(
                        key: ValueKey(_aiResponse), // لإعادة الحركة عند تغيير النص
                        animatedTexts: [
                          TypewriterAnimatedText(
                            _aiResponse,
                            speed: const Duration(milliseconds: 40),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        isRepeatingAnimation: false,
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
