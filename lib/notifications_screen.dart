import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color dropRed = Color(0xFFFF1111);
  final user = FirebaseAuth.instance.currentUser;

  double _range = 10.0; // الديفولت 10 كم
  List<String> _selectedCategories = [];
  final List<String> _allCategories = ['cat_food', 'cat_fashion', 'cat_cafes', 'cat_tech', 'cat_games'];

  // إحداثيات افتراضية (عمان) - يفضل مستقبلاً استخدام Geolocator لجلب موقع المستخدم الحقيقي
  final LatLng _currentUserLocation = const LatLng(31.9539, 35.9106);

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _range = (data['notif_range'] ?? 10.0).toDouble();
        _selectedCategories = List<String>.from(data['notif_categories'] ?? []);
      });
    }
  }

  Future<void> _saveSettings() async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'notif_range': _range,
      'notif_categories': _selectedCategories,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("save_changes".tr()), backgroundColor: Colors.green),
      );
      // الرجوع للشاشة السابقة (الهوم) بعد حفظ الإعدادات
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "notifications".tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          _buildSettingsHeader(),
          const Divider(height: 1),
          Expanded(
            child: _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("notification_settings".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: _saveSettings, child: Text("save_changes".tr(), style: const TextStyle(color: dropRed))),
            ],
          ),
          const SizedBox(height: 15),
          Text("${"notification_range".tr()}: ${_range.toInt()} km", style: const TextStyle(fontSize: 14)),
          Slider(
            value: _range,
            min: 1,
            max: 20,
            activeColor: dropRed,
            onChanged: (val) => setState(() => _range = val),
          ),
          const SizedBox(height: 10),
          Text("interested_categories".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _allCategories.map((cat) {
              bool isSelected = _selectedCategories.contains(cat);
              return FilterChip(
                label: Text(cat.tr(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
                selected: isSelected,
                selectedColor: dropRed,
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(cat);
                    } else {
                      _selectedCategories.remove(cat);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));
        
        // منطق الفلترة بناءً على الإعدادات
        final filteredDeals = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category']?.toString();
          
          // 1. فلترة الفئات
          if (_selectedCategories.isEmpty || !_selectedCategories.contains(category)) {
            return false;
          }

          // 2. فلترة المسافة
          if (data['lat'] != null && data['lng'] != null) {
            double dist = const Distance().as(
              LengthUnit.Kilometer,
              _currentUserLocation,
              LatLng(data['lat'], data['lng']),
            );
            return dist <= _range;
          }
          
          return false; // استبعاد أي عرض مجهول الموقع لضمان الدقة
        }).toList();

        if (filteredDeals.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredDeals.length,
          itemBuilder: (context, index) {
            final data = filteredDeals[index].data() as Map<String, dynamic>;
            return _buildNotificationTile(data);
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> data) {
    double dist = 0;
    if (data['lat'] != null && data['lng'] != null) {
      dist = const Distance().as(
        LengthUnit.Kilometer,
        _currentUserLocation,
        LatLng(data['lat'], data['lng']),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: dropRed.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_rounded, color: dropRed, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${data['storeName']}: ${data['discount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(data['product'] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Text("near_you".tr(args: [dist.toStringAsFixed(1)]), style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "no_notifications".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
