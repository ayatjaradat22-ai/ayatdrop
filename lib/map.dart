import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(31.9539, 35.9106); // مركز عمان
  static const Color dropRed = Color(0xFFFF1111);

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
                List<Marker> markers = [];
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    double lat = data['lat'] ?? 31.9539 + (snapshot.data!.docs.indexOf(doc) * 0.002);
                    double lng = data['lng'] ?? 35.9106 + (snapshot.data!.docs.indexOf(doc) * 0.002);
                    
                    markers.add(
                      Marker(
                        point: LatLng(lat, lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _mapController.move(LatLng(lat, lng), 15),
                          child: const Icon(Icons.location_on, color: dropRed, size: 40),
                        ),
                      ),
                    );
                  }
                }

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
          
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 120,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('deals').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var deal = snapshot.data!.docs[index];
                      return _buildStoreCard(deal);
                    },
                  );
                },
              ),
            ),
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
                  const Icon(Icons.search, color: dropRed), // Changed from grey
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

  Widget _buildStoreCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    String productName = data['product']?.toString() ?? "منتج مميز".tr(); // Added .tr()
    String storeName = data['storeName']?.toString() ?? "متجر شريك".tr(); // Added .tr()
    String discount = data['discount']?.toString() ?? "خصم خاص".tr(); // Added .tr()

    return GestureDetector(
      onTap: () {
        double lat = data['lat'] ?? 31.9539;
        double lng = data['lng'] ?? 35.9106;
        _mapController.move(LatLng(lat, lng), 15);
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: dropRed.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                color: dropRed.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              ),
              child: const Icon(Icons.storefront, color: dropRed, size: 40),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      productName, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dropRed) // Changed color
                    ),
                    Text(
                      "$discount " + "off_text".tr(), 
                      style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 5),
                    Text(
                      storeName, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
