import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();
  final User? currentStore = FirebaseAuth.instance.currentUser;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || currentStore == null) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      final Map<String, dynamic> data = jsonDecode(code);
      final String userId = data['u'];
      final String dealId = data['d'];
      final double savedAmount = (data['s'] as num).toDouble();

      await _confirmDiscount(userId, dealId, savedAmount);
    } catch (e) {
      _showResultDialog("خطأ", "الكود غير صالح أو تالف", Colors.red);
    }
  }

  Future<void> _confirmDiscount(String userId, String dealId, double savedAmount) async {
    try {
      // 1. التحقق من أن العرض يخص هذا المتجر فعلياً
      final dealDoc = await FirebaseFirestore.instance.collection('deals').doc(dealId).get();
      
      if (!dealDoc.exists) {
        _showResultDialog("خطأ", "هذا العرض لم يعد موجوداً في النظام", Colors.red);
        return;
      }

      final dealData = dealDoc.data() as Map<String, dynamic>;
      if (dealData['storeId'] != currentStore!.uid) {
        _showResultDialog("غير مصرح", "لا يمكنك تأكيد عرض لا ينتمي لمتجرك", Colors.red);
        return;
      }

      // 2. التحقق مما إذا كان العرض قد انتهى
      if (dealData['expiryTime'] != null) {
        DateTime expiry = (dealData['expiryTime'] as Timestamp).toDate();
        if (expiry.isBefore(DateTime.now())) {
          _showResultDialog("تنبيه", "هذا العرض قد انتهت صلاحيته", Colors.orange);
          return;
        }
      }

      // 3. التحقق مما إذا كان قد تم تأكيده مسبقاً
      final boughtRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bought_deals')
          .doc(dealId);

      final boughtDoc = await boughtRef.get();
      if (boughtDoc.exists && (boughtDoc.data()?['confirmedByStore'] ?? false)) {
        _showResultDialog("تنبيه", "هذا الخصم تم تأكيده مسبقاً لهذا المستخدم", Colors.orange);
        return;
      }

      // 4. تنفيذ العملية في Transaction لضمان الدقة
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        
        if (userSnapshot.exists) {
          final userData = userSnapshot.data() as Map<String, dynamic>?;
          double currentTotal = (userData?['totalSaved'] ?? 0).toDouble();
          transaction.update(userRef, {'totalSaved': currentTotal + savedAmount});
        }
        
        transaction.set(boughtRef, {
          'boughtAt': FieldValue.serverTimestamp(),
          'saved': savedAmount,
          'confirmedByStore': true,
          'storeId': currentStore!.uid,
          'dealProduct': dealData['product']
        }, SetOptions(merge: true));
      });

      _showResultDialog("تم التأكيد بنجاح", "تم تسجيل توفير بمبلغ ${savedAmount.toStringAsFixed(3)} JOD للمستخدم", Colors.green);
    } catch (e) {
      _showResultDialog("خطأ تقني", "حدث خطأ أثناء معالجة الطلب: $e", Colors.red);
    }
  }

  void _showResultDialog(String title, String message, Color color) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isProcessing = false);
              },
              child: const Text("موافق", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ماسح التأكيد للمتاجر"),
        backgroundColor: AppColors.dropRed,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.dropRed)),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                child: const Text(
                  "وجه الكاميرا نحو كود العميل لتأكيد الخصم",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
