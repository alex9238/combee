import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants/constants.dart';
import '../configuration/configuration_page.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage>
    with WidgetsBindingObserver {
  bool _isTracking = false;
  final service = FlutterBackgroundService();
  StreamSubscription<Position>? _positionStreamSub;
  String locationDataIOS = "Esperando ubicación";

  bool _statusNotification = false;

  String? RutaActiva = "";
  String? UnidadActiva = "";

  final AccountLocation api = AccountLocation();

  // publicidad

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //_loadBanner();
    _requestNotificationPermission();
    _checkStatusService();

    //_checkOverlayPermission();
  }

  // -------------------------------
  // BANNER
  // -------------------------------
  Future<void> _loadBanner() async {
    final width =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          width.toInt(),
        );

    if (size == null) return;

    late final BannerAd banner;

    banner = BannerAd(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-3940256099942544/6300978111"
          : "ca-app-pub-3940256099942544/2934735716",
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print("✅ Banner adaptativo cargado");
          setState(() {
            _bannerAd = banner;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print("❌ Error Banner: $error");
          ad.dispose();
        },
      ),
    );

    await banner.load();
  }

  _checkStatusService() async {
    final prefs = await SharedPreferences.getInstance();

    // Comprobamos si la clave existe
    final exists = prefs.containsKey("isTracking");

    if (exists) {
      final value = prefs.getString(
        "isTracking",
      ); // o getString, según cómo la guardaste
      print("✅ 'isTracking' existe. Valor: $value");

      if (value == "true") {
        setState(() {
          _isTracking = true;
        });
        //return;
      }
    } else {
      print("⚠️ 'isTracking' no existe en SharedPreferences.");
    }

    setState(() {
      RutaActiva = prefs.getString("ruta");
      UnidadActiva = prefs.getString("unidad");
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //if (Platform.isAndroid) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      print('#################### ${state}');
      FlutterBackgroundService().invoke('app_status', {'active': false});
    } else if (state == AppLifecycleState.resumed) {
      FlutterBackgroundService().invoke('app_status', {'active': true});
    }
    //}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    //if (Platform.isAndroid) {
    FlutterBackgroundService().invoke('app_status', {'active': false});
    //}
    super.dispose();
  }

  Future<void> _requestNotificationPermission() async {
    bool granted = false;

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      final result = await androidImplementation
          .requestNotificationsPermission();
      granted = result ?? false;
    }

    // Si quieres incluir soporte iOS:
    /*final iosImplementation = flutterLocalNotificationsPlugin
         .resolvePlatformSpecificImplementation<
             IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);*/

    setState(() {
      _statusNotification = granted;
    });
  }

  /*Future<void> _checkOverlayPermission() async {
    if (!Platform.isAndroid) return;

    try {
      // Paso 1: Verificar permiso actual
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();

      if (hasPermission) {
        debugPrint('✅ Permiso de overlay ya concedido');
        _showSnackbar('✅ Permiso de overlay activo.');
        _requestNotificationPermission();
        return;
      }

      // Paso 2: Si no tiene permiso, solicitarlo
      final granted = await FlutterOverlayWindow.requestPermission();

      if (granted == true) {
        debugPrint('✅ Permiso de overlay concedido tras solicitud');
        _showSnackbar('✅ Permiso de overlay concedido.');
        _requestNotificationPermission();
      } else {
        _showSnackbar('❌ No se otorgó permiso para mostrar sobre otras apps.');
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando permiso overlay: $e');
      _showSnackbar('⚠️ Error al verificar permiso overlay.');
    }
  }*/

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // --- iOS ---
    if (Platform.isIOS) {
      if (permission == LocationPermission.whileInUse) {
        // En iOS, primero se obtiene "whileInUse", luego se puede solicitar "always"
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always) {
        _startRealTimeTracking();
      } else {
        _showSnackbar(
          'Para el rastreo continuo, activa el permiso "Permitir siempre" en Configuración > Privacidad > Ubicación.',
        );
        Geolocator.openAppSettings();
      }

      return;
    }

    // --- Android ---
    if (Platform.isAndroid && permission != LocationPermission.always) {
      _showSnackbar(
        'El rastreo persistente requiere permiso "Permitir todo el tiempo".',
      );

      final shouldOpen =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permiso de Ubicación'),
              content: const Text(
                'Para el rastreo en segundo plano, por favor cambia el permiso a "Permitir todo el tiempo" en la configuración de la aplicación.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Abrir Configuración'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldOpen) {
        Geolocator.openAppSettings();
      }
    } else if (permission == LocationPermission.always) {
      _startRealTimeTracking();
    }
  }

  /*Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (Platform.isAndroid && permission != LocationPermission.always) {
      _showSnackbar(
        'El rastreo persistente requiere permiso "Permitir todo el tiempo".',
      );

      final shouldOpen =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permiso de Ubicación'),
              content: const Text(
                'Para el rastreo en segundo plano, por favor cambia el permiso a "Permitir todo el tiempo" en la configuración de la aplicación.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Abrir Configuración'),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldOpen) {
        Geolocator.openAppSettings();
      }
    } else if (permission == LocationPermission.always) {
      if (Platform.isAndroid) {
        //_checkOverlayPermission();
        //_requestNotificationPermission();
      } else {
        //_requestNotificationPermission();
      }
      _startRealTimeTracking();
    }
  }*/

  Future<void> _startRealTimeTracking() async {
    try {
      debugPrint('✅ Aqui voy');
      //_startLocationTracking();
      //await WakelockPlus.enable();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("isTracking", "true");

      if (Platform.isAndroid) {
        _startLocationTracking(); // tu servicio existente
      } else if (Platform.isIOS) {
        //await _startiOSTracking();
        _startLocationTracking();
      }

      setState(() {
        _isTracking = true;
      });

      _showSnackbar('✅ Rastreo en tiempo real iniciado');
    } catch (e) {
      _showSnackbar('Error al iniciar rastreo: $e');
    }
  }

  Future<void> _startiOSTracking() async {
    if (_positionStreamSub != null) return;

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    // 🔹 Inicializa ubicación
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && Platform.isIOS) {
      await Geolocator.openLocationSettings();
    }

    Position currentPosition = await Geolocator.getCurrentPosition();

    // Guardar la última posición
    void _saveAndNotify(Position position) async {
      debugPrint(
        '📍 [iOS background] ${position.latitude}, ${position.longitude}',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_lat", position.latitude.toString());
      await prefs.setString("last_lng", position.longitude.toString());

      await flutterLocalNotificationsPlugin.show(
        0,
        'Tracking activo',
        'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      setState(() {
        locationDataIOS =
            'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
      });
    }

    Future<void> _sendLocationData(Position position) async {
      // ✅ EVITAR ENVÍOS SIMULTÁNEOS
      AccountLocation _accountLocation = AccountLocation();

      try {
        final now = DateTime.now();
        final prefs = await SharedPreferences.getInstance();

        await _accountLocation.sendTracking(
          position.latitude,
          position.longitude,
          prefs.getString("ruta")!,
          prefs.getString("unidad")!,
          prefs.getInt("estado")!,
          prefs.getInt("municipio")!,
        );

        // ✅ ACTUALIZAR OVERLAY (UNA SOLA VEZ)
      } catch (e) {
        print('❌ Error enviando ubicación: $e');
      } finally {}
    }

    // 🔹 Stream por distancia
    _positionStreamSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            currentPosition = position;
            _sendLocationData(position);
            _saveAndNotify(position);
          },
        );

    // 🔹 Timer por tiempo (cada 30 segundos)
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (currentPosition != null) {
        _saveAndNotify(currentPosition);
      }
    });
  }

  void _startLocationTracking() async {
    //await service.startService();

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      if (Platform.isIOS) {
        /*await _positionStreamSub?.cancel();
        _positionStreamSub = null;*/
        service.invoke('stopService');
      } else {
        service.invoke('stopService');
      }
    }
    //service.invoke("setAsForeground");
    //service.invoke("setAsBackground");
  }

  Future<void> _stopTracking() async {
    //await WakelockPlus.disable();

    if (Platform.isIOS) {
      /*await _positionStreamSub?.cancel();
      _positionStreamSub = null;*/
      service.invoke('stopService');
    } else {
      service.invoke('stopService');
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("isTracking", "false");

    setState(() {
      _isTracking = false;
    });

    _showSnackbar('🛑 Rastreo detenido');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para mejor funcionamiento:'),
            SizedBox(height: 10),
            Text('• Concede permiso "Siempre" para ubicación'),
            Text('• Desactiva optimización de batería para esta app'),
            Text('• Permite mostrar sobre otras apps'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  _addStop() async {
    bool permiso = await _checkPermission();

    if (permiso) {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final prefs = await SharedPreferences.getInstance();

      final response = await api.sendStop(
        pos.latitude,
        pos.longitude,
        prefs.getString("ruta")!,
        prefs.getString("unidad")!,
        prefs.getInt("estado")!,
        prefs.getInt("municipio")!,
      );
      if (response.message == 1) {
        _showSnackbar('✅ Parada registrada correctamente, gracias!');
      } else {
        _showSnackbar('❌ Hubo un error al registrar la parada');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          
          mainAxisSize: MainAxisSize.min, // evita que ocupe todo el ancho
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppImages.logoPantallaAppBar, // tu imagen PNG
              height: 30, // ajusta tamaño
            ),
            const SizedBox(width: 8), // espacio entre imagen y texto
            const Text(
              'Rastrea Tiempo Real',
              style: TextStyle(
                color: AppColors.greyTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.greyTitle),
          onPressed: () {
            // Preguntar si quiere detener el rastreo antes de salir
            if (_isTracking) {
              /*showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Rastreo activo'),
                  content: const Text(
                    'El rastreo está activo. ¿Quieres detenerlo antes de salir?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Salir sin detener'),
                    ),
                    TextButton(
                      onPressed: () {
                        _stopTracking();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Detener y salir'),
                    ),
                  ],
                ),
              );*/
              _stopTracking();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigurationPage(view: "chofer"),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigurationPage(view: "chofer"),
                ),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.greyTitle),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de estado
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'RUTA $RutaActiva - $UnidadActiva',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isTracking ? Icons.location_on : Icons.location_off,
                          color: _isTracking ? Colors.green : Colors.red,
                          size: 40,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isTracking ? 'RASTREANDO' : 'DETENIDO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _isTracking ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ubicación Actual:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Platform.isAndroid
                        ? StreamBuilder<Map<String, dynamic>?>(
                            stream: FlutterBackgroundService().on('update'),
                            builder: (context, snapshot) {
                              String locationData = "";

                              if (!snapshot.hasData) {
                                locationData = "Esperando ubicación";
                              } else {
                                final data = snapshot.data!;

                                locationData =
                                    'Lat: ${data["latitud"]}\n'
                                    'Lon: ${data["longitud"]}\n'
                                    'Vel: ${data["Vel"]}'
                                    'Hora: ${data["Hora"]}';

                                FlutterBackgroundService().invoke(
                                  'app_status',
                                  {'active': true},
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  locationData,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          )
                        : StreamBuilder<Map<String, dynamic>?>(
                            stream: FlutterBackgroundService().on('update'),
                            builder: (context, snapshot) {
                              String locationData = "";

                              if (!snapshot.hasData) {
                                locationData = "Esperando ubicación";
                              } else {
                                final data = snapshot.data!;

                                locationData =
                                    'Lat: ${data["latitud"]}\n'
                                    'Lon: ${data["longitud"]}\n'
                                    'Vel: ${data["Vel"]}'
                                    'Hora: ${data["Hora"]}';

                                FlutterBackgroundService().invoke(
                                  'app_status',
                                  {'active': true},
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  locationData,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),

                    /*Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              locationDataIOS,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),*/
                    const SizedBox(height: 10),
                    /*Text(
                      'Overlay: ${_isOverlayVisible ? 'ACTIVO' : 'INACTIVO'}',
                      style: TextStyle(
                        color: _isOverlayVisible ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),*/
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Botón principal de rastreo
            ElevatedButton.icon(
              onPressed: _isTracking
                  ? _stopTracking
                  : _requestLocationPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _isTracking ? Icons.stop : Icons.play_arrow,
                size: 28,
                color: Colors.white,
              ),
              label: Text(
                _isTracking ? 'DETENER RASTREO' : 'INICIAR TIEMPO REAL',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _addStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.bus_alert_outlined,
                size: 28,
                color: Colors.white,
              ),
              label: Text(
                'Registrar Parada',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Botón de overlay

            // Información
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 24),
                    SizedBox(height: 8),
                    Text(
                      '📍 Actualización en tiempo real\n'
                      //'📱 Overlay flotante persistente\n'
                      '⚡ Optimizado para batería\n'
                      '🔴 Funciona en segundo plano',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            /*if (_isLoaded)
              Container(
                color: Colors.black12,
                height: _bannerAd!.size.height.toDouble(),
                width: MediaQuery.of(context).size.width,
                child: AdWidget(ad: _bannerAd!),
              ),*/
          ],
        ),
      ),
    );
  }
}
