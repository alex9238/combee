import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:flutter_overlay_window/flutter_overlay_window.dart'hide NotificationVisibility;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../http/http_location.dart';

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  /* 
    CONFIGURACIÓN DEL PUSH NOTIFICATION LOCAL
  */

  /*final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initSettingsAndroid,
  );
  await localNotifications.initialize(initializationSettings);*/

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initSettingsAndroid,
    iOS: initSettingsIOS,
  );

  await localNotifications.initialize(initializationSettings);

  /* 
   END CONFIGURACIÓN DEL PUSH NOTIFICATION LOCAL
 */

  print("🛰️ Servicio iniciado correctamente");

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  final AccountLocation _accountLocation = AccountLocation();

  Position? lastPosition;
  DateTime lastSent = DateTime.now().subtract(const Duration(seconds: 30));
  DateTime lastOverlayUpdate = DateTime.now();
  bool _isSendingLocation = false;
  bool _isActivaScreen = true;

  const double distanceThreshold = 5; //aqui modifico la distancia
  const Duration timeThreshold = Duration(seconds: 30);

  StreamSubscription? _overlayStreamSub;
  Completer<bool>? _pongCompleter;

  /*void initOverlayListener() {
    if (_overlayStreamSub != null) return; // evita duplicar

    _overlayStreamSub = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map && data['pong'] == true) {
        print('🏓 PONG recibido desde overlay');
        _pongCompleter?.complete(true);
      }
    });
  }*/

  //initOverlayListener();

  // Variable para almacenar el último texto del overlay
  String currentOverlayText = '🛰️ Esperando datos de ubicación';

  // Función para actualizar el overlay
  // ✅ FUNCIÓN OPTIMIZADA PARA ACTUALIZAR OVERLAY

  Future<void> _updateOverlay(String text) async {
    try {
      /*bool isActive = await FlutterOverlayWindow.isActive();

      if (!isActive) {
        print('🪟 Overlay no activo. Intentando recrearlo...');
        //await FlutterOverlayWindow.closeOverlay();
        //await Future.delayed(const Duration(milliseconds: 400));
        await FlutterOverlayWindow.showOverlay(
          height: 500,
          width: 800,
          alignment: OverlayAlignment.center,
          overlayTitle: "📍 Rastreo activo",
          overlayContent: "Mostrando ubicación en tiempo real",
          enableDrag: true,
        );
        //await Future.delayed(const Duration(milliseconds: 800));
      } else {
        print("############## ${isActive}");
      }

      await FlutterOverlayWindow.shareData({'location_info': text});
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString("last_overlay_location", text);*/
    } catch (e) {
      print('❌ Error actualizando overlay: $e');
    }
  }

  // Timer para forzar actualización del overlay cada 30 segundos
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (currentOverlayText != '🛰️ Esperando datos de ubicación') {
      await _updateOverlay(currentOverlayText);
    }
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) async {
    print("🛰️ Servicio detenido correctamente");

    //await localNotifications.cancel(888);
    service.stopSelf();
  });

  service.on('requestLocationUpdate').listen((event) async {
    // Si se recibe la señal, forzar el envío del último dato conocido
    await _updateOverlay(currentOverlayText);
  });

  service.on('app_status').listen((event) async {
    bool active = event?['active'] ?? false;
    print(
      '[SERVICE] Estado de la app: ${active ? 'ACTIVA' : 'CERRADA / EN SEGUNDO PLANO'}',
    );

    if (!active) {
      // App en background - mostrar overlay
      try {
        _isActivaScreen = false;
        /*await FlutterOverlayWindow.showOverlay(
          height: 500,
          width: 800,
          alignment: OverlayAlignment.center,
          enableDrag: true,
          overlayTitle: "📍 Rastreo activo",
          overlayContent: "Mostrando ubicación en tiempo real",
        );

        // ✅ Esperar a que el overlay esté listo y enviar datos iniciales
        await Future.delayed(const Duration(milliseconds: 1000));
        await _updateOverlay(currentOverlayText);*/
      } catch (e) {
        print('❌ Error mostrando overlay: $e');
      }
    } else {
      // App en foreground - cerrar overlay
      try {
        _isActivaScreen = true;
        //await FlutterOverlayWindow.closeOverlay();
      } catch (e) {
        print('❌ Error cerrando overlay: $e');
      }
    }
  });

  // ✅ FUNCIÓN ÚNICA PARA ENVIAR UBICACIÓN
  Future<void> _sendLocationData(Position position, bool _screenStatus) async {
    // ✅ EVITAR ENVÍOS SIMULTÁNEOS
    if (_isSendingLocation) {
      print('⏳ Envío en progreso, omitiendo...');
      return;
    }

    _isSendingLocation = true;

    try {
      final now = DateTime.now();

      // ✅ CALCULAR DISTANCIA (solo si tenemos última posición)
      double distance = 0;
      if (lastPosition != null) {
        distance = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }

      // ✅ CRITERIOS MÁS ESTRICTOS PARA ENVÍO
      final shouldSendByDistance = distance >= distanceThreshold;
      final shouldSendByTime = now.difference(lastSent) >= timeThreshold;
      final isFirstLocation = lastPosition == null;

      if (shouldSendByDistance || shouldSendByTime || isFirstLocation) {
        print(
          '📡 [BG] Enviando ubicación - '
          'Distancia: ${distance.toStringAsFixed(2)}m, '
          'Tiempo: ${now.difference(lastSent).inSeconds}s',
        );

        // ✅ ACTUALIZAR TEXTO DEL OVERLAY UNA SOLA VEZ

        final prefs = await SharedPreferences.getInstance();

        // ✅ ENVIAR AL SERVIDOR
        await _accountLocation.sendTracking(
          position.latitude,
          position.longitude,
          prefs.getString("ruta")!,
          prefs.getString("unidad")!,
          prefs.getInt("estado")!,
          prefs.getInt("municipio")!,
        );

        // ✅ ACTUALIZAR OVERLAY (UNA SOLA VEZ)
        /*await _updateOverlay(currentOverlayText);

        // ✅ ACTUALIZAR UI PRINCIPAL
        service.invoke('update', {
          "latitud": position.latitude.toStringAsFixed(6),
          "longitud": position.longitude.toStringAsFixed(6),
          "Vel": '${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s',
          "Hora": '${DateTime.now().toString().substring(11, 19)}',
        });*/

        lastPosition = position;
        lastSent = now;
      } else {
        print(
          '⏭️  Ubicación omitida para envio a server - '
          'Distancia: ${distance.toStringAsFixed(2)}m, '
          'Tiempo: ${now.difference(lastSent).inSeconds}s',
        );

        if (_isActivaScreen) {
          print("✅ Enviando a pantalla");
          service.invoke('update', {
            "latitud": position.latitude.toStringAsFixed(6),
            "longitud": position.longitude.toStringAsFixed(6),
            "Vel": '${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s',
            "Hora": '${DateTime.now().toString().substring(11, 19)}',
          });
        } else {
          print("✅ Enviando a overlay");
          await _updateOverlay(currentOverlayText);
        }
        // ✅ ACTUALIZAR OVERLAY (UNA SOLA VEZ)
        /*

        // ✅ ACTUALIZAR UI PRINCIPAL
        */
      }
    } catch (e) {
      print('❌ Error enviando ubicación: $e');
    } finally {
      _isSendingLocation = false;
    }
  }

  // ✅ CONFIGURACIÓN MÁS PRECISA DE GEOLOCATOR
  final locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 30, // metros
  );

  // ✅ ESCUCHA CONTINUA EN LUGAR DE TIMER PERIÓDICO
  Geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (Position position) async {
      print(
        '📍 Nueva posición obtenida: '
        '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}',
      );

      currentOverlayText =
          'Lat: ${position.latitude.toStringAsFixed(6)}\n'
          'Lon: ${position.longitude.toStringAsFixed(6)}\n'
          'Vel: ${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s\n'
          'Hora: ${DateTime.now().toString().substring(11, 19)}';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'my_foreground_channel',
            'Servicio en ejecución',
            channelDescription: 'Actualiza la hora cada segundo',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            onlyAlertOnce: true,
            showWhen: false,
          );
      const DarwinNotificationDetails
      iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true, // Muestra alerta visual
        presentBadge: true, // No cambia el ícono del badge
        presentSound:
            true, // No reproduce sonido (útil si es una notificación “silenciosa”)
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      if (!_isActivaScreen) {
        // Actualiza el contenido de la notificación
        await localNotifications.show(
          888,
          'Servicio Tracking Activo Distancia',
          '$currentOverlayText',
          platformChannelSpecifics,
        );
      }

      // ✅ ACTUALIZAR UI PRINCIPAL
      service.invoke('update', {
        "latitud": position.latitude.toStringAsFixed(6),
        "longitud": position.longitude.toStringAsFixed(6),
        "Vel": '${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s',
        "Hora": '${DateTime.now().toString().substring(11, 19)}',
      });

      await _sendLocationData(position, _isActivaScreen);
      print("#### ESTATUS SCREEN ${_isActivaScreen} ");
      if (!_isActivaScreen) {
        await _updateOverlay(currentOverlayText);
      }

      // ✅ ACTUALIZAR NOTIFICACIÓN (sin duplicar envíos)
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Rastreo activo',
          content:
              'Última: ${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}',
        );
      }
    },
    onError: (e) {
      print('⚠️ Error en stream de ubicación: $e');
    },
  );

  // ✅ TIMER DE SEGURIDAD (solo para casos extremos)
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    // Solo enviar si no ha habido movimiento en 2 minutos
    final timeSinceLastSend = DateTime.now().difference(lastSent);
    if (timeSinceLastSend >= const Duration(minutes: 1)) {
      print('🕒 Envío de seguridad por inactividad');
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );

        currentOverlayText =
            'Lat: ${position.latitude.toStringAsFixed(6)}\n'
            'Lon: ${position.longitude.toStringAsFixed(6)}\n'
            'Vel: ${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s\n'
            'Hora: ${DateTime.now().toString().substring(11, 19)}';

        print("#### ESTATUS SCREEN ${_isActivaScreen} ");

        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
              'my_foreground_channel',
              'Servicio en ejecución',
              channelDescription: 'Actualiza la hora cada segundo',
              importance: Importance.low,
              priority: Priority.low,
              ongoing: true,
              onlyAlertOnce: true,
              showWhen: false,
            );
        const DarwinNotificationDetails
        iOSPlatformChannelSpecifics = DarwinNotificationDetails(
          presentAlert: true, // Muestra alerta visual
          presentBadge: true, // No cambia el ícono del badge
          presentSound:
              true, // No reproduce sonido (útil si es una notificación “silenciosa”)
        );

        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(
              android: androidPlatformChannelSpecifics,
              iOS: iOSPlatformChannelSpecifics,
            );

        // Actualiza el contenido de la notificación
        if (!_isActivaScreen) {
          await localNotifications.show(
            888,
            'Servicio Tracking Activo Tiempo',
            '$currentOverlayText',
            platformChannelSpecifics,
          );

        
          await _updateOverlay(currentOverlayText);
        }

        // ✅ ACTUALIZAR UI PRINCIPAL
        service.invoke('update', {
          "latitud": position.latitude.toStringAsFixed(6),
          "longitud": position.longitude.toStringAsFixed(6),
          "Vel": '${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s',
          "Hora": '${DateTime.now().toString().substring(11, 19)}',
        });

        await _sendLocationData(position, _isActivaScreen);
      } catch (e) {
        print('❌ Error en envío de seguridad: $e');
      }
    }
  });
}




/*
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initSettingsAndroid,
  );
  await localNotifications.initialize(initializationSettings);

  bool running = true;

  // Si se detiene el servicio manualmente desde la app
  service.on('stopService').listen((event) {
    running = false;
    service.stopSelf();
  });

  // Bucle que actualiza la hora cada segundo
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (!running) {
      timer.cancel();
      return;
    }

    final now = DateTime.now().toLocal();
    final formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'my_foreground_channel',
          'Servicio en ejecución',
          channelDescription: 'Actualiza la hora cada segundo',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          showWhen: false,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Actualiza el contenido de la notificación
    await localNotifications.show(
      888,
      'Servicio activo',
      'Hora actual: $formattedTime',
      platformChannelSpecifics,
    );
  });
}
*/


/*
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Configuración de notificaciones para Android e iOS
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initSettingsAndroid,
    iOS: initSettingsIOS,
  );

  await localNotifications.initialize(initializationSettings);

  // Variables de control
  Position? lastPosition;
  DateTime lastSent = DateTime.now().subtract(const Duration(seconds: 30));
  bool _isSendingLocation = false;
  bool _isAppActive = true; // Indica si la app está en foreground
  const double distanceThreshold = 5; // metros
  const Duration timeThreshold = Duration(seconds: 30);
  String currentOverlayText = '🛰️ Esperando datos de ubicación';

  final AccountLocation _accountLocation = AccountLocation();
  final locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
  );

  // Función para enviar datos de ubicación
  Future<void> _sendLocationData(Position position) async {
    if (_isSendingLocation) return;
    _isSendingLocation = true;

    try {
      final now = DateTime.now();
      double distance = 0;

      if (lastPosition != null) {
        distance = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }

      final shouldSendByDistance = distance >= distanceThreshold;
      final shouldSendByTime = now.difference(lastSent) >= timeThreshold;
      final isFirstLocation = lastPosition == null;

      if (shouldSendByDistance || shouldSendByTime || isFirstLocation) {
        final prefs = await SharedPreferences.getInstance();

        await _accountLocation.sendTracking(
          position.latitude,
          position.longitude,
          prefs.getString("ruta") ?? "",
          prefs.getString("unidad") ?? "",
          prefs.getInt("estado") ?? 0,
          prefs.getInt("municipio") ?? 0,
        );

        lastPosition = position;
        lastSent = now;
      }

      // Actualizar notificación y UI principal
      currentOverlayText =
          'Lat: ${position.latitude.toStringAsFixed(6)}\n'
          'Lon: ${position.longitude.toStringAsFixed(6)}\n'
          'Vel: ${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s\n'
          'Hora: ${DateTime.now().toString().substring(11, 19)}';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'my_foreground_channel',
        'Servicio en ejecución',
        channelDescription: 'Actualiza la hora y ubicación',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: false,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await localNotifications.show(
        888,
        'Servicio Tracking Activo',
        '$currentOverlayText',
        platformDetails,
      );

      service.invoke('update', {
        "latitud": position.latitude.toStringAsFixed(6),
        "longitud": position.longitude.toStringAsFixed(6),
        "Vel": '${position.speed?.toStringAsFixed(1) ?? '0.0'} m/s',
        "Hora": '${DateTime.now().toString().substring(11, 19)}',
      });
    } catch (e) {
      print('❌ Error enviando ubicación: $e');
    } finally {
      _isSendingLocation = false;
    }
  }

  // Escucha continua de geolocalización
  Geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (Position position) async {

      print("Enviado ubicación por posición");
      await _sendLocationData(position);
    },
    onError: (e) => print('⚠️ Error en stream de ubicación: $e'),
  );

  // Eventos del servicio
  service.on('stopService').listen((event) async {
    print("🛰️ Servicio detenido correctamente");
    service.stopSelf();
  });

  service.on('app_status').listen((event) async {
    _isAppActive = event?['active'] ?? true;

    print(
      '[SERVICE] Estado de la app: ${_isAppActive ? 'ACTIVA' : 'CERRADA / EN SEGUNDO PLANO'}',
    );
  });

  // Timer de seguridad (envío periódico por si la ubicación no cambia)
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (DateTime.now().difference(lastSent) >= const Duration(minutes: 1)) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          
        );
        print("Enviado ubicación por inactividad");
        await _sendLocationData(position);
      } catch (e) {
        print('❌ Error en envío de seguridad: $e');
      }
    }
  });
}
*/