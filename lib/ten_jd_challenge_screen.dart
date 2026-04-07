import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'recommendation_service.dart';

class TenJdChallengeScreen extends StatefulWidget {
  const TenJdChallengeScreen({super.key});

  @override
  State<TenJdChallengeScreen> createState() => _TenJdChallengeScreenState();
}

class _TenJdChallengeScreenState extends State<TenJdChallengeScreen> {
  static const Color dropRed = Color(0xFFFF1111);
  late RecommendationService _recommendationService;
  String _aiSuggestion = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _recommendationService = RecommendationService(apiKey: dotenv.get('GEMINI_API_KEY'));
  }

  Future<void> _getAiPlan() async {
    setState(() {
      _isLoading = true;
      _aiSuggestion = "";
    });

    try {
      // 1. Fetch deals under 10 JD
      final snapshot = await FirebaseFirestore.instance
          .collection('deals')
          .get();
      
      final deals = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .where((d) {
            final price = double.tryParse(d['newPrice']?.toString() ?? d['price']?.toString() ?? "0") ?? 0;
            return price > 0 && price <= 10;
          })
          .toList();

      if (deals.isEmpty) {
        setState(() {
          _aiSuggestion = "للأسف ما لقيت عروض أقل من 10 دنانير حالياً، خليك متابعنا!";
          _isLoading = false;
        });
        return;
      }

      // 2. Get AI Suggestion
      final suggestion = await _recommendationService.getTenJdChallengeSuggestion(deals);

      setState(() {
        _aiSuggestion = suggestion;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiSuggestion = "حدث خطأ أثناء طلب الاقتراح الذكي. جرب مرة ثانية.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color ?? Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ten_jd_challenge".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator(color: Colors.green)),
              )
            else if (_aiSuggestion.isNotEmpty)
              _buildAiResponseCard()
            else
              _buildChallengeGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiResponseCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.green),
              const SizedBox(width: 10),
              Text("اقتراح Drop الذكي", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ],
          ),
          const Divider(height: 30),
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                _aiSuggestion,
                textStyle: const TextStyle(fontSize: 16, height: 1.6),
                speed: const Duration(milliseconds: 30),
              ),
            ],
            isRepeatingAnimation: false,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => setState(() => _aiSuggestion = ""),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("عرض العروض العادية"),
          )
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 50),
          const SizedBox(height: 15),
          Text(
            "ten_jd_challenge".tr(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "ten_jd_desc".tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _getAiPlan,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 10),
                const Text("خططلي بـ 10 دنانير", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final allDeals = snapshot.data!.docs;
        
        // تصفية العروض التي سعرها أقل من 10 دنانير بشكل فردي أو يمكن دمجها
        final List<List<DocumentSnapshot>> bundles = [];
        List<DocumentSnapshot> currentBundle = [];
        double currentTotal = 0;

        for (var doc in allDeals) {
          final data = doc.data() as Map<String, dynamic>;
          final price = double.tryParse(data['newPrice']?.toString() ?? data['price']?.toString() ?? "0") ?? 0;

          if (price > 0 && price <= 10) {
            if (currentTotal + price <= 10) {
              currentBundle.add(doc);
              currentTotal += price;
            } else {
              if (currentBundle.isNotEmpty) bundles.add(List.from(currentBundle));
              currentBundle = [doc];
              currentTotal = price;
            }
          }
        }
        if (currentBundle.isNotEmpty) bundles.add(currentBundle);

        if (bundles.isEmpty) {
          return Center(child: Text("coming_soon".tr()));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: bundles.length,
          itemBuilder: (context, index) {
            return _buildBundleCard(context, bundles[index]);
          },
        );
      },
    );
  }

  Widget _buildBundleCard(BuildContext context, List<DocumentSnapshot> items) {
    double total = 0;
    for (var item in items) {
      final data = item.data() as Map<String, dynamic>;
      total += double.tryParse(data['newPrice']?.toString() ?? data['price']?.toString() ?? "0") ?? 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text("items_bundle".tr(args: [items.length.toString()]), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Text("${total.toStringAsFixed(2)} JOD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 15),
          ...items.map((item) {
            final data = item.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildItemRow(data['storeName'] ?? "Store", data['product'] ?? "Item", data['newPrice']?.toString() ?? data['price']?.toString() ?? "0"),
            );
          }).toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("total_price".tr(args: [total.toStringAsFixed(2)]), style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {},
                child: Text("get_them_now".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String store, String product, String price) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
              children: [
                TextSpan(text: "$product ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "from_store".tr(args: [store]), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        Text("$price JOD", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
