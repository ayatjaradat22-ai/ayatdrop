import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'checkout_screen.dart';

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
  double? storeLat;
  double? storeLng;
  DateTime? subscriptionExpiry;
  DateTime? lastLocationUpdate;
  
  String? _editingDealId;
  DateTime _selectedExpiry = DateTime.now().add(const Duration(hours: 24));

  static const Color dropRed = Color(0xFFFF0000);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color scaffoldBg = Color(0xFFF9F6F2);

  bool _isPriceMode = true; 
  bool _isUpdatingLocation = false;

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
          if (data.containsKey('categories')) {
            _storeCategories = List<String>.from(data['categories']);
          } else if (data.containsKey('category')) {
            _storeCategories = [data['category']];
          }

          if (_storeCategories.isNotEmpty && _selectedDealCategory == null) {
            _selectedDealCategory = _storeCategories.first;
          }
          
          storeName = data['name'] ?? 'Store';
          storeLat = (data['lat'] as num?)?.toDouble();
          storeLng = (data['lng'] as num?)?.toDouble();
          subscriptionExpiry = (data['subscriptionExpiry'] as Timestamp?)?.toDate();
          lastLocationUpdate = (data['lastLocationUpdate'] as Timestamp?)?.toDate();
        });
      }
    }
  }

  Future<void> _resetLocationCooldown() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'lastLocationUpdate': FieldValue.delete(),
    });

    setState(() => lastLocationUpdate = null);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("DEBUG: Location cooldown reset!"), backgroundColor: Colors.orange)
      );
    }
  }

  Future<void> _updateLocation() async {
    if (lastLocationUpdate != null) {
      final difference = DateTime.now().difference(lastLocationUpdate!).inDays;
      if (difference < 30) {
        _showError("${"location_change_limit".tr()} ${"next_change_available".tr(args: [DateFormat('yyyy/MM/dd').format(lastLocationUpdate!.add(const Duration(days: 30)))])}");
        return;
      }
    }

    setState(() => _isUpdatingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isUpdatingLocation = false);
        _showError("location_service_disabled".tr());
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isUpdatingLocation = false);
          _showError("location_permission_denied".tr());
          return;
        }
      }

      // جلب الموقع الحالي بدقة عالية
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. تحديث موقع المتجر في جدول المستخدمين
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'lat': position.latitude,
        'lng': position.longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      // 2. تحديث موقع المتجر في جميع العروض المنشورة سابقاً لضمان انتقالها على الخريطة
      final dealsQuery = await FirebaseFirestore.instance
          .collection('deals')
          .where('storeId', isEqualTo: user.uid)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in dealsQuery.docs) {
        batch.update(doc.reference, {
          'lat': position.latitude,
          'lng': position.longitude,
        });
      }
      await batch.commit();
      
      setState(() {
        storeLat = position.latitude;
        storeLng = position.longitude;
        lastLocationUpdate = DateTime.now();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("save_changes".tr()), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isUpdatingLocation = false);
    }
  }

  void _processPayment(int days, double amount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          amount: amount,
          days: days,
          onSuccess: () => _executeRenewal(days),
        ),
      ),
    );
  }

  Future<void> _executeRenewal(int days) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime currentExpiry = subscriptionExpiry ?? DateTime.now();
    DateTime newExpiry = currentExpiry.isBefore(DateTime.now()) 
        ? DateTime.now().add(Duration(days: days))
        : currentExpiry.add(Duration(days: days));

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'subscriptionExpiry': Timestamp.fromDate(newExpiry),
      'isSubscribed': true,
      'lastPaymentDate': FieldValue.serverTimestamp(),
    });

    setState(() => subscriptionExpiry = newExpiry);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("publish_discount_button".tr()), backgroundColor: Colors.green));
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

  void _editDeal(String id, Map<String, dynamic> data) {
    setState(() {
      _editingDealId = id;
      _productController.text = data['product'] ?? "";
      _oldPriceController.text = (data['oldPrice'] ?? "").toString();
      _newPriceController.text = (data['newPrice'] ?? "").toString();
      _percentController.text = (data['discount'] ?? "").toString();
      _selectedDealCategory = data['category'];
      _selectedExpiry = (data['expiryTime'] as Timestamp).toDate();
      productName = _productController.text;
      discountPercent = "${_percentController.text}% OFF";
      _tabController.animateTo(0);
    });
  }

  Future<void> _publishOrUpdateDiscount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_productController.text.isEmpty || _oldPriceController.text.isEmpty || _selectedDealCategory == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("fill_all_fields_error".tr())));
      return;
    }

    if (storeLat == null || storeLng == null) {
      await _loadStoreData();
    }

    final dealData = {
      'discount': _percentController.text,
      'product': _productController.text,
      'oldPrice': _oldPriceController.text,
      'newPrice': _newPriceController.text,
      'category': _selectedDealCategory,
      'storeName': storeName,
      'storeId': user.uid,
      'lat': storeLat ?? 31.9539, 
      'lng': storeLng ?? 35.9106,
      'expiryTime': Timestamp.fromDate(_selectedExpiry),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_editingDealId != null) {
      await FirebaseFirestore.instance.collection('deals').doc(_editingDealId).update(dealData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("discount_published_success".tr())));
    } else {
      dealData['createdAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('deals').add(dealData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("discount_published_success".tr())));
    }

    _cancelEdit();
    _tabController.animateTo(1);
  }

  void _cancelEdit() {
    setState(() {
      _editingDealId = null;
      _percentController.clear();
      _productController.clear();
      _oldPriceController.clear();
      _newPriceController.clear();
      productName = "";
      discountPercent = "0% OFF";
      _selectedExpiry = DateTime.now().add(const Duration(hours: 24));
    });
  }

  void _deleteDeal(String id) async { 
    await FirebaseFirestore.instance.collection('deals').doc(id).delete(); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("cancel_edit".tr())));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: dropRed, size: 20), onPressed: () => Navigator.pop(context)),
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

          if (_storeCategories.length > 1) ...[
            Text("primary_cat_label".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: dropRed.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: dropRed, size: 20),
                  const SizedBox(width: 10),
                  Text("${"primary_cat_label".tr()}: ", style: const TextStyle(fontSize: 13)),
                  Text(_storeCategories.first.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: dropRed)),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 25),
          _buildStoreInput(_productController, "product_name_hint".tr(), (v) => setState(() => productName = v), limit: 30),
          const SizedBox(height: 18),
          
          _buildStoreInput(_oldPriceController, "السعر القديم (JOD)", (v) => _updateCalculations(), isNumber: true, limit: 6),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildStoreInput(
                  _newPriceController, 
                  "السعر الجديد", 
                  (v) { 
                    if (v.isNotEmpty) {
                      _isPriceMode = true; 
                      _percentController.clear();
                    }
                    _updateCalculations(); 
                  }, 
                  isNumber: true, 
                  limit: 6,
                  readOnly: !_isPriceMode && _percentController.text.isNotEmpty,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStoreInput(
                  _percentController, 
                  "النسبة (%)", 
                  (v) { 
                    if (v.isNotEmpty) {
                      _isPriceMode = false; 
                      _newPriceController.clear();
                    }
                    _updateCalculations(); 
                  }, 
                  isNumber: true, 
                  limit: 2,
                  readOnly: _isPriceMode && _newPriceController.text.isNotEmpty,
                ),
              ),
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
          if (_editingDealId != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton(onPressed: _cancelEdit, child: Center(child: Text("cancel_edit".tr(), style: const TextStyle(color: Colors.grey)))),
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
            DateTime? expiry = data['expiryTime'] != null ? (data['expiryTime'] as Timestamp).toDate() : null;
            int remainingHours = expiry != null ? expiry.difference(DateTime.now()).inHours : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: dropRed.withOpacity(0.1), child: Icon(_getDealIcon(data['category']), color: dropRed, size: 20)),
                title: Text(data['product'] ?? ""),
                subtitle: Text("${data['discount']}% ${"off_text".tr()} • ${data['newPrice'] ?? ""} ${"jod_currency".tr()} • ${remainingHours > 0 ? remainingHours : 0}${"hours_short".tr()} left"),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildStatusCard(daysLeft),
          const SizedBox(height: 30),
          _buildLocationUpdateSection(),
          const SizedBox(height: 30),
          _buildRenewalSection(),
          const SizedBox(height: 20),
          
          TextButton.icon(
            onPressed: _resetLocationCooldown,
            icon: const Icon(Icons.refresh_rounded, color: Colors.orange, size: 16),
            label: const Text("DEBUG: Reset 30-day Cooldown", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(int daysLeft) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Icon(Icons.stars_rounded, size: 80, color: daysLeft > 5 ? Colors.green : Colors.orange),
          const SizedBox(height: 15),
          Text("subscription_status".tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("${"days_left".tr()}: $daysLeft", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: daysLeft > 5 ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildLocationUpdateSection() {
    bool canUpdate = true;
    String nextUpdate = "";
    if (lastLocationUpdate != null) {
      final diff = DateTime.now().difference(lastLocationUpdate!).inDays;
      if (diff < 30) {
        canUpdate = false;
        nextUpdate = DateFormat('yyyy/MM/dd').format(lastLocationUpdate!.add(const Duration(days: 30)));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("change_location".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dropRed)),
          const SizedBox(height: 8),
          Text(canUpdate ? "location_change_limit".tr() : "${"location_change_limit".tr()} ${"next_change_available".tr(args: [nextUpdate])}", 
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: canUpdate ? dropRed : Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: canUpdate && !_isUpdatingLocation ? _updateLocation : null,
              icon: _isUpdatingLocation ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: dropRed)) : const Icon(Icons.my_location_rounded, color: dropRed),
              label: Text("get_my_location".tr(), style: TextStyle(color: canUpdate ? dropRed : Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewalSection() {
    return Column(
      children: [
        _buildRenewalOption("renew_monthly".tr(), Icons.calendar_today_rounded, dropRed.withOpacity(0.8), () => _processPayment(30, 5.0)),
        const SizedBox(height: 12),
        _buildRenewalOption("upgrade_yearly".tr(), Icons.auto_awesome_rounded, goldColor, () => _processPayment(365, 50.0)),
      ],
    );
  }

  Widget _buildRenewalOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(18), 
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            Icon(icon, color: color == goldColor ? Colors.black87 : Colors.white),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(color: color == goldColor ? Colors.black87 : Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color == goldColor ? Colors.black54 : Colors.white70, size: 14),
          ],
        ),
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
          Text("${_percentController.text}% ${"off_text".tr()}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          Text(productName.isEmpty ? "product_name_placeholder".tr() : productName, style: const TextStyle(color: Colors.white70)),
          if (oldP.isNotEmpty || newP.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (oldP.isNotEmpty) Text("$oldP ${"jod_currency".tr()}", style: const TextStyle(color: Colors.white60, decoration: TextDecoration.lineThrough, fontSize: 16)),
                  const SizedBox(width: 10),
                  if (newP.isNotEmpty) Text("$newP ${"jod_currency".tr()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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

  Widget _buildStoreInput(TextEditingController controller, String hint, Function(String) onChanged, {bool isNumber = false, int? limit, bool readOnly = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[100] : Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: readOnly ? Colors.transparent : Colors.grey.shade200)
      ),
      child: TextField(
        controller: controller, 
        onChanged: onChanged, 
        maxLength: limit,
        readOnly: readOnly,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, 
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, counterText: ""),
      ),
    );
  }
}