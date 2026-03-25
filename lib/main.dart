import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'app_colors.dart';
import 'home.dart';

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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String themeName = prefs.getString('app_theme') ?? 'light';
  AppTheme savedTheme = AppTheme.values.firstWhere(
    (e) => e.name == themeName, 
    orElse: () => AppTheme.light
  );

  try {
    await Firebase.initializeApp();
    
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    _setupBackgroundListeners();

  } catch (e) {
    debugPrint("Init Error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(savedTheme),
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

void _setupBackgroundListeners() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _showNotification(message.notification!.title, message.notification!.body, message.data);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleDeepLink(message.data);
  });

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      _setupUserAndFollowersListener(user.uid);
    }
  });

  FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

void _handleDeepLink(Map<String, dynamic> data) {}

void _setupUserAndFollowersListener(String uid) async {
  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<String> followedStoreIds = [];
  final startTime = Timestamp.now();

  FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('following_stores')
      .snapshots()
      .listen((followingSnapshot) {
    followedStoreIds = followingSnapshot.docs.map((doc) => doc.id).toList();
  });

  FirebaseFirestore.instance
      .collection('deals')
      .where('createdAt', isGreaterThan: startTime)
      .snapshots()
      .listen((dealsSnapshot) {
    for (var change in dealsSnapshot.docChanges) {
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        var dealData = change.doc.data() as Map<String, dynamic>;
        String storeId = dealData['storeId'] ?? "";
        
        if (followedStoreIds.contains(storeId)) {
          _showNotification(
            "عرض جديد من ${dealData['storeName'] ?? 'متجر تتابعه'} 🔥",
            "خصم ${dealData['discount']}% على ${dealData['product']}",
            {'dealId': change.doc.id}
          );
        }
      }
    }
  });
}

void _showNotification(String? title, String? body, Map<String, dynamic> data) {
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
    payload: data['dealId'],
  );
}

class ThemeProvider with ChangeNotifier {
  AppTheme _currentTheme;
  
  ThemeProvider(AppTheme theme) : _currentTheme = theme;

  AppTheme get currentTheme => _currentTheme;

  ThemeMode get themeMode => _currentTheme == AppTheme.light ? ThemeMode.light : ThemeMode.dark;

  void setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme.name);
  }

  void resetToDefault() {
    if (_currentTheme != AppTheme.light && _currentTheme != AppTheme.dark) {
      setTheme(AppTheme.light);
    }
  }

  void toggleTheme(bool isDark) {
    setTheme(isDark ? AppTheme.dark : AppTheme.light);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _listenToPremiumStatus();
  }

  void _listenToPremiumStatus() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            bool isPremium = data?['isPremium'] ?? false;
            
            if (!isPremium) {
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              // إذا كان المستخدم غير بريميوم ويستخدم ثيماً مخصصاً، نرجعه للثيم الأساسي
              themeProvider.resetToDefault();
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppColors.getTheme(themeProvider.currentTheme),
      home: const SplashScreen(),
    );
  }
}
