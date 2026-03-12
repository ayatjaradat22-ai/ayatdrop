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
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();
  
  String discountPercent = "0% OFF";
  String productName = "";
  List<String> _storeCategories = [];
  String? _selectedDealCategory;
  String? storeName;
  DateTime? subscriptionExpiry;
  
  String? _editingDealId;
  DateTime _selectedExpiry = DateTime.now().add(const Duration(hours: 24));

  static const Color dropRed = Color(0xFFFF0000);
  static const Color scaffoldBg = Color(0xFFF9F6F2);

  bool _isPriceMode = true;

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
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // محاولة جلب الفئات من الحقل الجديد أو القديم لضمان التوافق
          if (data.containsKey('categories')) {
            _storeCategories = List<String>.from(data['categories']);
          } else if (data.containsKey('category')) {
            _storeCategories = [data['category']];
          }

          // اختيار التخصص تلقائياً إذا وجد تخصص واحد أو أكثر
          if (_storeCategories.isNotEmpty) {
            _selectedDealCategory = _storeCategories.first;
          }
          
          storeName = data['name'] ?? 'Store';
          subscriptionExpiry = (data['subscriptionExpiry'] as Timestamp?)?.toDate();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _percentController.dispose();
    _productController.dispose();
    _oldPriceController.dispose();
    _newPriceController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    double oldP = double.tryParse(_oldPriceController.text) ?? 0;
    if (_isPriceMode) {
      double newP = double.tryParse(_newPriceController.text) ?? 0;
      if (oldP > 0 && newP > 0 && oldP > newP) {
        double percent = ((oldP - newP) / oldP) * 100;
        setState(() {
          discountPercent = "${percent.toStringAsFixed(0)}% OFF";
          _percentController.text = percent.toStringAsFixed(0);
        });
      }
    } else {
      double percent = double.tryParse(_percentController.text) ?? 0;
      if (oldP > 0 && percent > 0 && percent < 100) {
        double newP = oldP - (oldP * (percent / 100));
        setState(() {
          discountPercent = "${percent.toStringAsFixed(0)}% OFF";
          _newPriceController.text = newP.toStringAsFixed(2);
        });
      }
    }
  }

  Future<void> _pickExpiry() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: dropRed)), child: child!),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedExpiry),
        builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: dropRed)), child: child!),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedExpiry = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(_editingDealId == null ? "store_dashboard".tr() : "edit_deal_title".tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
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

          // القسم المصلح: عرض التخصصات
          if (_storeCategories.length > 1) ...[
            Text("صنف هذا العرض ضمن:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _storeCategories.map((cat) {
                bool isSelected = _selectedDealCategory == cat;
                return ChoiceChip(
                  label: Text(cat.tr(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  selectedColor: dropRed,
                  onSelected: (selected) => setState(() => _selectedDealCategory = selected ? cat : null),
                );
              }).toList(),
            ),
          ] else if (_storeCategories.length == 1) ...[
            // إظهار التخصص الوحيد كمعلومة للمتجر
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: dropRed.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: dropRed, size: 20),
                  const SizedBox(width: 10),
                  Text("تخصص العرض: ", style: const TextStyle(fontSize: 13)),
                  Text(_storeCategories.first.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: dropRed)),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 25),
          _buildStoreInput(_productController, "product_name_hint".tr(), (v) => setState(() => productName = v)),
          const SizedBox(height: 18),
          
          _buildStoreInput(_oldPriceController, "السعر القديم (JOD)", (v) => _updateCalculations(), isNumber: true),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _buildStoreInput(_newPriceController, "السعر الجديد", (v) { _isPriceMode = true; _updateCalculations(); }, isNumber: true)),
              const SizedBox(width: 15),
              Expanded(child: _buildStoreInput(_percentController, "النسبة (%)", (v) { _isPriceMode = false; _updateCalculations(); }, isNumber: true)),
            ],
          ),
          
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
              child: Text(_editingDealId == null ? "publish_discount_button".tr() : "update_discount_button".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPicker() {
    String formattedDate = DateFormat('yyyy/MM/dd - HH:mm').format(_selectedExpiry);
    return GestureDetector(
      onTap: _pickExpiry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("expiry_time_label".tr(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Icon(Icons.alarm_on_rounded, color: dropRed, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildMyDealsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').where('storeId', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("no_deals_yet".tr()));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: dropRed.withOpacity(0.1), child: Icon(_getDealIcon(data['category']), color: dropRed, size: 20)),
                title: Text(data['product'] ?? ""),
                subtitle: Text("${data['discount']}% OFF • ${data['newPrice'] ?? ""} JOD"),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteDeal(id)),
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
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    String oldP = _oldPriceController.text;
    String newP = _newPriceController.text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: dropRed.withOpacity(0.2), blurRadius: 15)]),
      child: Column(
        children: [
          Icon(_getDealIcon(_selectedDealCategory), color: Colors.white, size: 40),
          const SizedBox(height: 15),
          Text("${_percentController.text}% OFF", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          Text(productName.isEmpty ? "product_name_placeholder".tr() : productName, style: const TextStyle(color: Colors.white70)),
          if (oldP.isNotEmpty || newP.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (oldP.isNotEmpty) Text("$oldP JOD", style: const TextStyle(color: Colors.white60, decoration: TextDecoration.lineThrough, fontSize: 16)),
                  const SizedBox(width: 10),
                  if (newP.isNotEmpty) Text("$newP JOD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getDealIcon(String? category) {
    switch (category) {
      case 'cat_food': return Icons.restaurant_rounded;
      case 'cat_cafes': return Icons.local_cafe_rounded;
      case 'cat_fashion': return Icons.shopping_bag_rounded;
      default: return Icons.storefront_rounded;
    }
  }

  Future<void> _publishOrUpdateDiscount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_productController.text.isEmpty || _oldPriceController.text.isEmpty || _selectedDealCategory == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إكمال البيانات الأساسية والسعر والتخصص")));
      return;
    }

    final dealData = {
      'discount': _percentController.text,
      'product': _productController.text,
      'oldPrice': _oldPriceController.text,
      'newPrice': _newPriceController.text,
      'category': _selectedDealCategory,
      'storeName': storeName,
      'storeId': user.uid,
      'expiryTime': Timestamp.fromDate(_selectedExpiry),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('deals').add(dealData);
    _percentController.clear(); _productController.clear(); _oldPriceController.clear(); _newPriceController.clear();
    _tabController.animateTo(1);
  }

  void _deleteDeal(String id) async { await FirebaseFirestore.instance.collection('deals').doc(id).delete(); }

  Widget _buildStoreInput(TextEditingController controller, String hint, Function(String) onChanged, {bool isNumber = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(controller: controller, onChanged: onChanged, keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(hintText: hint, border: InputBorder.none)),
    );
  }
}
