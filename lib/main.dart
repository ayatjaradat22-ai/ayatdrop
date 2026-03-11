import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'drop.dart';
import 'home.dart';

// دالة معالجة الإشعارات في الخلفية (يجب أن تكون خارج أي Class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    await Firebase.initializeApp();
    
    // إعدادات الإشعارات
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب الإذن (مهم لـ Android 13+ و iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // الحصول على الـ Token الخاص بالجهاز (لإرسال إشعارات لهذا الشخص تحديداً)
      String? token = await messaging.getToken();
      print("Firebase Messaging Token: $token");
      
      // ملاحظة: يفضل حفظ هذا الـ Token في Firestore تحت بيانات المستخدم
    }

    // الاستماع للإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // الاستماع للإشعارات والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Message Title: ${message.notification!.title}');
      }
    });

  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
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
          if (snapshot.hasData) {
            return const MainWrapper();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
