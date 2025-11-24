/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:combeetracking/helper/databaseHelper.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/model/trackingrutaunidad.dart';


class MapaTrackingPage extends StatefulWidget {
  const MapaTrackingPage({Key? key}) : super(key: key);

  @override
  State<MapaTrackingPage> createState() => _MapaTrackingPageState();
}

class _MapaTrackingPageState extends State<MapaTrackingPage> {
  final MapController _mapController = MapController();
  String layer1 = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  String layer2 = 'http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  List<Map<String, dynamic>> resultados = [];
  List<TrackingRutaUnidad> ubicaciones = [];
  Timer? _timer;
  final AccountLocation api = AccountLocation();

  @override
  void initState() {
    super.initState();
    _buscar();
    _iniciarActualizacionPeriodica();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarActualizacionPeriodica() {
    // Cada 15 minutos
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _buscar();
    });
  }

  Future<void> _buscar() async {
    try {
      final data = await DatabaseHelper.instance.getAllUnidadConcesionario();

      final mapped =
          data?.map((item) {
            return {
              'ruta': item['ruta'] ?? '',
              'unidad': item['unidad'] ?? '',
              'municipio': item['idmunicipio'] ?? '',
              'estado': item['idestado'] ?? '',
              'pais': '52',
            };
          }).toList() ??
          [];

      setState(() {
        resultados = mapped;
      });

      await _cargarTracking(mapped);
    } catch (e) {
      print('Error al buscar: $e');
    }
  }

  Future<void> _cargarTracking(List<Map<String, dynamic>> resultado) async {
    try {
      final List<TrackingRutaUnidad> lista = await api.getRutaUnidadesTracking(
        resultado,
      );
      setState(() {
        ubicaciones = lista;
      });
    } catch (e) {
      print('Error al obtener tracking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = ubicaciones
        .where(
          (unidad) =>
              unidad.latitud != null &&
              unidad.longitud != null &&
              unidad.latitud!.isNotEmpty &&
              unidad.longitud!.isNotEmpty,
        )
        .map((unidad) {
          return Marker(
            point: LatLng(
              double.parse(unidad.latitud!),
              double.parse(unidad.longitud!),
            ),
            width: 60,
            height: 60,
            child: Column(
              children: [
                const Icon(Icons.directions_bus, color: Colors.blue, size: 35),
                Text(
                  unidad.unidad ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          );
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Unidades'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _buscar),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(19.4326, -99.1332), // CDMX
          initialZoom: 10,
        ),
        children: [
          TileLayer(
            urlTemplate: layer1,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName:
                'com.tuempresa.tuapp', // pon tu app id real aquí
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              markers: markers,
              zoomToBoundsOnClick:
                  true, // Ajusta el zoom al hacer clic en un cluster
              centerMarkerOnClick: true, // Centra el mapa al hacer clic
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
        icon: const Icon(Icons.location_searching),
        label: const Text('Actualizar'),
        onPressed: _buscar,
      ),
    );
  }
}
*/
// --- Mock clases para que compile el ejemplo ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';

import 'package:combeetracking/helper/databaseHelper.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/model/trackingrutaunidad.dart';
import 'package:combeetracking/views/concessionaire/route_filter_page.dart';

import '../../core/constants/constants.dart';

class MapaTrackingPage extends StatefulWidget {
  const MapaTrackingPage({Key? key}) : super(key: key);

  @override
  State<MapaTrackingPage> createState() => _MapaTrackingPageState();
}

class _MapaTrackingPageState extends State<MapaTrackingPage> {
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

  @override
  void initState() {
    super.initState();
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
      final data = await DatabaseHelper.instance.getAllUnidadConcesionario();
      final mapped =
          data
              ?.map(
                (item) => {
                  'ruta': item['ruta'] ?? '',
                  'unidad': item['unidad'] ?? '',
                  'municipio': item['idmunicipio'] ?? '',
                  'estado': item['idestado'] ?? '',
                  'pais': '52',
                },
              )
              .toList() ??
          [];

      setState(() {
        resultados = mapped;
      });

      await _cargarTracking(mapped);
    } catch (e) {
      print('Error al buscar: $e');
    }
  }

  Future<void> _cargarTracking(List<Map<String, dynamic>> resultado) async {
    try {
      final lista = await api.getRutaUnidadesTracking(resultado);
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

      //print('✅ Capas WMS detectadas: $_wmsLayers');
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

    // 📍 Agrega marcador de tu ubicación actual
    if (_miUbicacion != null) {
      markers.add(
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
        title: Row(
          mainAxisSize: MainAxisSize.min, // evita que ocupe todo el ancho
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppImages.logoPantallaAppBar, // tu imagen PNG
              height: 30, // ajusta tamaño
            ),
            const SizedBox(width: 8), // espacio entre imagen y texto
            Flexible(
              child: Text(
                'Mapa de Rutas',
                overflow: TextOverflow.ellipsis, // evita desbordamiento
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.greyTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.greyTitle),
          onPressed: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RouteFilterPage()),
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

          /*..._wmsLayers.map(
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
            ),
          ),*/
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
              markers: markers,
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
