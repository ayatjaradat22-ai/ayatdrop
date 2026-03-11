import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'map.dart';
import 'ai_guide_screen.dart';
import 'account.dart';

class MainWrapper extends StatefulWidget {
  final int initialIndex;
  const MainWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildExploreButton(),
          const SizedBox(height: 25),
          _buildSectionTitle(_selectedCategory == null ? "popular_categories".tr() : "cat_filtered_title".tr(args: [_selectedCategory!.tr()])),
          const SizedBox(height: 15),
          _buildCategoriesRow(),
          const SizedBox(height: 30),
          if (_selectedCategory == null) ...[
            _buildSectionTitle("savings_summary".tr()),
            const SizedBox(height: 10),
            _buildSavingsCard(),
            const SizedBox(height: 30),
          ],
          _buildSectionTitle("trending_deals".tr()),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("drop", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
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
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "search_hint".tr(),
              prefixIcon: const Icon(Icons.auto_awesome, color: Colors.purple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsList() {
    // جلب كل العروض ثم الفلترة في الـ UI لضمان ظهور العروض القديمة التي لا تحتوي على حقل فئة
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('deals').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: dropRed));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // منطق الفلترة الذكي
        final filteredDocs = snapshot.data!.docs.where((doc) {
          if (_selectedCategory == null) return true;
          
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category']?.toString();
          final productName = data['product']?.toString().toLowerCase() ?? "";
          final storeName = data['storeName']?.toString().toLowerCase() ?? "";

          // 1. فحص حقل الفئة المباشر
          if (category == _selectedCategory) return true;

          // 2. استنتاج ذكي للعروض القديمة بناءً على كلمات دلالية
          if (_selectedCategory == 'cat_cafes') {
            return productName.contains('قهوة') || productName.contains('coffee') || 
                   productName.contains('moca') || storeName.contains('كافيه') || storeName.contains('ايات');
          }
          if (_selectedCategory == 'cat_food') {
            return productName.contains('اكل') || productName.contains('وجبة') || productName.contains('burger');
          }

          return false;
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
    final productName = data['product']?.toString().toLowerCase() ?? "";
    final storeName = data['storeName']?.toString().toLowerCase() ?? "";

    // تحديد الأيقونة تلقائياً للعروض القديمة
    IconData categoryIcon = Icons.local_offer_rounded;
    if (category == 'cat_food' || productName.contains('burger')) {
      categoryIcon = Icons.restaurant_rounded;
    } else if (category == 'cat_cafes' || productName.contains('moca') || storeName.contains('كافيه') || storeName.contains('ايات')) {
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
                Text(data['product'] ?? "Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(data['storeName'] ?? "Store", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(data['discount'] ?? "0%", style: const TextStyle(color: dropRed, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey.shade200),
        Text("no_deals".tr(), style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildExploreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            const Icon(Icons.explore, color: Colors.white),
            const SizedBox(width: 15),
            Text("explore_nearby".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
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
