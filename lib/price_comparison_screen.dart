import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'premium.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final TextEditingController _itemController = TextEditingController();
  final List<String> _shoppingCart = [];
  bool _isPremium = false;
  static const Color dropRed = Color(0xFFFF1111);

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      setState(() => _isPremium = doc.data()?['isPremium'] ?? false);
    }
  }

  void _addItem() {
    if (!_isPremium && _shoppingCart.isNotEmpty) {
      _showPremiumRequiredDialog();
      return;
    }
    if (_itemController.text.trim().isNotEmpty) {
      setState(() {
        _shoppingCart.add(_itemController.text.trim());
        _itemController.clear();
      });
    }
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("premium_feature".tr()),
        content: Text("basket_comparison_desc".tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("cancel_button".tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dropRed),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
            },
            child: Text("upgrade_now".tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("price_comparison_title".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: "compare_hint".tr(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_shopping_cart),
                  style: IconButton.styleFrom(backgroundColor: dropRed),
                ),
              ],
            ),
          ),
          if (_shoppingCart.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                children: _shoppingCart.map((item) => Chip(
                  label: Text(item),
                  onDeleted: () => setState(() => _shoppingCart.remove(item)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                )).toList(),
              ),
            ),
            const Divider(),
            Expanded(child: _buildComparisonLogic()),
          ] else
            Expanded(child: Center(child: Text("add_items_to_compare".tr(), style: const TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }

  Widget _buildComparisonLogic() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        Map<String, double> storeTotals = {};
        Map<String, int> storeMatchCount = {};

        for (var item in _shoppingCart) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final productName = (data['product'] ?? "").toString().toLowerCase();
            final storeName = data['storeName'] ?? "Unknown";
            final price = double.tryParse(data['newPrice']?.toString() ?? "0") ?? 0;

            if (productName.contains(item.toLowerCase())) {
              storeTotals[storeName] = (storeTotals[storeName] ?? 0) + price;
              storeMatchCount[storeName] = (storeMatchCount[storeName] ?? 0) + 1;
            }
          }
        }

        var sortedStores = storeTotals.keys.toList()
          ..sort((a, b) => storeTotals[a]!.compareTo(storeTotals[b]!));

        if (sortedStores.isEmpty) {
          return Center(child: Text("no_deals_found_for_basket".tr()));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sortedStores.length,
          itemBuilder: (context, index) {
            final store = sortedStores[index];
            final total = storeTotals[store];
            final matches = storeMatchCount[store];
            final isBest = index == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isBest ? Colors.green.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isBest ? Colors.green : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("matches_count".tr(args: [matches.toString(), _shoppingCart.length.toString()]),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  Text("${total?.toStringAsFixed(2)} JOD", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: isBest ? Colors.green : Colors.black)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
