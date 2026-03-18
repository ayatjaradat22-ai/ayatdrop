import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class SmartShoppingListScreen extends StatefulWidget {
  const SmartShoppingListScreen({super.key});

  @override
  State<SmartShoppingListScreen> createState() => _SmartShoppingListScreenState();
}

class _SmartShoppingListScreenState extends State<SmartShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  static const Color dropRed = Color(0xFFFF1111);

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty || user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('shopping_list')
        .add({
      'name': _itemController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isBought': false,
    });

    _itemController.clear();
  }

  Future<void> _removeItem(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('shopping_list')
        .doc(id)
        .delete();
  }

  void _findDealsForItem(String itemName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "finding_deals_for".tr(args: [itemName]),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ),
            Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('deals').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));
                  
                  final results = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final product = (data['product'] ?? "").toString().toLowerCase();
                    return product.contains(itemName.toLowerCase());
                  }).toList();

                  if (results.isEmpty) {
                    return Center(child: Text("no_deals_found_for_item".tr(), style: const TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final data = results[index].data() as Map<String, dynamic>;
                      return Card(
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          title: Text(data['product'] ?? "", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                          subtitle: Text(data['storeName'] ?? "", style: const TextStyle(color: Colors.grey)),
                          trailing: Text("${data['newPrice']} ${"jod_currency".tr()}", style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "smart_shopping_list".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _itemController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "shopping_list_hint".tr(),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addItem,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('shopping_list')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text("no_items_in_list".tr(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    return _buildShoppingItem(id, data['name']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(String id, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: ListTile(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => _findDealsForItem(name),
              icon: const Icon(Icons.search, size: 16, color: dropRed),
              label: Text("find_deals_for_item".tr(), style: const TextStyle(color: dropRed, fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
              onPressed: () => _removeItem(id),
            ),
          ],
        ),
      ),
    );
  }
}
