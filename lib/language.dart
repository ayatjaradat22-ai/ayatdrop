import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'home.dart';
import 'setting.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLangCode;
  static const Color dropRed = Color(0xFFFF1111);

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'desc': 'United States', 'code': 'en', 'flag': '🇺🇸'},
    {'name': 'العربية', 'desc': 'المنطقة العربية', 'code': 'ar', 'flag': '🇸🇦'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLangCode = context.locale.languageCode;
  }

  void _saveLanguage() async {
    if (_selectedLangCode != context.locale.languageCode) {
      await context.setLocale(Locale(_selectedLangCode));
      
      if (!mounted) return;

      // العودة للرئيسية (تبويب الحساب) ثم فتح الإعدادات لضمان التحديث الكامل
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainWrapper(initialIndex: 3),
        ),
        (route) => false,
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "language_title".tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: dropRed.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.translate_rounded, color: dropRed, size: 50),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "choose_language".tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              "select_preferred_language".tr(),
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  bool isSelected = _selectedLangCode == lang['code'];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedLangCode = lang['code']!),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.grey[50],
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? dropRed : Colors.grey.shade100,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: dropRed.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['name']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: isSelected ? Colors.black : Colors.black87,
                                  ),
                                ),
                                Text(
                                  lang['desc']!,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: dropRed, size: 26),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveLanguage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dropRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: dropRed.withOpacity(0.3),
                  ),
                  child: Text(
                    "save_changes".tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
