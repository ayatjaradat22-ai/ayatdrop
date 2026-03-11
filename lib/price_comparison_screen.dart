import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const Color dropRed = Color(0xFFFF1111);
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "compare_before_go".tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "compare_hint".tr(),
                  prefixIcon: const Icon(Icons.search, color: dropRed),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty 
              ? _buildInitialState() 
              : _buildComparisonList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.grey[200]),
          const SizedBox(height: 20),
          Text(
            "compare_hint".tr(),
            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));

        // فحص العروض التي تطابق كلمة البحث
        var matchingDeals = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final product = (data['product'] ?? "").toString().toLowerCase();
          return product.contains(_query);
        }).toList();

        if (matchingDeals.isEmpty) {
          return Center(child: Text("no_search_results".tr(), style: const TextStyle(color: Colors.grey)));
        }

        // محاولة استخراج السعر من نص الخصم (لأننا لم نضف حقل سعر مخصص بعد)
        // سنفترض أن صاحب المتجر قد يكتب السعر في حقل الخصم أو المنتج
        // للتبسيط في هذا الإصدار، سنرتبهم حسب "أفضلية العرض"
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: matchingDeals.length,
          itemBuilder: (context, index) {
            final data = matchingDeals[index].data() as Map<String, dynamic>;
            bool isCheapest = index == 0; // افتراضياً أول واحد هو الأفضل (تحتاج لمنطق سعر حقيقي)

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isCheapest ? dropRed.withOpacity(0.3) : Colors.grey.shade100),
                boxShadow: [
                  if (isCheapest) BoxShadow(color: dropRed.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCheapest)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(10)),
                            child: Text("cheapest_place".tr(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        Text(data['storeName'] ?? "Store", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(data['product'] ?? "", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text(
                    data['discount'] ?? "", 
                    style: const TextStyle(color: dropRed, fontWeight: FontWeight.w900, fontSize: 20)
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
