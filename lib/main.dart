import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'splash_screen.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification!.title, message.notification!.body);
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _setupUserAndFollowersListener(user.uid);
      }
    });

  } catch (e) {
    debugPrint("Init Error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: const MyApp(),
      ),
    ),
  );
}

// دالة سحرية لمتابعة عروض المتاجر التي يتابعها المستخدم
void _setupUserAndFollowersListener(String uid) async {
  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 1. الحصول على قائمة المتاجر التي يتابعها المستخدم
  FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('following_stores')
      .snapshots()
      .listen((followingSnapshot) {
    
    List<String> followedStoreIds = followingSnapshot.docs.map((doc) => doc.id).toList();
    
    if (followedStoreIds.isEmpty) return;

    // 2. مراقبة جدول العروض (Deals) للعروض الجديدة
    // تم تغيير 'timestamp' إلى 'createdAt' لتتوافق مع ما يتم تخزينه في المتجر
    FirebaseFirestore.instance
        .collection('deals')
        .where('createdAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .listen((dealsSnapshot) {
      
      for (var change in dealsSnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var dealData = change.doc.data() as Map<String, dynamic>;
          String storeId = dealData['storeId'] ?? "";
          
          // 3. إذا كان العرض من متجر أتابعه، أظهر إشعاراً فوراً
          if (followedStoreIds.contains(storeId)) {
            _showNotification(
              "عرض جديد من ${dealData['storeName'] ?? 'متجر تتابعه'} 🔥",
              "خصم ${dealData['discount']}% على ${dealData['product']}"
            );
          }
        }
      }
    });
  });
}

void _showNotification(String? title, String? body) {
  flutterLocalNotificationsPlugin.show(
    DateTime.now().hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFFF1111)),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xFFFF1111)),
      home: const SplashScreen(),
    );
  }
}
