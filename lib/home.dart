import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'map.dart';
import 'ai_guide_screen.dart';
import 'account.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  static const Color dropRed = Color(0xFFFF1111);

  final List<Widget> _pages = [
    const HomeScreenContent(),
    const MapScreen(),
    const AiGuideScreen(),
    const AccountScreen(),
  ];

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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_mosaic_rounded), label: "AI Guide"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Account"),
        ],
      ),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  static const Color dropRed = Color(0xFFFF1111);
  static const Color lightGreen = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildExploreButton(),
          const SizedBox(height: 25),
          _buildSectionTitle("Popular Categories"),
          const SizedBox(height: 15),
          _buildCategoriesRow(),
          const SizedBox(height: 30),
          _buildSectionTitle("Savings Summary"),
          const SizedBox(height: 10),
          _buildSavingsCard(),
          const SizedBox(height: 30),
          _buildSectionTitle("Trending Deals"),
          const SizedBox(height: 20),
          _buildDealsList(), // هنا سيتم عرض العروض من Firestore
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
          // جلب اسم المستخدم من Firestore
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              String name = "Saver";
              if (snapshot.hasData && snapshot.data!.exists) {
                name = snapshot.data!.get('name') ?? "Saver";
              }
              return Text("Hello, $name! 👋", style: const TextStyle(color: Colors.white70, fontSize: 16));
            },
          ),
          const Text("Find deals within your budget", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 25),
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "I have 20 JOD.. where should I go?",
              prefixIcon: const Icon(Icons.auto_awesome, color: Colors.purple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت عرض العروض من Firestore
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

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var deal = snapshot.data!.docs[index];
            return _buildDealCard(deal);
          },
        );
      },
    );
  }

  Widget _buildDealCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
            child: const Icon(Icons.local_offer, color: dropRed),
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
        const Text("No active deals today", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  // بقية الويدجت (Explore, Categories, Savings) تبقى كما هي
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
        child: const Row(
          children: [
            Icon(Icons.explore, color: Colors.white),
            SizedBox(width: 15),
            Text("Explore Nearby Deals", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CategoryIconItem(icon: Icons.restaurant, label: "Food"),
        CategoryIconItem(icon: Icons.shopping_bag, label: "Fashion"),
        CategoryIconItem(icon: Icons.local_cafe, label: "Cafes"),
        CategoryIconItem(icon: Icons.devices, label: "Tech"),
      ],
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
      child: const Row(
        children: [
          CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.account_balance_wallet, color: Colors.white)),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Money Saved", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text("0.000 JOD", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }
}

class CategoryIconItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const CategoryIconItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: 5,
          shape: const CircleBorder(),
          shadowColor: Colors.black26,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(icon, color: const Color(0xFFFF1111), size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
