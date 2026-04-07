import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class MerchantScannerScreen extends StatefulWidget {
  const MerchantScannerScreen({super.key});

  @override
  State<MerchantScannerScreen> createState() => _MerchantScannerScreenState();
}

class _MerchantScannerScreenState extends State<MerchantScannerScreen> {
  bool _isProcessing = false;
  static const Color dropRed = Color(0xFFFF1111);

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await _processRedemption(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processRedemption(String rawData) async {
    try {
      // توقع البيانات بصيغة: uid:XYZ|deal:123
      final Map<String, String> extractedData = {};
      final parts = rawData.split('|');
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) extractedData[kv[0]] = kv[1];
      }

      if (extractedData.containsKey('uid') && extractedData.containsKey('deal')) {
        // 1. تسجيل العملية في Firestore
        await FirebaseFirestore.instance.collection('redemptions').add({
          'userId': extractedData['uid'],
          'dealId': extractedData['deal'],
          'scannedAt': FieldValue.serverTimestamp(),
          'status': 'verified',
        });

        // 2. عرض رسالة نجاح
        if (mounted) _showStatusDialog(true, "تم تفعيل الخصم بنجاح! 🎉");
      } else {
        throw "QR غير صالح";
      }
    } catch (e) {
      if (mounted) _showStatusDialog(false, "عذراً، هذا الكود غير صالح أو منتهي الصلاحية.");
    } finally {
      // تأخير بسيط قبل السماح بمسح كود آخر
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  void _showStatusDialog(bool isSuccess, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green : dropRed,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dropRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("موافق", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("ماسح Drop للتاجر", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // الكاميرا
          MobileScanner(
            onDetect: _handleBarcode,
            controller: MobileScannerController(
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
          ),
          
          // طبقة التصميم فوق الكاميرا
          _buildScannerOverlay(),

          // حالة المعالجة
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: dropRed),
                    SizedBox(height: 20),
                    Text("جاري التحقق من العرض...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // تعتيم الجوانب باستخدام ColorFiltered بشكل صحيح
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
              ),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
        // إطار المسح
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: dropRed, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                _buildCorner(0, 0, isTop: true, isLeft: true),
                _buildCorner(0, null, isTop: true, isRight: true),
                _buildCorner(null, 0, isBottom: true, isLeft: true),
                _buildCorner(null, null, isBottom: true, isRight: true),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Text(
            "ضع كود QR الخاص بالعميل داخل الإطار",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(double? top, double? left, {bool isTop = false, bool isLeft = false, bool isRight = false, bool isBottom = false}) {
    return Positioned(
      top: top,
      left: left,
      right: isRight ? 0 : null,
      bottom: isBottom ? 0 : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dropRed,
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(25) : Radius.zero,
            topRight: isTop && isRight ? const Radius.circular(25) : Radius.zero,
            bottomLeft: isBottom && isLeft ? const Radius.circular(25) : Radius.zero,
            bottomRight: isBottom && isRight ? const Radius.circular(25) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
