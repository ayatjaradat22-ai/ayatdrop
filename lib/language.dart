import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_colors.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text("language_title".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "select_language_subtitle".tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getSubtitleColor(context),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.8, // تم تقليل القيمة لزيادة طول المربع وتفادي الـ Overflow
                children: [
                  _buildLanguageCard(
                    context,
                    title: "English",
                    subtitle: "English Language",
                    shortName: "En",
                    locale: const Locale('en'),
                    isSelected: currentLocale.languageCode == 'en',
                  ),
                  _buildLanguageCard(
                    context,
                    title: "العربية",
                    subtitle: "اللغة العربية",
                    shortName: "عربي",
                    locale: const Locale('ar'),
                    isSelected: currentLocale.languageCode == 'ar',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String shortName,
    required Locale locale,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (context.locale != locale) {
          context.setLocale(locale);
          setState(() {}); 
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context, isSelected: isSelected),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.dropRed : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.1 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // استخدام Flexible لمنع الـ Overflow في الأيقونة/المربع العلوي
            Flexible(
              child: Container(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.dropRed : AppColors.getSecondaryBackground(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  shortName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.getPrimaryColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(context, isSelected: isSelected),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.dropRed.withValues(alpha: 0.7) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
