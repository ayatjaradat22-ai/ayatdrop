import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'drop.dart'; // صفحة Login
import 'home.dart'; // صفحة MainWrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    // تفعيل الفايربيز
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations', // مسار ملفات الترجمة
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      // فحص حالة تسجيل الدخول تلقائياً
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF1111)),
              ),
            );
          }
          // إذا كان مسجل دخوله مسبقاً، نرسله لصفحة MainWrapper مباشرة
          if (snapshot.hasData) {
            return const MainWrapper();
          }
          // إذا لم يكن مسجلاً، نرسله لصفحة تسجيل الدخول
          return const LoginScreen();
        },
      ),
    );
  }
}
