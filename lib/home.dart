import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'map.dart';
import 'ai_guide_screen.dart';
import 'account.dart';
import 'saved_stores.dart';
import 'notifications_screen.dart';
import 'price_comparison_screen.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex;
  const MainWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainWrapper> createState() => MainWrapperState();
}

class MainWrapperState extends State<MainWrapper> {
  late int _selectedIndex;
  static const Color dropRed = Color(0xFFFF1111);

  final List<Widget> _pages = [
    const HomeScreenContent(),
    const MapScreen(),
    const AiGuideScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void setIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: dropRed,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: "home_nav".tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.map_rounded), label: "map_nav".tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.auto_awesome_mosaic_rounded), label: "ai_nav".tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: "account_nav".tr()),
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
  static const Color dropRed = Color(0xFFFF1111);
  static const Color lightGreen = Color(0xFFF1F8E9);
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

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
          _buildExploreAndCompareRow(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: dropRed,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("drop", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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
                name = snapshot.data!.get('name') ?? "saver_default".tr();
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
              prefixIcon: const Icon(Icons.search, color: dropRed),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: dropRed));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category']?.toString();
          final productName = data['product']?.toString().toLowerCase() ?? "";
          final storeName = data['storeName']?.toString().toLowerCase() ?? "";
          final searchText = _searchController.text.toLowerCase();

          bool matchesCategory = true;
          if (_selectedCategory != null) {
            matchesCategory = (category == _selectedCategory);
            if (!matchesCategory) {
              if (_selectedCategory == 'cat_cafes') {
                matchesCategory = productName.contains('قهوة') || productName.contains('coffee') || productName.contains('moca') || storeName.contains('كافيه');
              } else if (_selectedCategory == 'cat_food') {
                matchesCategory = productName.contains('اكل') || productName.contains('وجبة') || productName.contains('burger');
              }
            }
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
            return _buildDealCard(filteredDocs[index]);
          },
        );
      },
    );
  }

  Widget _buildDealCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String? category = data['category']?.toString();
    final productName = data['product'] ?? "Product";
    final storeName = data['storeName'] ?? "Store";
    final discount = data['discount'] ?? "0%";
    final user = FirebaseAuth.instance.currentUser;
    
    String timeLeftStr = "";
    if (data['expiryTime'] != null) {
      DateTime expiry = (data['expiryTime'] as Timestamp).toDate();
      Duration diff = expiry.difference(DateTime.now());
      if (diff.isNegative) {
        timeLeftStr = "expired_text".tr();
      } else if (diff.inHours >= 24) {
        timeLeftStr = "${diff.inDays} ${"days_short".tr()}";
      } else {
        timeLeftStr = "${diff.inHours} ${"hours_short".tr()}";
      }
    }

    IconData categoryIcon = Icons.local_offer_rounded;
    if (category == 'cat_food' || productName.toString().toLowerCase().contains('burger')) {
      categoryIcon = Icons.restaurant_rounded;
    } else if (category == 'cat_cafes' || productName.toString().toLowerCase().contains('moca')) {
      categoryIcon = Icons.local_cafe_rounded;
    } else if (category == 'cat_fashion') {
      categoryIcon = Icons.shopping_bag_rounded;
    } else if (category == 'cat_tech') {
      categoryIcon = Icons.devices_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: dropRed.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(categoryIcon, color: dropRed),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(storeName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                if (timeLeftStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 12, color: dropRed.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(timeLeftStr, style: TextStyle(color: dropRed.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(discount, style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 18)),
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
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: dropRed, size: 20),
                    onPressed: () => _toggleFavorite(doc.id, data, isFav),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
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
    } else {
      await favRef.set({
        ...dealData,
        'savedAt': FieldValue.serverTimestamp(),
      });
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

  Widget _buildExploreAndCompareRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
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
            child: _buildActionButton(
              title: "compare_before_go".tr(),
              icon: Icons.shopping_cart_checkout_rounded,
              color: Colors.orange.shade700,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PriceComparisonScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(title, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
            shadowColor: isSelected ? dropRed : Colors.black26,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: isSelected ? dropRed : Colors.white,
              child: Icon(icon, color: isSelected ? Colors.white : dropRed, size: 28),
            ),
          ),
          const SizedBox(height: 10),
          Text(categoryKey.tr(), style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? dropRed : Colors.black)),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.account_balance_wallet, color: Colors.white)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("total_saved_title".tr(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const Text("0.000 JOD", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }
}
