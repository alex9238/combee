import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';

import 'package:combeetracking/helper/databaseHelper.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/model/rutachecador.dart';
import 'package:combeetracking/model/trackingrutaunidad.dart';
import 'package:combeetracking/views/checker/checker_page.dart';
import 'package:combeetracking/views/concessionaire/route_filter_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/constants.dart';

class TrackingMapCheckerPage extends StatefulWidget {
  const TrackingMapCheckerPage({Key? key}) : super(key: key);

  @override
  State<TrackingMapCheckerPage> createState() => _TrackingMapCheckerPageState();
}

class _TrackingMapCheckerPageState extends State<TrackingMapCheckerPage> {
  final MapController _mapController = MapController();
  String layer1 = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  List<Map<String, dynamic>> resultados = [];
  List<TrackingRutaUnidad> ubicaciones = [];
  Timer? _timer;
  final AccountLocation api = AccountLocation();

  // 📍 variables de ubicación
  LatLng? _miUbicacion;
  StreamSubscription<Position>? _posicionSub;

  List<String> _wmsLayers = [];

  Map<String, bool> _wmsSeleccionadas = {};
  Map<String, Color> _wmsColores = {};
  final List<Color> _coloresDisponibles = [
    Colors.brown,
    Colors.green,
    Colors.teal,
    Colors.purple,
    Colors.teal,
    Colors.black,
    Colors.deepPurpleAccent,
  ];

  List<RutaChecador> paradaVirtual = [];

  @override
  void initState() {
    super.initState();
    _obtenerParadasVirtuales();
    _buscar();
    _iniciarActualizacionPeriodica();
    _iniciarUbicacion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posicionSub?.cancel();
    super.dispose();
  }

  void _iniciarActualizacionPeriodica() {
    // Actualiza tracking cada 15 minutos
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _buscar();
    });
  }

  Future<void> _iniciarUbicacion() async {
    bool servicio = await Geolocator.isLocationServiceEnabled();
    if (!servicio) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }

    if (permiso == LocationPermission.deniedForever) return;

    // Obtener ubicación inicial
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _miUbicacion = LatLng(pos.latitude, pos.longitude);
    });

    // Hacer focus en el mapa
    _mapController.move(_miUbicacion!, 15);

    // Escuchar ubicación en tiempo real
    _posicionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // actualiza cada 5 metros
          ),
        ).listen((Position pos) {
          setState(() {
            _miUbicacion = LatLng(pos.latitude, pos.longitude);
          });
        });
  }

  Future<void> _buscar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? estado = prefs.getInt("estado");
      int? municipio = prefs.getInt("municipio");
      String? ruta = prefs.getString("ruta");
      await _cargarTracking(52, estado!, municipio!, ruta!);
    } catch (e) {
      print('Error al buscar: $e');
    }
  }

  Future<void> _obtenerParadasVirtuales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? estado = prefs.getInt("estado");
      int? municipio = prefs.getInt("municipio");
      String? ruta = prefs.getString("ruta");
      final paradas = await api.getRutaChecador(
        52,
        estado!,
        municipio!,
        ruta!,
        0,
      );

      setState(() {
        paradaVirtual = paradas;
      });
    } catch (e) {
      print('Error al buscar: $e');
    }
  }

  Future<void> _cargarTracking(
    int pais,
    int estado,
    int municipio,
    String ruta,
  ) async {
    try {
      final lista = await api.getRutaUnidadChecadorTracking(
        pais,
        estado,
        municipio,
        ruta,
      );
      /*setState(() {
        ubicaciones = lista;
      });*/

      // 🧠 Calcular activos e identificar capas WMS únicas
      final now = DateTime.now();
      final List<TrackingRutaUnidad> actualizadas = [];
      final Set<String> wmsLayersSet = {};

      for (final unidad in lista) {
        // Verificar tiempo y calcular "activo"
        bool activo = false;
        if (unidad.tiempo != null && unidad.tiempo!.isNotEmpty) {
          try {
            final dt = DateTime.parse(unidad.tiempo!);
            final diff = now.difference(dt);
            activo = diff.inSeconds <= 60;
          } catch (e) {
            activo = false;
          }
        }

        unidad.activo = activo;

        // Si tiene WMS válido, agregarlo al set
        if (unidad.wms != null &&
            unidad.wms!.isNotEmpty &&
            unidad.wms!.toLowerCase() != 'null') {
          wmsLayersSet.add(unidad.wms!);
        }

        actualizadas.add(unidad);
      }

      // 📦 Convertir Set a lista
      final wmsLayers = wmsLayersSet.toList();

      setState(() {
        ubicaciones = actualizadas;
        _wmsLayers = wmsLayers;

        for (int i = 0; i < _wmsLayers.length; i++) {
          final layer = _wmsLayers[i];
          _wmsSeleccionadas.putIfAbsent(layer, () => true);
          _wmsColores.putIfAbsent(
            layer,
            () => _coloresDisponibles[i % _coloresDisponibles.length],
          );
        }
      });
    } catch (e) {
      print('Error al obtener tracking: $e');
    }
  }

  void _mostrarSeleccionRutas() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Rutas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _wmsLayers.length,
                      itemBuilder: (context, index) {
                        final layer = _wmsLayers[index];
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _wmsColores[layer],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.black26),
                                ),
                              ),
                              Text("Ruta ${layer.split(':').last}"),
                            ],
                          ),
                          value: _wmsSeleccionadas[layer] ?? false,
                          onChanged: (value) {
                            setStateModal(() {
                              _wmsSeleccionadas[layer] = value ?? false;
                            });
                            setState(() {}); // actualiza el mapa
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParadaIcon(int tipo) {
    switch (tipo) {
      case 0:
        return const Icon(Icons.location_on, color: Colors.orange, size: 35);
      case 1:
        return const Icon(Icons.flag, color: Colors.green, size: 35);
      case 2:
        return const Icon(Icons.stop_circle, color: Colors.red, size: 35);
      default:
        return const Icon(Icons.place, color: Colors.grey, size: 35);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚍 Marcadores de unidades

    final markers = ubicaciones
        .where(
          (unidad) =>
              unidad.latitud != null &&
              unidad.longitud != null &&
              unidad.latitud!.isNotEmpty &&
              unidad.longitud!.isNotEmpty,
        )
        .map(
          (unidad) => Marker(
            point: LatLng(
              double.parse(unidad.latitud!),
              double.parse(unidad.longitud!),
            ),
            width: 80,
            height: 80,
            child: Column(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: unidad.activo! ? Colors.blue : Colors.red,
                  size: 35,
                ),
                Text(
                  "${unidad.ruta} - ${unidad.unidad}",
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
        )
        .toList();

    final paradaMarkers = paradaVirtual
        .where(
          (p) =>
              p.latitud != null &&
              p.longitud != null &&
              p.latitud!.isNotEmpty &&
              p.longitud!.isNotEmpty,
        )
        .map(
          (p) => Marker(
            point: LatLng(double.parse(p.latitud!), double.parse(p.longitud!)),
            width: 80,
            height: 80,
            child: Column(
              children: [
                _buildParadaIcon(p.tipo ?? 0),
                Text(
                  p.denominacion ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
        .toList();

    final allMarkers = [...markers, ...paradaMarkers];

    // 📍 Agrega marcador de tu ubicación actual
    if (_miUbicacion != null) {
      allMarkers.add(
        Marker(
          point: _miUbicacion!,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.person_pin_circle,
            color: Color.fromARGB(255, 0, 156, 151),
            size: 40,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa de Unidades',
          style: TextStyle(color: AppColors.greyTitle),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.greyTitle),
          onPressed: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CheckerPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers, color: AppColors.greyTitle),
            onPressed: _mostrarSeleccionRutas,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.greyTitle),
            onPressed: _buscar,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(19.4326, -99.1332), // CDMX
          initialZoom: 10,
        ),
        children: [
          TileLayer(urlTemplate: layer1, userAgentPackageName: 'com.combee.mx'),

          ..._wmsLayers
              .where((layerName) => _wmsSeleccionadas[layerName] ?? false)
              .map(
                (layerName) => TileLayer(
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl:
                        'https://mapas.siese.chiapas.gob.mx/geoserver/transporte/wms?',
                    layers: [layerName],
                    format: 'image/png',
                    transparent: true,
                    version: '1.3.0',
                    crs: const Epsg3857(),
                  ),
                  // Color semitransparente por capa (para distinguir)
                  tileBuilder: (context, widget, tile) {
                    final color = _wmsColores[layerName] ?? Colors.transparent;

                    return ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        color.withOpacity(1),
                        BlendMode.srcATop,
                      ),
                      child: widget,
                    );
                  },
                ),
              ),

          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              markers: allMarkers,
              zoomToBoundsOnClick: true,
              centerMarkerOnClick: true,
              builder: (context, clusterMarkers) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      clusterMarkers.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.my_location, color: AppColors.greyTitle),
        label: const Text(
          'Mi ubicación',
          style: TextStyle(color: AppColors.greyTitle),
        ),
        onPressed: () {
          if (_miUbicacion != null) {
            _mapController.move(_miUbicacion!, 16);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ubicación no disponible')),
            );
          }
        },
      ),
    );
  }
}
