import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

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
    final boughtRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bought_deals')
        .doc(dealId);

    final boughtDoc = await boughtRef.get();
    if (boughtDoc.exists) {
      _showResultDialog("تنبيه", "هذا الخصم تم تأكيده مسبقاً لهذا المستخدم", Colors.orange);
      return;
    }

    // تحديث توفير المستخدم وسجل المشتريات
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        double currentTotal = (userData?['totalSaved'] ?? 0).toDouble();
        transaction.update(userRef, {'totalSaved': currentTotal + savedAmount});
      }
      
      transaction.set(boughtRef, {
        'boughtAt': FieldValue.serverTimestamp(),
        'saved': savedAmount,
        'confirmedByStore': true
      });
    });

    _showResultDialog("تم التأكيد", "تم تسجيل توفير بمبلغ ${savedAmount.toStringAsFixed(3)} JOD للمستخدم بنجاح", Colors.green);
  }

  void _showResultDialog(String title, String message, Color color) {
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
        title: const Text("ماسح التأكيد"),
        backgroundColor: AppColors.dropRed,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // إطار المسح
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
              child: Text(
                "وجه الكاميرا نحو كود العميل",
                style: TextStyle(color: Colors.white, backgroundColor: Colors.black45, fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}
