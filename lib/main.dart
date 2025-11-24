import 'dart:io';
import 'dart:ui';

import 'package:combee/provider/WalkieTalkieProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
//import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:combee/service/service_background_location.dart';
import 'package:combee/views/auth/login_page.dart';
import 'package:combee/views/splash/splash_page.dart';
import 'package:combee/views/tracking/overlay_widget.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/*
@pragma('vm:entry-point')
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await WakelockPlus.enable();
  DartPluginRegistrant.ensureInitialized();

  //_initializeOverlayListener();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(), // ✅ ESTO ACTIVA TU WIDGET
    ),
  );
}*/

/*void _initializeOverlayListener() {
  // Esperar un poco antes de configurar el listener
  Future.delayed(const Duration(milliseconds: 500), () {
    try {
      FlutterOverlayWindow.overlayListener.listen((data) {
        print('📡 [OVERLAY] Datos recibidos: $data');
        // El widget OverlayWidget manejará los datos a través de su propio listener
      });
    } catch (e) {
      print('❌ Error inicializando listener del overlay: $e');
    }
  });
}*/

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
    runApp(
      ChangeNotifierProvider(
        create: (context) => WalkieTalkieProvider(),
        child: const MyApp(),
      ),
    );
  });

  /*runApp(
    ChangeNotifierProvider(
      create: (context) => WalkieTalkieProvider(),
      child: const MyApp(),
    ),
  );*/
}

Future<void> _initializeNotificationsAndService() async {
  // 🔸 Inicializa plugin y canal

  print('Modo actual: ${kReleaseMode ? 'Release' : 'Debug'}');

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestProvisionalPermission: false,
        requestCriticalPermission: false,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        defaultPresentBanner: true,
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground_channel',
    'Servicio en ejecución',
    description: 'Canal para notificaciones del rastreo',
    importance: Importance.low,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await androidPlugin?.createNotificationChannel(channel);

  // 🔸 Configura el servicio, pero NO lo inicies aún
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: 'my_foreground_channel',
      initialNotificationTitle: 'Servicio Iniciado',
      initialNotificationContent: 'Esperando actualización...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

Future<void> initializeService() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final service = FlutterBackgroundService();

  /*await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground_channel',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: false,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );*/

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: 'my_foreground_channel',
      initialNotificationTitle: 'Servicio Iniciado',
      initialNotificationContent: 'Esperando actualización...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  // Comprobamos si la clave existe
  final exists = prefs.containsKey("isTracking");

  if (exists) {
    final value = prefs.getString(
      "isTracking",
    ); // o getString, según cómo la guardaste
    print("✅ 'isTracking' existe. Valor: $value");

    if (value == "true") {
      if (Platform.isAndroid) {
        final statusTracking = await service.isRunning();
        await prefs.setString("isTracking", statusTracking.toString());
      }
    }
  } else {
    print("⚠️ 'isTracking' no existe en SharedPreferences.");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackbarKey,
      title: 'Rutas Tracking',
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
