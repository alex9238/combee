import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
//import 'package:flutter_background_service/flutter_background_service.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:combee/views/splash/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

//final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /*final config = RequestConfiguration(
    testDeviceIds: ["9F9D8B4244C864C5E5C8FFDC39753CBB"],
  );
  MobileAds.instance.updateRequestConfiguration(config);

  await MobileAds.instance.initialize();*/
  await _initializeNotificationsAndService();
  //runApp(const MyApp());

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Bloquear solo en orientación vertical
  ]).then((_) {
    runApp(const MyApp());
  });

  /*runApp(
    ChangeNotifierProvider(
      create: (context) => WalkieTalkieProvider(),
      child: const MyApp(),
    ),
  );
  */
}

Future<void> _initializeNotificationsAndService() async {
  print('Modo actual: ${kReleaseMode ? 'Release' : 'Debug'}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackbarKey,
      title: 'Combee',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const SplashScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (opcional)
      ],
    );
  }
}
