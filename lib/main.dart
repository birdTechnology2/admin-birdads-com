// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'main_menu.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // هذا السطر للتأكد من أن Firebase تم تهيئتها بشكل صحيح في الخلفية
  await Firebase.initializeApp(options: firebaseOptions);
  print("Handling a background message: ${message.messageId}");
  // هنا يمكنك تشغيل إشعارات أو تنفيذ أي منطق خاص في الخلفية
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy()); // Set URL strategy to remove # from URLs
  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  // تعيين معالج الرسائل في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(App());
}

class App extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp.router(
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          routeInformationProvider: router.routeInformationProvider,
          title: 'Your Project',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              headlineLarge: TextStyle(color: Colors.white),
              headlineMedium: TextStyle(color: Colors.white),
              headlineSmall: TextStyle(color: Colors.white),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white),
              labelLarge: TextStyle(color: Colors.white70),
              labelSmall: TextStyle(color: Colors.white),
            ),
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          themeMode: currentMode,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? Container(),
            );
          },
        );
      },
    );
  }
}
