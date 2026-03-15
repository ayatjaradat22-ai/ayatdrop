import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'setting.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("language_title".tr()),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text("English"),
            onTap: () {
              context.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("العربية"),
            onTap: () {
              context.setLocale(const Locale('ar'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
