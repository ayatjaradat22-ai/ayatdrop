import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app_colors.dart';

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
                childAspectRatio: 0.9,
                children: [
                  _buildLanguageCard(
                    context,
                    title: "English",
                    subtitle: "English",
                    locale: const Locale('en'),
                    isSelected: currentLocale.languageCode == 'en',
                    icon: "🇺🇸",
                  ),
                  _buildLanguageCard(
                    context,
                    title: "العربية",
                    subtitle: "Arabic",
                    locale: const Locale('ar'),
                    isSelected: currentLocale.languageCode == 'ar',
                    icon: "🇸🇦",
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
    required Locale locale,
    required bool isSelected,
    required String icon,
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
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context, isSelected: isSelected),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.dropRed : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.dropRed.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(icon, style: const TextStyle(fontSize: 45)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(context, isSelected: isSelected),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.dropRed.withOpacity(0.7) : Colors.grey,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle, color: AppColors.dropRed, size: 20),
            ]
          ],
        ),
      ),
    );
  }
}
