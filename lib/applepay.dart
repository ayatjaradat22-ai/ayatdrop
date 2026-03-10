import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplePayScreen extends StatelessWidget {
  const ApplePayScreen({super.key});

  // ألوان الهوية البصرية لـ Drop و Apple
  static const Color premiumBlack = Color(0xFF121212);
  static const Color appleGrey = Color(0xFFF2F2F7);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Wallet",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // 1. البطاقة السوداء الفاخرة
                  _buildAppleCard(screenWidth),

                  const SizedBox(height: 35),

                  // 2. الرصيد الإجمالي بتصميم عصري
                  _buildBalanceSection(currentUser, screenWidth),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. قائمة المعاملات
            _buildTransactionList(currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleCard(double width) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2E), Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // شعار آبل خفيف في الخلفية
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.apple, size: 150, color: Colors.white.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.apple, color: Colors.white, size: 32),
                    Text(" Card", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Lana Abdullah".toUpperCase(),
                        style: const TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w300)),
                    const SizedBox(height: 5),
                    const Text("•••• 8824", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(User? user, double width) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String balance = "0.00";
        if (snapshot.hasData && snapshot.data!.exists) {
          balance = snapshot.data!['wallet_balance']?.toString() ?? "0.00";
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appleGrey,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Balance", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("\$$balance", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  elevation: 0,
                ),
                child: const Text("Pay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(User? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Latest Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text("See All", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('transactions')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) => const Divider(height: 30, color: appleGrey),
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return _buildTransactionItem(
                    doc['status'] ?? "Transaction",
                    doc['amount']?.toString() ?? "0.00",
                    doc['type'] ?? "expense", // نفترض وجود نوع لتغيير الأيقونة
                  );
                },
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String amount, String type) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: appleGrey, borderRadius: BorderRadius.circular(15)),
          child: Icon(
            type == "income" ? Icons.add_rounded : Icons.shopping_bag_rounded,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Text("Today", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Text(
          "${type == "income" ? "+" : "-"}\$$amount",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: type == "income" ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}