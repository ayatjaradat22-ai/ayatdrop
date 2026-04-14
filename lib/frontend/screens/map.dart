import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'premium.dart';
import '../../frontend/theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  final LatLng? targetLocation;
  const MapScreen({super.key, this.targetLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _initialCenter = const LatLng(31.9539, 35.9106);
  Position? _userPosition;
  late AnimationController _fireAnimationController;
  String? _selectedCategory;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fireAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    if (widget.targetLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.targetLocation!, 15.0);
      });
    }
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetLocation != null && widget.targetLocation != oldWidget.targetLocation) {
      _mapController.move(widget.targetLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _fireAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("location_service_disabled".tr()), backgroundColor: Colors.orange)
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
          if (widget.targetLocation == null) {
            _initialCenter = LatLng(position.latitude, position.longitude);
            _mapController.move(_initialCenter, 14.0);
          }
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final Uri geoUrl = Uri.parse("geo:$lat,$lng?q=$lat,$lng");
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("error_occurred".tr(args: [e.toString()])), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _calculateDistance(double storeLat, double storeLng) {
    if (_userPosition == null) return "";
    double distanceInMeters = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      storeLat,
      storeLng,
    );
    double distanceInKm = distanceInMeters / 1000;
    return "${distanceInKm.toStringAsFixed(1)} ${"km_unit".tr()}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('deals').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.dropRed));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                Map<String, List<DocumentSnapshot>> storeDeals = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (data['expiryTime'] != null) {
                    DateTime expiry = (data['expiryTime'] as Timestamp).toDate();
                    if (expiry.isBefore(DateTime.now())) continue;
                  }

                  String? category = data['category']?.toString();
                  if (_selectedCategory != null && category != _selectedCategory) continue;

                  String storeId = data['storeId'] ?? doc.id;
                  if (!storeDeals.containsKey(storeId)) {
                    storeDeals[storeId] = [];
                  }
                  storeDeals[storeId]!.add(doc);
                }

                List<Marker> markers = [];

                if (_userPosition != null) {
                  markers.add(
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10)],
                        ),
                      ),
                    ),
                  );
                }

                storeDeals.forEach((storeId, deals) {
                  final firstDealData = deals.first.data() as Map<String, dynamic>;
                  double lat = (firstDealData['lat'] as num?)?.toDouble() ?? 31.9539;
                  double lng = (firstDealData['lng'] as num?)?.toDouble() ?? 35.9106;

                  bool hasHotDeal = deals.any((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    double discount = double.tryParse(d['discount']?.toString() ?? "0") ?? 0;
                    return discount > 10;
                  });

                  markers.add(
                    Marker(
                      point: LatLng(lat, lng),
                      width: 100,
                      height: 140,
                      rotate: true,
                      alignment: Alignment.topCenter,
                      child: _buildStoreMarker(storeId, firstDealData, deals, hasHotDeal),
                    ),
                  );
                });

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.targetLocation ?? _initialCenter,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.drop',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
            ),
          ),

          _buildTopSearchAndFilters(),

          Positioned(
            right: 20,
            bottom: 120,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.dropRed),
              onPressed: () {
                if (_userPosition != null) {
                  _mapController.move(LatLng(_userPosition!.latitude, _userPosition!.longitude), 15.0);
                } else {
                  _getCurrentLocation();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreMarker(String storeId, Map<String, dynamic> storeData, List<DocumentSnapshot> deals, bool hasHotDeal) {
    String storeName = storeData['storeName'] ?? "Store";
    String? category = storeData['category']?.toString();
    int dealsCount = deals.length;

    return GestureDetector(
      onTap: () => _showStoreDealsSheet(storeId, storeName, (storeData['lat'] as num?)?.toDouble() ?? 31.9539, (storeData['lng'] as num?)?.toDouble() ?? 35.9106, deals),
      child: Container(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dropRed,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                  ),
                  child: Text(
                    category.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 2),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (hasHotDeal)
                    AnimatedBuilder(
                      animation: _fireAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_fireAnimationController.value * 0.25),
                          child: Icon(Icons.local_fire_department_rounded,
                              color: Colors.orange.withValues(alpha: 0.8 - (_fireAnimationController.value * 0.4)),
                              size: 75),
                        );
                      },
                    ),
                  if (hasHotDeal)
                    const Positioned(
                      top: -15,
                      child: Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 30),
                    ),

                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: hasHotDeal ? Colors.orange : AppColors.dropRed, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, color: hasHotDeal ? Colors.orange : AppColors.dropRed, size: 28),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: hasHotDeal ? Colors.orange : Colors.green, shape: BoxShape.circle),
                              child: Text("$dealsCount", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                width: 80,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(5)),
                child: Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              CustomPaint(
                size: const Size(12, 6),
                painter: TrianglePainter(color: hasHotDeal ? Colors.orange : AppColors.dropRed),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _showStoreDealsSheet(String storeId, String storeName, double lat, double lng, List<DocumentSnapshot> deals) {
    String distance = _calculateDistance(lat, lng);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront_rounded, color: AppColors.dropRed, size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(storeName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                            const SizedBox(height: 5),
                            if (distance.isNotEmpty)
                              Text(
                                "${"near_you_label".tr()} $distance",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildFollowButton(storeId, storeName),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${deals.length} ${"trending_deals".tr()}", style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                      ElevatedButton.icon(
                        onPressed: () => _openMaps(lat, lng),
                        icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 16),
                        label: Text("go_action".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                itemCount: deals.length,
                itemBuilder: (context, index) {
                  final data = deals[index].data() as Map<String, dynamic>;
                  return _buildDealItem(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(String storeId, String storeName) {
    if (user == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isPremium = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          isPremium = userData?['isPremium'] ?? false;
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('following_stores')
              .doc(storeId)
              .snapshots(),
          builder: (context, followSnapshot) {
            bool isFollowing = followSnapshot.hasData && followSnapshot.data!.exists;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!isPremium) {
                    _showPremiumRequiredDialog();
                  } else {
                    _toggleFollow(storeId, storeName, isFollowing);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? (isDark ? Colors.white12 : Colors.grey[200]) : AppColors.dropRed.withValues(alpha: 0.1),
                  foregroundColor: isFollowing ? (isDark ? Colors.white : Colors.black) : AppColors.dropRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  isFollowing ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  size: 20,
                ),
                label: Text(
                  isFollowing ? "following_label".tr() : "follow_label".tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleFollow(String storeId, String storeName, bool isFollowing) async {
    final followRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('following_stores')
        .doc(storeId);

    if (isFollowing) {
      await followRef.delete();
    } else {
      await followRef.set({
        'storeName': storeName,
        'followedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("premium_feature".tr()),
        content: Text("follow_store_premium_desc".tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("cancel_button".tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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

  Widget _buildDealItem(Map<String, dynamic> data) {
    double discount = double.tryParse(data['discount']?.toString() ?? "0") ?? 0;
    bool isHot = discount > 10;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHot ? Colors.orange.withValues(alpha: isDark ? 0.1 : 0.05) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isHot ? Colors.orange.withValues(alpha: 0.3) : (isDark ? Colors.white10 : Colors.grey.shade100), width: isHot ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: isHot ? Colors.orange.withValues(alpha: 0.2) : AppColors.dropRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Icon(
                isHot ? Icons.local_fire_department_rounded : Icons.shopping_bag_outlined,
                color: isHot ? Colors.orange : AppColors.dropRed,
                size: 20
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['product'] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                Text("${data['discount']}% ${"off_text".tr()}",
                    style: TextStyle(color: isHot ? Colors.orange : AppColors.dropRed, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${data['newPrice']} ${"jod_currency".tr()}",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isHot ? (isDark ? Colors.orange[300] : Colors.orange[900]) : (isDark ? Colors.white : Colors.black))),
              if (data['oldPrice'] != null)
                Text("${data['oldPrice']} ${"jod_currency".tr()}",
                    style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchAndFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  height: 55,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.dropRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: "search_nearby_hint".tr(),
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Icon(Icons.filter_list, color: AppColors.dropRed),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(null, Icons.all_inclusive, "all_filter".tr()),
                _buildFilterChip("cat_food", Icons.restaurant, "cat_food".tr()),
                _buildFilterChip("cat_cafes", Icons.local_cafe, "cat_cafes".tr()),
                _buildFilterChip("cat_fashion", Icons.shopping_bag, "cat_fashion".tr()),
                _buildFilterChip("cat_tech", Icons.devices, "cat_tech".tr()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? category, IconData icon, String label) {
    bool isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12, fontWeight: FontWeight.bold)),
        avatar: Icon(icon, color: isSelected ? Colors.white : AppColors.dropRed, size: 16),
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: AppColors.dropRed,
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => false;
}