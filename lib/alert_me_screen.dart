import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class AlertMeScreen extends StatefulWidget {
  const AlertMeScreen({super.key});

  @override
  State<AlertMeScreen> createState() => _AlertMeScreenState();
}

class _AlertMeScreenState extends State<AlertMeScreen> {
  final TextEditingController _brandController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  static const Color dropRed = Color(0xFFFF1111);

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _followBrand() async {
    if (_brandController.text.trim().isEmpty || user == null) return;

    final brandName = _brandController.text.trim();
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('followed_brands')
        .add({
      'name': brandName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _brandController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("brand_added_success".tr(args: [brandName])), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _unfollowBrand(String id) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('followed_brands')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "alert_me_title".tr(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Colors.blue, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "brand_tracking_desc".tr(),
                      style: TextStyle(color: isDark ? Colors.blue[200] : Colors.blue.shade900, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            
            Text("add_brand_button".tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _brandController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "track_brand_hint".tr(),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _followBrand,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: dropRed, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            Text("followed_brands".tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 15),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('followed_brands')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text("no_tracked_brands".tr(), style: const TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['name'] ?? "", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                          IconButton(
                            icon: const Icon(Icons.notifications_off_outlined, color: Colors.grey, size: 20),
                            onPressed: () => _unfollowBrand(id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
