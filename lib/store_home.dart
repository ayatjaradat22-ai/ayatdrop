import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _percentController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  
  String discountPercent = "0% OFF";
  String productName = "";
  String? storeCategory;
  String? storeName;
  DateTime? subscriptionExpiry;
  
  String? _editingDealId;
  int _selectedHours = 24;

  static const Color dropRed = Color(0xFFFF0000);
  static const Color scaffoldBg = Color(0xFFF9F6F2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          storeCategory = doc.get('category') ?? 'cat_other';
          storeName = doc.get('name') ?? 'Store';
          subscriptionExpiry = (doc.get('subscriptionExpiry') as Timestamp).toDate();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _percentController.dispose();
    _productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_editingDealId == null ? "store_dashboard".tr() : "edit_deal_title".tr(), 
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: dropRed,
          unselectedLabelColor: Colors.grey,
          indicatorColor: dropRed,
          tabs: [
            Tab(text: "tab_create".tr(), icon: const Icon(Icons.add_circle_outline)),
            Tab(text: "tab_my_deals".tr(), icon: const Icon(Icons.list_alt_rounded)),
            Tab(text: "tab_subs".tr(), icon: const Icon(Icons.vignette_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildMyDealsTab(),
          _buildSubscriptionTab(),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("discount_preview".tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          _buildPreviewCard(),
          const SizedBox(height: 40),
          
          _buildStoreInput(_percentController, "discount_hint".tr(), (v) => setState(() => discountPercent = "$v OFF")),
          const SizedBox(height: 18),
          _buildStoreInput(_productController, "product_name_hint".tr(), (v) => setState(() => productName = v)),
          
          const SizedBox(height: 25),
          Text("deal_duration_label".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildDurationPicker(),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _publishOrUpdateDiscount,
              child: Text(_editingDealId == null ? "publish_discount_button".tr() : "update_discount_button".tr(), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          if (_editingDealId != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: () => setState(() { _editingDealId = null; _percentController.clear(); _productController.clear(); }),
                child: Center(child: Text("cancel_edit".tr(), style: const TextStyle(color: Colors.grey))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationPicker() {
    final List<int> hours = [24, 48, 72, 168];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: hours.map((h) {
        bool isSel = _selectedHours == h;
        return GestureDetector(
          onTap: () => setState(() => _selectedHours = h),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? dropRed : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? dropRed : Colors.grey.shade300),
            ),
            child: Text(h < 168 ? "$h ${"hours_short".tr()}" : "1 ${"week_short".tr()}", 
                style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyDealsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || storeName == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deals')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // الفلترة: يظهر العرض إذا كان storeId يطابقني، أو storeName يطابق اسمي الحالي، 
          // أو إذا كان يحمل الاسم التجريبي القديم (للسماح بالتنظيف).
          return data['storeId'] == user.uid || 
                 data['storeName'] == storeName || 
                 data['storeName'] == "اسم المتجر التجريبي";
        }).toList();

        if (docs.isEmpty) return Center(child: Text("no_deals_yet".tr()));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            
            DateTime? expiry;
            if (data['expiryTime'] != null) {
              if (data['expiryTime'] is Timestamp) {
                expiry = (data['expiryTime'] as Timestamp).toDate();
              } else {
                expiry = DateTime.tryParse(data['expiryTime'].toString());
              }
            }
            
            int remainingHours = expiry != null ? expiry.difference(DateTime.now()).inHours : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: dropRed.withOpacity(0.1), child: Icon(_getCategoryIcon(), color: dropRed, size: 20)),
                title: Text(data['product'] ?? ""),
                subtitle: Text("${data['discount']} • ${remainingHours > 0 ? remainingHours : 0}h left"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editDeal(id, data)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteDeal(id)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubscriptionTab() {
    int daysLeft = subscriptionExpiry != null ? subscriptionExpiry!.difference(DateTime.now()).inDays : 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_rounded, size: 100, color: daysLeft > 5 ? Colors.green : Colors.orange),
          const SizedBox(height: 20),
          Text("subscription_status".tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("${"days_left".tr()}: $daysLeft", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: daysLeft > 5 ? Colors.green : Colors.red)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: () {},
            child: Text("renew_subscription".tr(), style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: dropRed.withOpacity(0.2), blurRadius: 15)]),
      child: Column(
        children: [
          Icon(_getCategoryIcon(), color: Colors.white, size: 40),
          const SizedBox(height: 15),
          Text(discountPercent, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          Text(productName.isEmpty ? "product_name_placeholder".tr() : productName, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (storeCategory) {
      case 'cat_food': return Icons.restaurant_rounded;
      case 'cat_cafes': return Icons.local_cafe_rounded;
      case 'cat_fashion': return Icons.shopping_bag_rounded;
      default: return Icons.storefront_rounded;
    }
  }

  Future<void> _publishOrUpdateDiscount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_percentController.text.isEmpty || _productController.text.isEmpty || user == null) return;

    DateTime expiryDate = DateTime.now().add(Duration(hours: _selectedHours));

    final dealData = {
      'discount': _percentController.text,
      'product': _productController.text,
      'category': storeCategory,
      'storeName': storeName,
      'storeId': user.uid,
      'expiryTime': Timestamp.fromDate(expiryDate),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (_editingDealId == null) {
      await FirebaseFirestore.instance.collection('deals').add(dealData);
    } else {
      await FirebaseFirestore.instance.collection('deals').doc(_editingDealId).update(dealData);
      setState(() => _editingDealId = null);
    }
    
    _percentController.clear();
    _productController.clear();
    _tabController.animateTo(1);
  }

  void _deleteDeal(String id) async {
    await FirebaseFirestore.instance.collection('deals').doc(id).delete();
  }

  void _editDeal(String id, Map<String, dynamic> data) {
    setState(() {
      _editingDealId = id;
      _percentController.text = data['discount'] ?? "";
      _productController.text = data['product'] ?? "";
      _tabController.animateTo(0);
    });
  }

  Widget _buildStoreInput(TextEditingController controller, String hint, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(controller: controller, onChanged: onChanged, decoration: InputDecoration(hintText: hint, border: InputBorder.none)),
    );
  }
}
