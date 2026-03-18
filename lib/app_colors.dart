import 'package:flutter/material.dart';

class AppColors {
  static const Color dropRed = Color(0xFFFF1111);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color premiumBlack = Color(0xFF121212);
  
  // يمكنك إضافة ألوان أخرى هنا لاحقاً لتسهيل التعديل
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color getScaffoldColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
}
