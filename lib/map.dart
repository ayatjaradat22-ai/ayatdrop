import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _initialCenter = const LatLng(31.9539, 35.9106); 
  static const Color dropRed = Color(0xFFFF1111);
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _userPosition = position;
          _initialCenter = LatLng(position.latitude, position.longitude);
        });
        // تحريك الخريطة فوراً لموقع المستخدم الحالي
        _mapController.move(_initialCenter, 14.0);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final Uri geoUrl = Uri.parse("geo:$lat,$lng?q=$lat,$lng");
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("error_occurred".tr() + ": $e"), backgroundColor: Colors.red),
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
    return distanceInKm.toStringAsFixed(1) + " " + "km_unit".tr();
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                Map<String, List<DocumentSnapshot>> storeDeals = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String storeId = data['storeId'] ?? doc.id;
                  if (!storeDeals.containsKey(storeId)) {
                    storeDeals[storeId] = [];
                  }
                  storeDeals[storeId]!.add(doc);
                }

                List<Marker> markers = [];
                
                // إضافة ماركر لموقع المستخدم الحالي (نقطة زرقاء)
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
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
                        ),
                      ),
                    ),
                  );
                }

                storeDeals.forEach((storeId, deals) {
                  final firstDealData = deals.first.data() as Map<String, dynamic>;
                  double lat = (firstDealData['lat'] as num?)?.toDouble() ?? 31.9539;
                  double lng = (firstDealData['lng'] as num?)?.toDouble() ?? 35.9106;

                  markers.add(
                    Marker(
                      point: LatLng(lat, lng),
                      width: 100,
                      height: 120,
                      rotate: true, 
                      alignment: Alignment.topCenter, 
                      child: _buildStoreMarker(firstDealData, deals),
                    ),
                  );
                });

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
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
          
          _buildTopSearch(),

          // زر إعادة التركيز على موقعي الحالي
          Positioned(
            right: 20,
            bottom: 150,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: dropRed),
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

  Widget _buildStoreMarker(Map<String, dynamic> storeData, List<DocumentSnapshot> deals) {
    String storeName = storeData['storeName'] ?? "Store";
    String? category = storeData['category']?.toString();
    double lat = (storeData['lat'] as num?)?.toDouble() ?? 31.9539;
    double lng = (storeData['lng'] as num?)?.toDouble() ?? 35.9106;
    int dealsCount = deals.length;

    return GestureDetector(
      onTap: () => _showStoreDealsSheet(storeName, lat, lng, deals),
      child: Container(
        height: 120, 
        alignment: Alignment.bottomCenter, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: dropRed,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
                child: Text(
                  category.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 2),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dropRed, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.storefront_rounded, color: dropRed, size: 28),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: Text("$dealsCount", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(5)),
              child: Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            CustomPaint(
              size: const Size(12, 8),
              painter: TrianglePainter(color: dropRed),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreDealsSheet(String storeName, double lat, double lng, List<DocumentSnapshot> deals) {
    String distance = _calculateDistance(lat, lng);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: dropRed, size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(storeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            if (distance.isNotEmpty)
                              Text(
                                "${"near_you_label".tr()} $distance",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openMaps(lat, lng),
                        icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 18),
                        label: Text("go_action".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: ui.TextDirection.ltr == Directionality.of(context) ? Alignment.centerLeft : Alignment.centerRight,
                    child: Text("${deals.length} ${"trending_deals".tr()}", style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
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

  Widget _buildDealItem(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: dropRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shopping_bag_outlined, color: dropRed, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['product'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${data['discount']}% ${"off_text".tr()}", style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${data['newPrice']} ${"jod_currency".tr()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              if (data['oldPrice'] != null)
                Text("${data['oldPrice']} ${"jod_currency".tr()}", 
                  style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearch() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: dropRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "search_nearby_hint".tr(),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.filter_list, color: dropRed),
                ],
              ),
            ),
          ),
        ),
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