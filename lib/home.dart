import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'map.dart';
import 'ai_guide_screen.dart';
import 'account.dart';
import 'saved_stores.dart';
import 'notifications_screen.dart';
import 'price_comparison_screen.dart';
import 'exclusive_deals_screen.dart';
import 'alert_me_screen.dart';
import 'ten_jd_challenge_screen.dart';
import 'smart_shopping_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'premium.dart';
import 'app_colors.dart';
import 'store_profile_screen.dart';
import 'edit_profile.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex;
  const MainWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainWrapper> createState() => MainWrapperState();
}

class MainWrapperState extends State<MainWrapper> {
  late int _selectedIndex;
  LatLng? _mapTargetLocation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void setIndex(int index, {LatLng? location}) {
    setState(() {
      _selectedIndex = index;
      if (location != null) {
        _mapTargetLocation = location;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreenContent(),
      MapScreen(targetLocation: _mapTargetLocation),
      const AiGuideScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.getPrimaryColor(context),
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index != 1) _mapTargetLocation = null;
          });
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: "home_nav".tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.map_rounded), label: "map_nav".tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.auto_awesome_mosaic_rounded), label: "ai_nav".tr()),
          BottomNavigationBarItem(
            icon: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                final uid = authSnapshot.data?.uid;
                if (uid == null) return const Icon(Icons.person_rounded);
                
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                  builder: (context, snapshot) {
                    String? photoUrl;
                    ImageProvider? imageProvider;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      photoUrl = data?['photoUrl'];
                      
                      if (photoUrl != null && photoUrl.isNotEmpty) {
                        if (photoUrl.startsWith('http')) {
                          imageProvider = NetworkImage(photoUrl);
                        } else {
                          try {
                            imageProvider = MemoryImage(base64Decode(photoUrl));
                          } catch (e) {
                            imageProvider = null;
                          }
                        }
                      }
                    }

                    return Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedIndex == 3 ? AppColors.getPrimaryColor(context) : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        image: imageProvider != null 
                            ? DecorationImage(image: imageProvider, fit: BoxFit.cover) 
                            : null,
                      ),
                      child: imageProvider == null
                          ? Icon(Icons.person_rounded, size: 20, color: _selectedIndex == 3 ? AppColors.getPrimaryColor(context) : Colors.grey.shade400) 
                          : null,
                    );
                  }
                );
              }
            ),
            label: "account_nav".tr(),
          ),
        ],
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final LatLng _userLocation = const LatLng(31.9539, 35.9106);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildActionButtonsGrid(),
          const SizedBox(height: 25),
          _buildSectionTitle(_selectedCategory == null ? "popular_categories".tr() : "cat_filtered_title".tr(args: [_selectedCategory!.tr()])),
          const SizedBox(height: 15),
          _buildCategoriesRow(),
          const SizedBox(height: 30),
          if (_selectedCategory == null && _searchController.text.isEmpty) ...[
            _buildSectionTitle("savings_summary".tr()),
            const SizedBox(height: 10),
            _buildSavingsCard(),
            const SizedBox(height: 30),
          ],
          _buildSectionTitle(_searchController.text.isEmpty ? "trending_deals".tr() : "search_results".tr()),
          const SizedBox(height: 20),
          _buildDealsList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    User? user = FirebaseAuth.instance.currentUser;
    final primaryColor = AppColors.getPrimaryColor(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("app_name".tr(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedStoresScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              String name = "saver_default".tr();
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                name = data?['name'] ?? data?['storeName'] ?? "saver_default".tr();
              }
              return Text("hello_user".tr(args: [name]), style: const TextStyle(color: Colors.white70, fontSize: 16));
            },
          ),
          Text("header_tagline".tr(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 25),
          
          GestureDetector(
            onTap: () {
               final wrapper = context.findAncestorStateOfType<MainWrapperState>();
               if (wrapper != null) {
                 wrapper.setIndex(2); 
               }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                  const SizedBox(width: 10),
                  Text("search_hint".tr(), style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              hintText: "deal_search_hint".tr(),
              prefixIcon: Icon(Icons.search, color: primaryColor),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => setState(() => _searchController.clear())) 
                : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsList() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isPremium = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          isPremium = userData?['isPremium'] ?? false;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('deals').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("error_occurred".tr(), textAlign: TextAlign.center),
              ));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppColors.getPrimaryColor(context)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final now = DateTime.now();
            final filteredDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
              
              if (data['expiryTime'] != null) {
                DateTime expiry = (data['expiryTime'] as Timestamp).toDate();
                if (expiry.isBefore(now)) return false; 
              }

              if (!isPremium) {
                if (now.isBefore(createdAt)) return false;
                final difference = now.difference(createdAt);
                if (difference.inHours < 1) return false;
              }

              final category = data['category']?.toString();
              final productName = (data['product'] ?? "").toString().toLowerCase();
              final storeName = (data['storeName'] ?? "").toString().toLowerCase();
              final searchText = _searchController.text.toLowerCase();

              bool matchesCategory = true;
              if (_selectedCategory != null) {
                matchesCategory = (category == _selectedCategory);
              }

              bool matchesSearch = true;
              if (searchText.isNotEmpty) {
                matchesSearch = productName.contains(searchText) || storeName.contains(searchText);
              }

              return matchesCategory && matchesSearch;
            }).toList();

            if (filteredDocs.isEmpty) return _buildEmptyState();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                return _buildDealCard(filteredDocs[index], isPremium);
              },
            );
          },
        );
      }
    );
  }

  Widget _buildDealCard(DocumentSnapshot doc, bool isPremium) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final productName = data['product'] ?? "Product";
    final storeName = data['storeName'] ?? "Store";
    final discount = data['discount']?.toString() ?? "0";
    final oldPrice = data['oldPrice']?.toString() ?? "";
    final newPrice = data['newPrice']?.toString() ?? "";
    final user = FirebaseAuth.instance.currentUser;
    final isDark = AppColors.isDarkMode(context);
    final primaryColor = AppColors.getPrimaryColor(context);
    
    double discountVal = double.tryParse(discount) ?? 0;
    bool isHot = discountVal > 10;

    return GestureDetector(
      onTap: () => _showDealDetails(doc),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isHot ? AppColors.getHotDealBackground(context) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isHot ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => StoreProfileScreen(storeId: data['storeId'] ?? doc.id, storeName: storeName)));
                    },
                    child: Text(storeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isHot ? Colors.orange.withOpacity(0.2) : primaryColor.withOpacity(0.1), 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getCategoryIcon(data['category'], productName), color: primaryColor, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(productName, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          ),
                          if (isHot) ...[
                            const SizedBox(width: 5),
                            const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 16),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (newPrice.isNotEmpty) ...[
                      Text("$newPrice ${"jod_currency".tr()}", 
                        style: TextStyle(color: isHot ? (isDark ? Colors.orange[300] : Colors.orange[900]) : primaryColor, fontWeight: FontWeight.w900, fontSize: 18)),
                      if (oldPrice.isNotEmpty)
                        Text("$oldPrice ${"jod_currency".tr()}", 
                          style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontSize: 12)),
                    ] else
                      Text("$discount% ${"off_text".tr()}", 
                        style: TextStyle(color: isHot ? Colors.orange : primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPremium)
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.blue, size: 18),
                            onPressed: () {
                              Share.share("share_msg".tr(args: [productName, storeName, newPrice]));
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .collection('favorites')
                              .doc(doc.id)
                              .snapshots(),
                          builder: (context, favSnapshot) {
                            bool isFav = favSnapshot.hasData && favSnapshot.data!.exists;
                            return IconButton(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 18),
                              onPressed: () => _toggleFavorite(doc.id, data, isFav),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(5),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDealDetails(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final double lat = (data['lat'] as num?)?.toDouble() ?? 31.9539;
    final double lng = (data['lng'] as num?)?.toDouble() ?? 35.9106;
    final isDark = AppColors.isDarkMode(context);
    final primaryColor = AppColors.getPrimaryColor(context);
    final wrapper = context.findAncestorStateOfType<MainWrapperState>();

    FirebaseFirestore.instance.collection('deals').doc(doc.id).update({'clicks': FieldValue.increment(1)});

    double distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      _userLocation,
      LatLng(lat, lng),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.getSubtitleColor(context).withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(sheetContext);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => StoreProfileScreen(storeId: data['storeId'] ?? doc.id, storeName: data['storeName'] ?? "Store")));
                          },
                          child: Text(data['storeName'] ?? "Store", 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor))),
                        Text(data['product'] ?? "Product", 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(fontSize: 17, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "near_you".tr(args: [distanceKm.toStringAsFixed(1)]),
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: AppColors.getSecondaryBackground(context), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    Expanded(child: Text("is_deal_available".tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
                    IconButton(onPressed: () => _voteDeal(doc.id, true), icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.green, size: 20)),
                    IconButton(onPressed: () => _voteDeal(doc.id, false), icon: const Icon(Icons.thumb_down_alt_outlined, color: Colors.red, size: 20)),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),
              const SizedBox(height: 20),
              Text("current_deal".tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (data['newPrice'] != null)
                    Text("${data['newPrice']} ${"jod_currency".tr()}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryColor)),
                  const SizedBox(width: 12),
                  if (data['oldPrice'] != null)
                    Text("${data['oldPrice']} ${"jod_currency".tr()}", style: const TextStyle(fontSize: 18, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                ],
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.getSecondaryBackground(context), 
                  borderRadius: BorderRadius.circular(18), 
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100)
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data['location'] ?? "location_hint".tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildLargeFollowButton(data['storeId'] ?? doc.id, data['storeName'] ?? "Store"),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _showQRConfirmation(doc.id, data);
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                  label: Text("confirm_with_qr".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _markAsBought(doc.id, data);
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text("mark_as_bought".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => _openMaps(lat, lng),
                        icon: Icon(Icons.directions_rounded, color: primaryColor, size: 20),
                        label: Text("go_action".tr(), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext); 
                          if (wrapper != null) {
                            wrapper.setIndex(1, location: LatLng(lat, lng)); 
                          }
                        },
                        icon: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                        label: Text("show_on_map".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRConfirmation(String dealId, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime expiry = (data['expiryTime'] as Timestamp).toDate();
    if (expiry.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("deal_expired_error".tr())));
      return;
    }

    double oldPrice = double.tryParse(data['oldPrice']?.toString() ?? "0") ?? 0;
    double newPrice = double.tryParse(data['newPrice']?.toString() ?? "0") ?? 0;
    double savedAmount = oldPrice - newPrice;

    Map<String, dynamic> qrData = {
      'u': user.uid,
      'd': dealId,
      's': savedAmount,
      't': DateTime.now().millisecondsSinceEpoch,
    };

    String qrString = jsonEncode(qrData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("confirm_discount_title".tr(), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("qr_scan_instruction".tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: qrString,
                version: QrVersions.auto,
                size: 200.0,
                foregroundColor: AppColors.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 20),
            Text("${savedAmount.toStringAsFixed(3)} JOD", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            Text("expected_savings".tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("close_button".tr())),
        ],
      ),
    );
  }

  void _voteDeal(String dealId, bool isUpvote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final voteRef = FirebaseFirestore.instance
        .collection('deals')
        .doc(dealId)
        .collection('user_votes')
        .doc(user.uid);

    final voteDoc = await voteRef.get();
    if (voteDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("already_voted".tr())));
      return;
    }

    await voteRef.set({'vote': isUpvote, 'timestamp': FieldValue.serverTimestamp()});
    FirebaseFirestore.instance.collection('deals').doc(dealId).update({
      isUpvote ? 'upvotes' : 'downvotes': FieldValue.increment(1)
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isUpvote ? "thanks_for_rating".tr() : "we_will_verify".tr()), backgroundColor: isUpvote ? Colors.green : Colors.orange));
  }

  Future<void> _markAsBought(String dealId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime expiry = (data['expiryTime'] as Timestamp).toDate();
    if (expiry.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("expired_deal_cant_count".tr())));
      return;
    }

    final boughtRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bought_deals')
        .doc(dealId);

    final boughtDoc = await boughtRef.get();
    if (boughtDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("already_counted_savings".tr())));
      return;
    }

    double oldPrice = double.tryParse(data['oldPrice']?.toString() ?? "0") ?? 0;
    double newPrice = double.tryParse(data['newPrice']?.toString() ?? "0") ?? 0;
    double savedAmount = oldPrice - newPrice;
    if (savedAmount <= 0) return;

    await boughtRef.set({'boughtAt': FieldValue.serverTimestamp(), 'saved': savedAmount, 'confirmedByStore': false});

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        double currentTotal = (userData?['totalSaved'] ?? 0).toDouble();
        transaction.update(userRef, {'totalSaved': currentTotal + savedAmount});
      }
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("saved_amount_msg".tr(args: [savedAmount.toStringAsFixed(3)])),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleFavorite(String dealId, Map<String, dynamic> dealData, bool currentlyFav) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(dealId);

    if (currentlyFav) {
      await favRef.delete();
      FirebaseFirestore.instance.collection('deals').doc(dealId).update({'favoritesCount': FieldValue.increment(-1)});
    } else {
      await favRef.set({
        ...dealData,
        'savedAt': FieldValue.serverTimestamp(),
      });
      FirebaseFirestore.instance.collection('deals').doc(dealId).update({'favoritesCount': FieldValue.increment(1)});
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchController.text.isEmpty ? "no_deals".tr() : "no_search_results".tr(), 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildNeumorphicActionButton(
                  title: "drop_exclusive".tr(),
                  icon: Icons.confirmation_num_rounded,
                  color: Colors.deepPurple.shade600,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExclusiveDealsScreen())),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildNeumorphicActionButton(
                  title: "smart_shopping_list".tr(),
                  icon: Icons.playlist_add_check_rounded,
                  color: Colors.blueGrey.shade600,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartShoppingListScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildNeumorphicActionButton(
                  title: "compare_before_go".tr(),
                  icon: Icons.shopping_cart_checkout_rounded,
                  color: Colors.orange.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PriceComparisonScreen())),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildNeumorphicActionButton(
                  title: "ten_jd_challenge".tr(),
                  icon: Icons.monetization_on_rounded,
                  color: Colors.green.shade600,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TenJdChallengeScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildNeumorphicActionButton(
                  title: "explore_nearby".tr(),
                  icon: Icons.explore,
                  color: const Color(0xFF1E88E5),
                  onTap: () {
                    final wrapper = context.findAncestorStateOfType<MainWrapperState>();
                    if (wrapper != null) wrapper.setIndex(1);
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildNeumorphicActionButton(
                  title: "alert_me_title".tr(),
                  icon: Icons.notifications_active_rounded,
                  color: Colors.teal.shade600,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertMeScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicActionButton({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.getNeumorphicShadow(context),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title, 
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13), 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCategoryItem(Icons.restaurant, "cat_food"),
        _buildCategoryItem(Icons.shopping_bag, "cat_fashion"),
        _buildCategoryItem(Icons.local_cafe, "cat_cafes"),
        _buildCategoryItem(Icons.devices, "cat_tech"),
      ],
    );
  }

  Widget _buildCategoryItem(IconData icon, String categoryKey) {
    bool isSelected = _selectedCategory == categoryKey;
    final primaryColor = AppColors.getPrimaryColor(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCategory == categoryKey) {
            _selectedCategory = null; 
          } else {
            _selectedCategory = categoryKey;
          }
        });
      },
      child: Column(
        children: [
          Material(
            elevation: isSelected ? 10 : 5,
            shape: const CircleBorder(),
            shadowColor: isSelected ? primaryColor : Colors.black26,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: isSelected ? primaryColor : Theme.of(context).cardColor,
              child: Icon(icon, color: isSelected ? Colors.white : primaryColor, size: 28),
            ),
          ),
          const SizedBox(height: 10),
          Text(categoryKey.tr(), style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? primaryColor : null)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildSavingsCard() {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = AppColors.isDarkMode(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        double totalSaved = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          totalSaved = (data?['totalSaved'] ?? 0).toDouble();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.getSavingsCardBackground(context), 
            borderRadius: BorderRadius.circular(25), 
            border: Border.all(color: Colors.green.withOpacity(0.1))
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.account_balance_wallet, color: Colors.white)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("total_saved_title".tr(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text("${totalSaved.toStringAsFixed(3)} ${"jod_currency".tr()}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _resetSavings(user?.uid),
                icon: const Icon(Icons.refresh_rounded, color: Colors.green),
                tooltip: "reset_savings_tooltip".tr(),
              ),
            ],
          ),
        );
      }
    );
  }

  void _resetSavings(String? uid) async {
    if (uid == null) return;

    AppColors.showThemedDialog(
      context: context,
      title: "reset_savings_title".tr(),
      description: "reset_savings_confirmation".tr(),
      primaryButtonText: "reset_action".tr(),
      primaryButtonColor: Colors.red,
      icon: Icons.refresh_rounded,
      onPrimaryPressed: () async {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'totalSaved': 0});
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("savings_reset_success".tr()), backgroundColor: Colors.green));
        }
      },
    );
  }

  Widget _buildLargeFollowButton(String storeId, String storeName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    final primaryColor = AppColors.getPrimaryColor(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following_stores').doc(storeId).snapshots(),
      builder: (context, snapshot) {
        bool isFollowing = snapshot.hasData && snapshot.data!.exists;
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following_stores').doc(storeId);
              if (isFollowing) {
                ref.delete();
              } else {
                ref.set({'storeName': storeName, 'followedAt': FieldValue.serverTimestamp()});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[200] : primaryColor.withOpacity(0.1),
              foregroundColor: isFollowing ? Colors.black : primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            icon: Icon(isFollowing ? Icons.check_circle : Icons.add_circle_outline, size: 20),
            label: Text(isFollowing ? "following_label".tr() : "follow_label".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String? category, String productName) {
    if (category == 'cat_food' || productName.toLowerCase().contains('burger')) return Icons.restaurant_rounded;
    if (category == 'cat_cafes') return Icons.local_cafe_rounded;
    if (category == 'cat_fashion') return Icons.shopping_bag_rounded;
    return Icons.local_offer_rounded;
  }

  Future<void> _openMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}
