import 'dart:async';
import 'dart:io';
import 'package:combeetracking/provider/WalkieTalkieProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants/constants.dart';
import '../configuration/configuration_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage>
    with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  bool showSearch = false;
  bool _isCheckingPermissions = true;

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
    WakelockPlus.enable();
    //_loadBanner();
    /*_requestNotificationPermission();
    _checkStatusService();*/

    //WidgetsBinding.instance.addPostFrameCallback((_) async {
    /*await _checkStatusService();
      _handlePermissionsAndConnect();
      _requestNotificationPermission();*/

    //});

    //_checkOverlayPermission();

    initConfig();
  }

  Future<void> initConfig() async {
    await _checkStatusService();
    await _requestNotificationPermission();
    await _handlePermissionsAndConnect();
  }

  // FUNCIOA EN ANDROID

  Future<void> _handlePermissionsAndConnect() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      print("patito juan: ${RutaActiva}_${UnidadActiva}");
      await Provider.of<WalkieTalkieProvider>(
        context,
        listen: false,
      ).connect("${RutaActiva}_${UnidadActiva}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de micrófono denegado.')),
      );
    }
  }

  // Toda la parte de tracking

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
        await _stopTracking();
        print("⚠️ 'reiniciando servicio");

        await Future.delayed(Duration(seconds: 3));
        await _startRealTimeTracking();

        print("⚠️ 'iniciado servicio");
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

    _searchCtrl.dispose();
    Provider.of<WalkieTalkieProvider>(context, listen: false).dispose();
    //}
    super.dispose();
  }

  /*Future<void> _requestNotificationPermission() async {
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
  }*/

  Future<void> _requestNotificationPermission() async {
    bool granted = false;

    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final result = await android.requestNotificationsPermission();
      granted = result ?? false;

      // 🔥 Esto es clave
      // Espera a que el sistema cierre el diálogo antes de continuar.
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _statusNotification = granted);
  }

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

        /*await _requestNotificationPermission();

        if(_statusNotification){
          _startRealTimeTracking();
        }
        else{
          _showSnackbar(
            'Para el rastreo continuo, activa el permiso de Notificación',
          );
        }*/
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
      //await _requestNotificationPermission();

      /*if(_statusNotification){
          _startRealTimeTracking();
        }
        else{
          _showSnackbar(
            'Para el rastreo continuo, activa el permiso de Notificación',
          );
        }*/
    }
  }

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
            Text(
              'RUTA ${RutaActiva} - ${UnidadActiva}',
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
          onPressed: () async {
            final walkie = Provider.of<WalkieTalkieProvider>(
              context,
              listen: false,
            );

            // 🔥 desconectar y limpiar TODO
            await walkie.disposeAsync();

            if (_isTracking) {
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
      body: SafeArea(
        child: Consumer<WalkieTalkieProvider>(
          builder: (context, provider, child) {
            final filtered = provider.connectedUsers
                .where(
                  (u) =>
                      u.toLowerCase().contains(_searchCtrl.text.toLowerCase()),
                )
                .toList();

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // =======================
                // CARD LOCATION
                // =======================
                Card(
                  elevation: 3,
                  child: SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          // --- ESTADO DE RASTREO ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isTracking
                                    ? Icons.location_on
                                    : Icons.location_off,
                                color: _isTracking ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isTracking ? 'RASTREANDO' : 'DETENIDO',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isTracking
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // --- CUERPO PRINCIPAL ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -------------------- INFORMACIÓN --------------------
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ubicación Actual:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Caja donde muestras la ubicación
                                  StreamBuilder<Map<String, dynamic>?>(
                                    stream: FlutterBackgroundService().on(
                                      'update',
                                    ),
                                    builder: (context, snapshot) {
                                      String locationData = "";

                                      if (!snapshot.hasData) {
                                        locationData = "Esperando ubicación";
                                      } else {
                                        final data = snapshot.data!;
                                        locationData =
                                            'Lat: ${data["latitud"]}\n'
                                            'Lon: ${data["longitud"]}\n'
                                            'Vel: ${data["Vel"]}\n'
                                            'Hora: ${data["Hora"]}';

                                        FlutterBackgroundService().invoke(
                                          'app_status',
                                          {'active': true},
                                        );
                                      }

                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                ],
                              ),

                              const Spacer(),

                              // -------------------- BOTONES DERECHA --------------------
                              Row(
                                children: [
                                  // Botón Play/Stop pequeño
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: ElevatedButton(
                                      onPressed: _isTracking
                                          ? _stopTracking
                                          : _requestLocationPermission,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isTracking
                                            ? Colors.red
                                            : Colors.green,
                                        shape: const CircleBorder(),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Icon(
                                        _isTracking
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // Botón estético pequeño
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: ElevatedButton(
                                      onPressed: _addStop, // ← importante
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: const CircleBorder(),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Icon(
                                        Icons.bus_alert,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =======================
                // CARD FUTURO BANNER
                // =======================
                /*Card(
                  elevation: 3,
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        "Otro módulo aquí...",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),*/
                // =======================
                // CARD (PTT)
                // =======================
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: provider.wsConnected
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                provider.wsConnected
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                color: provider.wsConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.wsConnected
                                      ? 'Conectado'
                                      : 'Desconectado — reintentando...',
                                ),
                              ),
                              Text('Conectado(s): ${provider.peerCount}'),
                              const SizedBox(width: 10),

                              // -----------------------
                              // 🔍 BOTÓN MOSTRAR BUSCADOR
                              // -----------------------
                              IconButton(
                                icon: Icon(
                                  showSearch ? Icons.close : Icons.search,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showSearch = !showSearch;
                                    if (!showSearch) _searchCtrl.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // --- barra de búsqueda ---
                              if (showSearch)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 12,
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar usuario',
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // --- fila superior user seleccionado + broadcast ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.selectedUserDisplay,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.campaign),
                                    label: const Text("Todos"),
                                    onPressed: () => provider
                                        .setSelectedUserFromDisplay("Todos"),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              SizedBox(
                                height: 120,
                                child: Stack(
                                  children: [
                                    // LISTA REAL CON FONDO GRIS
                                    Container(
                                      color: Colors
                                          .grey
                                          .shade100, // 👈 fondo gris parejo
                                      child: ListView.builder(
                                        itemCount: filtered.length,
                                        itemBuilder: (context, idx) {
                                          final u = filtered[idx];
                                          final isSelected =
                                              provider.selectedUserDisplay == u;

                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              child: Text(u[0].toUpperCase()),
                                            ),
                                            title: Text(u),
                                            trailing: isSelected
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  )
                                                : null,
                                            onTap: () => provider
                                                .setSelectedUserFromDisplay(u),
                                          );
                                        },
                                      ),
                                    ),

                                    // INDICADOR DE “HAY MÁS” ABAJO
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: IgnorePointer(
                                        child: Container(
                                          height: 25,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.grey.shade100
                                                    .withOpacity(
                                                      0.0,
                                                    ), // 👈 ajustar el fade
                                                Colors
                                                    .grey
                                                    .shade100, // 👈 mismo gris
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // --- botón PTT ---
                              GestureDetector(
                                onLongPressStart: (_) =>
                                    provider.startSpeaking(),
                                onLongPressEnd: (_) => provider.stopSpeaking(),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: provider.isSpeaking
                                        ? Colors.red.shade600
                                        : (provider.hasActivePeer
                                              ? Colors.green.shade600
                                              : Colors.grey),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    provider.isSpeaking
                                        ? Icons.mic
                                        : Icons.mic_none,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                provider.isSpeaking
                                    ? "Hablando..."
                                    : "Mantén presionado para hablar",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // agrega más cards aquí...
              ],
            );
          },
        ),
      ),
    );
  }
}
