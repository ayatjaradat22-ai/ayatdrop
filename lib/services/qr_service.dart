import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class QRService {
  static void showRedemptionQR(BuildContext context, Map<String, dynamic> dealData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // البيانات المشفرة داخل الـ QR
    final String qrData = "uid:${user.uid}|deal:${dealData['id']}|ts:${DateTime.now().millisecondsSinceEpoch}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getScaffoldBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "scan_to_save".tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              dealData['product'] ?? "Deal",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getPrimaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: AppColors.getCommonShadow(context),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220.0,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: AppColors.dropRed,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: AppColors.premiumBlack,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "present_to_merchant".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getSecondaryTextColor(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text("done".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
