import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as ll;
import '../../frontend/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  double _range = 10.0;
  List<String> _selectedCategories = [];
  final List<String> _allCategories = ['cat_food', 'cat_fashion', 'cat_cafes', 'cat_tech', 'cat_games'];
  ll.LatLng _currentUserLocation = const ll.LatLng(31.9539, 35.9106);

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
      
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentUserLocation = ll.LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error location: $e");
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
            _currentUserLocation = ll.LatLng(data['default_lat'], data['default_lng']);
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
      Position position = await Geolocator.getCurrentPosition();
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'default_lat': position.latitude,
          'default_lng': position.longitude,
        }, SetOptions(merge: true));
        
        setState(() {
          _currentUserLocation = ll.LatLng(position.latitude, position.longitude);
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
          SnackBar(content: Text("error_occurred".tr()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode(context);
    final primaryColor = AppColors.getPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getScaffoldBackground(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getPrimaryTextColor(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "notifications".tr(),
          style: TextStyle(color: AppColors.getPrimaryTextColor(context), fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(child: _buildSettingsHeader(isDark, primaryColor)),
          const Divider(height: 1),
          Expanded(
            child: _buildNotificationsList(primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.getSecondaryBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("notification_settings".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: _saveSettings, child: Text("save_changes".tr(), style: TextStyle(color: primaryColor))),
            ],
          ),
          const SizedBox(height: 15),
          Text("${"notification_range".tr()}: ${_range.toInt()} km", style: const TextStyle(fontSize: 14)),
          Slider(
            value: _range,
            min: 1,
            max: 20,
            activeColor: primaryColor,
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
                selectedColor: primaryColor,
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
              color: isDark ? Colors.grey[800] : Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
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

  Widget _buildNotificationsList(Color primaryColor) {
    if (user == null) return _buildEmptyState();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('following_stores')
          .snapshots(),
      builder: (context, followSnapshot) {
        if (!followSnapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryColor));
        
        final followedStoreIds = followSnapshot.data!.docs.map((doc) => doc.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('deals')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, dealsSnapshot) {
            if (!dealsSnapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryColor));

            final notifications = dealsSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final storeId = data['storeId'];
              final category = data['category']?.toString();

              if (followedStoreIds.contains(storeId)) return true;

              if (_selectedCategories.contains(category)) {
                if (data['lat'] != null && data['lng'] != null) {
                  double dist = Geolocator.distanceBetween(
                    _currentUserLocation.latitude,
                    _currentUserLocation.longitude,
                    data['lat'],
                    data['lng'],
                  ) / 1000;
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
                return _buildNotificationTile(data, isFollowed, primaryColor);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> data, bool isFollowed, Color primaryColor) {
    double dist = 0;
    if (data['lat'] != null && data['lng'] != null) {
      dist = Geolocator.distanceBetween(
        _currentUserLocation.latitude,
        _currentUserLocation.longitude,
        data['lat'],
        data['lng'],
      ) / 1000;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isFollowed ? primaryColor.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1), width: isFollowed ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isFollowed ? primaryColor.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isFollowed ? Icons.star_rounded : Icons.local_offer_rounded, color: isFollowed ? primaryColor : Colors.blue, size: 22),
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
                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(5)),
                        child: Text("following_label".tr().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text("${data['product']}: ${data['discount']}% OFF", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                const SizedBox(height: 4),
                Text(isFollowed ? "new_deal_from_followed".tr() : "near_you".tr(args: [dist.toStringAsFixed(1)]), 
                  style: TextStyle(color: isFollowed ? primaryColor : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
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
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
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
