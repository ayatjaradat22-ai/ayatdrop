import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color dropRed = Color(0xFFFF1111);
  final user = FirebaseAuth.instance.currentUser;

  double _range = 10.0;
  List<String> _selectedCategories = [];
  final List<String> _allCategories = ['cat_food', 'cat_fashion', 'cat_cafes', 'cat_tech', 'cat_games'];
  LatLng _currentUserLocation = const LatLng(31.9539, 35.9106);

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _tryGetRealLocation();
  }

  Future<void> _tryGetRealLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _loadUserSettings() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _range = (data['notif_range'] ?? 10.0).toDouble();
        _selectedCategories = List<String>.from(data['notif_categories'] ?? []);
        if (data['default_lat'] != null && data['default_lng'] != null) {
          _currentUserLocation = LatLng(data['default_lat'], data['default_lng']);
        }
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
    }
  }

  Future<void> _setDefaultLocation() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("picking_location".tr())),
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'default_lat': position.latitude,
          'default_lng': position.longitude,
        }, SetOptions(merge: true));
        
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("default_location_saved".tr()), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("location_service_disabled".tr()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "notifications".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(child: _buildSettingsHeader(isDark)),
          const Divider(height: 1),
          Expanded(
            child: _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? Colors.grey[900] : Colors.grey[50],
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
                label: Text(cat.tr(), style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12)),
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "default_location_desc".tr(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _setDefaultLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text("set_default_location".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (user == null) return _buildEmptyState();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('following_stores')
          .snapshots(),
      builder: (context, followSnapshot) {
        if (!followSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));
        
        final followedStoreIds = followSnapshot.data!.docs.map((doc) => doc.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('deals')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, dealsSnapshot) {
            if (!dealsSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));

            final notifications = dealsSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final storeId = data['storeId'];
              final category = data['category']?.toString();

              // قاعدة 1: إذا كان المتجر من المتابعين، أظهره دائماً (أولوية قصوى) - حتى خارج النطاق
              if (followedStoreIds.contains(storeId)) return true;

              // قاعدة 2: إذا كان ضمن الفئات المفضلة والمدى الجغرافي
              if (_selectedCategories.contains(category)) {
                if (data['lat'] != null && data['lng'] != null) {
                  double dist = const Distance().as(
                    LengthUnit.Kilometer,
                    _currentUserLocation,
                    LatLng(data['lat'], data['lng']),
                  );
                  return dist <= _range;
                }
              }
              return false;
            }).toList();

            if (notifications.isEmpty) return _buildEmptyState();

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final data = notifications[index].data() as Map<String, dynamic>;
                bool isFollowed = followedStoreIds.contains(data['storeId']);
                return _buildNotificationTile(data, isFollowed);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> data, bool isFollowed) {
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isFollowed ? dropRed.withOpacity(0.3) : Colors.grey.withOpacity(0.1), width: isFollowed ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isFollowed ? dropRed.withOpacity(0.1) : Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isFollowed ? Icons.star_rounded : Icons.local_offer_rounded, color: isFollowed ? dropRed : Colors.blue, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("${data['storeName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (isFollowed) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(5)),
                        child: Text("following_label".tr().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text("${data['product']}: ${data['discount']}% OFF", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                const SizedBox(height: 4),
                Text(isFollowed ? "new_deal_from_followed".tr() : "near_you".tr(args: [dist.toStringAsFixed(1)]), 
                  style: TextStyle(color: isFollowed ? dropRed : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
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
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
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
