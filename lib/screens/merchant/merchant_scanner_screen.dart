import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class MerchantScannerScreen extends StatefulWidget {
  const MerchantScannerScreen({super.key});

  @override
  State<MerchantScannerScreen> createState() => _MerchantScannerScreenState();
}

class _MerchantScannerScreenState extends State<MerchantScannerScreen> {
  bool _isProcessing = false;

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
      // تفكيك البيانات: uid:xyz|deal:123|ts:456
      final parts = rawData.split('|');
      final Map<String, String> data = {};
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) data[kv[0]] = kv[1];
      }

      if (data.containsKey('uid') && data.containsKey('deal')) {
        // تخزين العملية في Firestore
        await FirebaseFirestore.instance.collection('redemptions').add({
          'userId': data['uid'],
          'dealId': data['deal'],
          'scannedAt': FieldValue.serverTimestamp(),
          'merchantId': 'current_merchant_id', // يجب ربطه بـ Auth المحل لاحقاً
        });

        if (mounted) {
          _showResultDialog(true, "discount_applied_success".tr());
        }
      } else {
        throw "Invalid QR Code";
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(false, "invalid_qr_error".tr());
      }
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  void _showResultDialog(bool success, String message) {
    AppColors.showThemedDialog(
      context: context,
      title: success ? "success".tr() : "error".tr(),
      description: message,
      icon: success ? Icons.check_circle : Icons.error,
      primaryButtonText: "ok".tr(),
      onPrimaryPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("merchant_scanner".tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          // إطار المسح الجمالي
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dropRed, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
