import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:combee/helper/databaseHelper.dart';
import 'package:combee/http/http_location.dart';
import 'package:combee/model/direccion.dart';
import 'package:combee/model/ruta.dart';
import 'package:combee/model/rutachecador.dart';
import 'package:combee/model/trackingrutaunidad.dart';
import 'package:combee/views/home/components/hex_button.dart';
import 'package:combee/views/home/components/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:combee/views/configuration/configuration_page.dart';
import 'package:select2dot1/select2dot1.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

import '../../core/constants/constants.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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
  /*final List<Color> _coloresDisponibles = [
    Colors.brown,
    Colors.green,
    Colors.teal,
    Colors.purple,
    Colors.teal,
    Colors.black,
    Colors.deepPurpleAccent,
  ];*/

  // Reemplaza tu lista de colores disponibles con una más amplia
  final List<Color> _coloresDisponibles = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lime,
    Colors.brown,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.yellow,
  ];

  List<RutaChecador> paradaVirtual = [];

  SelectDataController? estadoController;
  SelectDataController? municipioController;

  SelectDataController? rutaController;

  bool loadingEstados = true;
  bool loadingMunicipios = false;
  bool loadingRutas = false;

  bool municipioEnabled = false;
  bool rutaEnabled = false;

  int? selectedEstadoId;
  String? selectedEstadoName;

  int? selectedMunicipioId;
  String? selectedMunicipioName;

  int? selectedRutaId;
  String? selectedRutaName;

  final _formKey = GlobalKey<FormState>();

  final _formKeyPoint = GlobalKey<FormState>();

  int? idEstado;
  int? idMunicipio;

  int? idRuta;
  bool cargando = true;

  late TabController _tabController;

  final ScrollController _scrollController = ScrollController();
  bool _showLeft = false;
  bool _showRight = true;

  bool _mostrarCard = true;

  final TextEditingController ubicacion1Controller = TextEditingController();
  final TextEditingController ubicacion2Controller = TextEditingController();

  late List<Ruta> _rutasCargadas = [];
  Ruta? selectedRuta;

  int totalRutas = 0;

  LatLng? _puntoOrigen;
  LatLng? _puntoDestino;

  LatLng? _puntoOrigenLast;
  LatLng? _puntoDestinoLast;

  String? _direccionOrigenLast;
  String? _direccionDestinoLast;

  Timer? _debounceOrigen;
  Timer? _debounceDestino;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() async {
      if (mounted) {
        /*if (_tabController.index == 0) {
          _cargarTracking();
          setState(() {
            _puntoOrigen = null;
            _puntoDestino = null;
            ubicacion1Controller.clear();
            ubicacion2Controller.clear();
          });
        } else {
          _stopActualizacionPeriodica();
          print(_puntoOrigenLast);
          setState(() {
            ubicaciones = [];
            _wmsLayers = [];
            resultados = [];

            _puntoOrigen = _puntoOrigenLast;
            _puntoDestino = _puntoDestinoLast;

            if (_direccionOrigenLast != null) {
              ubicacion1Controller.text = _direccionOrigenLast!;
            }

            if (_direccionDestinoLast != null) {
              ubicacion2Controller.text = _direccionDestinoLast!;
            }
          });
        }*/
        setState(() {});
      }
    });

    _scrollController.addListener(() {
      if (!mounted) return;

      setState(() {
        _showLeft = _scrollController.offset > 0;
        _showRight =
            _scrollController.offset <
            _scrollController.position.maxScrollExtent;
      });
    });

    //_buscar();
    //_iniciarActualizacionPeriodica();

    initConfig();
  }

  void _handleTabChange(int index) async {
    if (!mounted) return;

    if (index == 0) {
      // Volver al tab de Tracking
      _cargarTracking(); // async, pero no da problemas
      setState(() {
        _puntoOrigen = null;
        _puntoDestino = null;
        ubicacion1Controller.clear();
        ubicacion2Controller.clear();
      });
    } else {
      // Entrar al tab de Buscar
      _stopActualizacionPeriodica();

      setState(() {
        ubicaciones = [];
        _wmsLayers = [];
        resultados = [];

        _puntoOrigen = _puntoOrigenLast;
        _puntoDestino = _puntoDestinoLast;

        if (_direccionOrigenLast != null) {
          ubicacion1Controller.text = _direccionOrigenLast!;
        }

        if (_direccionDestinoLast != null) {
          ubicacion2Controller.text = _direccionDestinoLast!;
        }
      });
    }
  }

  void initConfig() async {
    await _checkPermission();
    await _initLocationFlow();
    await _iniciarUbicacion();
    await _cargarTracking();
  }

  void _asignarColoresWMS() {
    _wmsColores.clear();

    for (int i = 0; i < _wmsLayers.length; i++) {
      final layer = _wmsLayers[i];
      _wmsColores[layer] = _coloresDisponibles[i % _coloresDisponibles.length];

      // Si se acaban los colores únicos, generamos colores aleatorios
      if (i >= _coloresDisponibles.length) {
        _wmsColores[layer] = Color.fromRGBO(
          Random().nextInt(256),
          Random().nextInt(256),
          Random().nextInt(256),
          1.0,
        );
      }
    }
  }

  Future<void> _initLocationFlow() async {
    /*WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLogin(true);
    });*/

    final last = await DatabaseHelper.instance.getLastLocation();

    if (last != null) {
      idEstado = last['idestado'];
      idMunicipio = last['idmunicipio'];
      selectedEstadoName = last['estado'];
      selectedMunicipioName = last['municipio'];
    } else {
      bool permiso = await _checkPermission();

      if (permiso) {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final response = await api.getDataLocation(pos.latitude, pos.longitude);
        if (response.message == 1 && response.data != null) {
          idEstado = response.data!.idestado;
          idMunicipio = response.data!.idmunicipio;
          selectedEstadoName = response.data!.estado;
          selectedMunicipioName = response.data!.municipio;

          await DatabaseHelper.instance.insertLocation(
            idestado: idEstado!,
            estado: selectedEstadoName!,
            idmunicipio: idMunicipio!,
            municipio: selectedMunicipioName!,
          );
        }
      }
    }

    // Siempre cargamos estados desde la API
    await _loadEstados();

    // Luego, si tenemos un idEstado, cargamos municipios
    if (idEstado != null) {
      await _loadMunicipios(idEstado!);
    }

    if (idEstado != null && idMunicipio != null) {
      await _loadRutas(idEstado!, idMunicipio!);
    }

    setState(() => cargando = false);

    /*WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLogin(false);
    });*/
  }

  /// Carga todos los estados desde API
  Future<void> _loadEstados() async {
    final estados = await api.getState();

    final items = estados
        .map(
          (e) => SingleItemCategoryModel(
            nameSingleItem: e.estado ?? '',
            value: e.idestado.toString(),
          ),
        )
        .toList();

    // Si ya tenemos un idEstado detectado, lo preseleccionamos
    SingleItemCategoryModel? selectedEstadoItem;
    if (idEstado != null) {
      selectedEstadoItem = items.firstWhere(
        (item) => item.value == idEstado.toString(),
        orElse: () => items.first,
      );
      selectedEstadoId = int.tryParse(selectedEstadoItem.value);
    }

    estadoController = SelectDataController(
      data: [
        SingleCategoryModel(
          nameCategory: "Estados",
          singleItemCategoryList: items,
        ),
      ],
      isMultiSelect: false,
      initSelected: selectedEstadoItem != null ? [selectedEstadoItem] : null,
    );

    setState(() {
      loadingEstados = false;
    });
  }

  /// Carga municipios del estado seleccionado
  Future<void> _loadMunicipios(int idEstado) async {
    setState(() {
      loadingMunicipios = true;
      municipioEnabled = false;
    });

    final municipios = await api.getMunicipality(idEstado);

    final items = municipios
        .map(
          (m) => SingleItemCategoryModel(
            nameSingleItem: m.municipio ?? '',
            value: m.idmunicipio.toString(),
          ),
        )
        .toList();

    // Si ya tenemos un idMunicipio detectado, lo preseleccionamos
    SingleItemCategoryModel? selectedMunicipioItem;
    if (idMunicipio != null) {
      selectedMunicipioItem = items.firstWhere(
        (item) => item.value == idMunicipio.toString(),
        orElse: () => items.first,
      );
      selectedMunicipioId = int.tryParse(selectedMunicipioItem.value);
    }

    municipioController = SelectDataController(
      data: [
        SingleCategoryModel(
          nameCategory: "Municipios",
          singleItemCategoryList: items,
        ),
      ],
      isMultiSelect: false,
      initSelected: selectedMunicipioItem != null
          ? [selectedMunicipioItem]
          : null,
    );

    setState(() {
      loadingMunicipios = false;
      municipioEnabled = true;
    });
  }

  Future<void> _loadRutas(int idEstado, int idMunicipio) async {
    setState(() {
      loadingRutas = true;
      rutaEnabled = false;
    });

    final rutas = await api.getRouteByStateMunicipality(idEstado, idMunicipio);

    _rutasCargadas = rutas;

    final items = rutas
        .map(
          (m) => SingleItemCategoryModel(
            nameSingleItem: m.ruta ?? '',
            value: m.idruta.toString(),
          ),
        )
        .toList();

    // Si ya tenemos un idMunicipio detectado, lo preseleccionamos
    SingleItemCategoryModel? selectedRutaItem;
    if (idRuta != null) {
      selectedRutaItem = items.firstWhere(
        (item) => item.value == idRuta.toString(),
        orElse: () => items.first,
      );
      selectedRutaId = int.tryParse(selectedRutaItem.value);
    }

    rutaController = SelectDataController(
      data: [
        SingleCategoryModel(
          nameCategory: "Rutas",
          singleItemCategoryList: items,
        ),
      ],
      isMultiSelect: false,
      initSelected: selectedRutaItem != null ? [selectedRutaItem] : null,
    );

    setState(() {
      loadingRutas = false;
      rutaEnabled = true;
    });
  }

  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounceOrigen?.cancel();
    _debounceDestino?.cancel();
    _posicionSub?.cancel();
    super.dispose();
  }

  void _iniciarActualizacionPeriodica() {
    if (_timer?.isActive ?? false) return;

    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _cargarTracking();
    });
  }

  void _stopActualizacionPeriodica() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null; // opcional pero recomendable
    }
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
      if (selectedRuta == null) return;

      final String? wms = selectedRuta!.wms;

      await DatabaseHelper.instance.insertRutas(
        idestado: idEstado!,
        estado: selectedEstadoName!,
        idmunicipio: idMunicipio!,
        municipio: selectedMunicipioName!,
        idruta: idRuta!,
        ruta: selectedRutaName!,
        wms: wms!,
      );

      await _cargarTracking();

      //_iniciarActualizacionPeriodica();
    } catch (e) {
      print('Error al buscar: $e');
    }
  }

  Future<void> _cargarTracking() async {
    try {
      final data = await DatabaseHelper.instance.getRutasSaveInDatabase();

      totalRutas = data.length;

      final Set<String> wmsLayersSet = {};

      final mapped =
          data?.map((item) {
            return {
              'ruta': item['ruta'] ?? '',
              'municipio': item['idmunicipio'] ?? '',
              'estado': item['idestado'] ?? '',
              'pais': '52',
            };
          }).toList() ??
          [];

      final mapped_wms =
          data?.map((item) {
            return {'wms': item['wms'] ?? ''};
          }).toList() ??
          [];

      for (final item in mapped_wms) {
        final wms = item['wms']?.toString() ?? '';

        if (wms.isNotEmpty && wms.toLowerCase() != 'null') {
          wmsLayersSet.add(wms);
        }
      }

      print("WMS desde DB: $wmsLayersSet");

      /*setState(() {
        resultados = mapped;
      });*/

      final lista = await api.getRutaUnidadTracking(mapped);
      /*setState(() {
        ubicaciones = lista;
      });*/

      // 🧠 Calcular activos e identificar capas WMS únicas
      final now = DateTime.now();
      final List<TrackingRutaUnidad> actualizadas = [];

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
        /*if (unidad.wms != null &&
            unidad.wms!.isNotEmpty &&
            unidad.wms!.toLowerCase() != 'null') {
          wmsLayersSet.add(unidad.wms!);
        }*/

        actualizadas.add(unidad);
      }

      // 📦 Convertir Set a lista
      final wmsLayers = wmsLayersSet.toList();

      setState(() {
        ubicaciones = actualizadas;
        _wmsLayers = wmsLayers;
        resultados = mapped;

        /*
        for (int i = 0; i < _wmsLayers.length; i++) {
          final layer = _wmsLayers[i];
          _wmsSeleccionadas.putIfAbsent(layer, () => true);
          _wmsColores.putIfAbsent(
            layer,
            () => _coloresDisponibles[i % _coloresDisponibles.length],
          );
        }
        */

        for (final layer in _wmsLayers) {
          _wmsSeleccionadas.putIfAbsent(layer, () => true);
        }

        // Asignar colores únicos
        _asignarColoresWMS();
      });

      print("Colores asignados:");
      _wmsColores.forEach((key, value) {
        print("$key  ->  $value");
      });

      if (totalRutas != 0) {
        _iniciarActualizacionPeriodica();
      }
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

  Widget _buildMapa() {
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
                  "${unidad.ruta}",
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
        )
        .toList();

    final allMarkers = [...markers];

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

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(19.4326, -99.1332),
        initialZoom: 10,
        onTap: (_, latlng) async {
          if (_tabController.index != 1) return;

          // ----- LÓGICA PARA AGREGAR MARCADORES -----

          final tieneOrigen = _puntoOrigen != null;
          final tieneDestino = _puntoDestino != null;

          if (!tieneOrigen) {
            // Primer clic → ORIGEN
            setState(() => _puntoOrigen = latlng);

            _puntoOrigenLast = _puntoOrigen;

            await _actualizarDireccionDesdeMapa(latlng, ubicacion1Controller);

            _puntoOrigenLast = _puntoOrigen;
            _direccionOrigenLast = ubicacion1Controller.text;
            return;
          }

          if (!tieneDestino) {
            // Segundo clic → DESTINO
            setState(() => _puntoDestino = latlng);

            _puntoDestinoLast = _puntoDestino;

            _actualizarDireccionDesdeMapa(latlng, ubicacion2Controller);

            _puntoDestinoLast = _puntoDestino;
            _direccionDestinoLast = ubicacion2Controller.text;
            return;
          }

          // Si ya hay 2 → mover DESTINO
          setState(() => _puntoDestino = latlng);
          await _actualizarDireccionDesdeMapa(latlng, ubicacion2Controller);
          _puntoDestinoLast = _puntoDestino;
          _direccionDestinoLast = ubicacion2Controller.text;
        },
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
        DragMarkers(
          markers: [
            if (_puntoOrigen != null)
              DragMarker(
                point: _puntoOrigen!,
                size: const Size(80, 80), // ⬅️ Aquí en vez de width/height
                builder: (context, point, isDragging) => const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
                onDragEnd: (details, newPoint) async {
                  setState(() => _puntoOrigen = newPoint);
                  await _actualizarDireccionDesdeMapa(
                    newPoint,
                    ubicacion1Controller,
                  );

                  _puntoOrigenLast = _puntoOrigen;
                  _direccionOrigenLast = ubicacion1Controller.text;
                },
              ),

            if (_puntoDestino != null)
              DragMarker(
                point: _puntoDestino!,
                size: const Size(80, 80),
                builder: (context, point, isDragging) => const Icon(
                  Icons.location_on,
                  color: Colors.purple,
                  size: 40,
                ),
                onDragEnd: (details, newPoint) async {
                  setState(() => _puntoDestino = newPoint);
                  await _actualizarDireccionDesdeMapa(
                    newPoint,
                    ubicacion2Controller,
                  );

                  _puntoDestinoLast = _puntoDestino;
                  _direccionDestinoLast = ubicacion2Controller.text;
                },
              ),
          ],
        ),
        MarkerLayer(markers: allMarkers),
      ],
    );
  }

  double get cardHeight {
    return _mostrarCard ? 430 : 30;
  }

  Widget _flechaIzquierda() {
    return Container(
      width: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: const Icon(Icons.chevron_left, size: 28),
    );
  }

  Widget _flechaDerecha() {
    return Container(
      width: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.0)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
      ),
      child: const Icon(Icons.chevron_right, size: 28),
    );
  }

  _deleteRutaResultado(int estado, int municipio, String ruta) async {
    await DatabaseHelper.instance.deleteRuta(estado, municipio, ruta);

    _cargarTracking();
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== HEADER =====
            /*DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.directions_bus,
                    size: 48,
                    color: AppColors.greyTitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Combee",
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.greyTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),*/

            // ===== OPCIONES =====
            ListTile(
              leading: const Icon(Icons.map, color: Colors.black87),
              title: const Text("Políticas de privacidad"),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.route, color: Colors.black87),
              title: const Text("Denuncias"),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black87),
              title: const Text("Configuración"),
              onTap: () => Navigator.pop(context),
            ),

            const Spacer(),

            /*ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // lógica de logout
              },
            ),
            const SizedBox(height: 10),*/
          ],
        ),
      ),
    );
  }

  Widget _buildFormRuta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loadingEstados || estadoController == null)
              const Center(child: CircularProgressIndicator())
            else
              Select2dot1(
                searchEmptyInfoModalSettings:
                    const SearchEmptyInfoModalSettings(
                      text: "No se encontraron resultados",
                      textStyle: TextStyle(color: Colors.black),
                    ),
                searchEmptyInfoOverlaySettings:
                    const SearchEmptyInfoOverlaySettings(
                      text: "No se encontraron resultados",
                      textStyle: TextStyle(color: Colors.black),
                    ),
                doneButtonModalSettings: const DoneButtonModalSettings(
                  title: "Aceptar",
                ),
                selectEmptyInfoSettings: const SelectEmptyInfoSettings(
                  text: "-- Seleccione --",
                  textStyle: TextStyle(color: Colors.black),
                ),

                selectDataController: estadoController!,

                onChanged: (selectedItems) async {
                  final item = selectedItems.isNotEmpty
                      ? selectedItems.first
                      : null;
                  final id = int.tryParse(item?.value ?? "");
                  final selectEstadoName = item?.nameSingleItem;

                  if (id != null) {
                    selectedEstadoId = id;
                    idEstado = selectedEstadoId;
                    selectedEstadoName = selectEstadoName;
                    idMunicipio = null;
                    await _loadMunicipios(id);
                  }
                },
                pillboxTitleSettings: const PillboxTitleSettings(
                  title: "Selecciona un estado",
                  titleStyleDefault: TextStyle(color: Colors.black),
                ),
              ),

            const SizedBox(height: 10),

            // ----------- SELECT MUNICIPIO -----------
            if (loadingMunicipios || municipioController == null)
              const Center(child: CircularProgressIndicator())
            else
              IgnorePointer(
                ignoring: !municipioEnabled,
                child: Opacity(
                  opacity: municipioEnabled ? 1.0 : 0.5,
                  child: Select2dot1(
                    searchEmptyInfoModalSettings:
                        const SearchEmptyInfoModalSettings(
                          text: "No se encontraron resultados",
                          textStyle: TextStyle(color: Colors.black),
                        ),
                    searchEmptyInfoOverlaySettings:
                        const SearchEmptyInfoOverlaySettings(
                          text: "No se encontraron resultados",
                          textStyle: TextStyle(color: Colors.black),
                        ),
                    doneButtonModalSettings: const DoneButtonModalSettings(
                      title: "Aceptar",
                    ),
                    selectEmptyInfoSettings: const SelectEmptyInfoSettings(
                      text: "-- Seleccione --",
                      textStyle: TextStyle(color: Colors.black),
                    ),

                    selectDataController: municipioController!,
                    onChanged: (selectedItems) {
                      final item = selectedItems.isNotEmpty
                          ? selectedItems.first
                          : null;
                      selectedMunicipioId = int.tryParse(item?.value ?? '');

                      idMunicipio = selectedMunicipioId;

                      selectedMunicipioName = item?.nameSingleItem;
                    },
                    pillboxTitleSettings: const PillboxTitleSettings(
                      title: "Selecciona un municipio",
                      titleStyleDefault: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 10),
            // ----------- SELECT MUNICIPIO -----------
            if (loadingRutas || rutaController == null)
              const Center(child: CircularProgressIndicator())
            else
              IgnorePointer(
                ignoring: !rutaEnabled,
                child: Opacity(
                  opacity: rutaEnabled ? 1.0 : 0.5,
                  child: Select2dot1(
                    searchEmptyInfoModalSettings:
                        const SearchEmptyInfoModalSettings(
                          text: "No se encontraron resultados",
                          textStyle: TextStyle(color: Colors.black),
                        ),
                    searchEmptyInfoOverlaySettings:
                        const SearchEmptyInfoOverlaySettings(
                          text: "No se encontraron resultados",
                          textStyle: TextStyle(color: Colors.black),
                        ),
                    doneButtonModalSettings: const DoneButtonModalSettings(
                      title: "Aceptar",
                    ),
                    selectEmptyInfoSettings: const SelectEmptyInfoSettings(
                      text: "-- Seleccione --",
                      textStyle: TextStyle(color: Colors.black),
                    ),

                    selectDataController: rutaController!,
                    onChanged: (selectedItems) {
                      final item = selectedItems.isNotEmpty
                          ? selectedItems.first
                          : null;
                      selectedRutaId = int.tryParse(item?.value ?? '');

                      idRuta = selectedRutaId;

                      selectedRutaName = item?.nameSingleItem;

                      selectedRuta = _rutasCargadas.firstWhere(
                        (r) => r.idruta == selectedRutaId,
                        orElse: () => Ruta(),
                      );
                    },
                    pillboxTitleSettings: const PillboxTitleSettings(
                      title: "Selecciona una ruta",
                      titleStyleDefault: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            RoundedButton(
              text: 'Buscar',
              textColor: Colors.black,
              heightButton: 40,
              widthButton: 200,
              colors: const [AppColors.primary, AppColors.primary],
              onTap: _validarFormulario,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actualizarDireccionDesdeMapa(
    LatLng punto,
    TextEditingController controller,
  ) async {
    // Aquí llamas tu API para obtener la dirección
    /*final direccion = await api.getReverseGeocode(
      punto.latitude,
      punto.longitude,
    );

    setState(() {
      controller.text = direccion ?? "Dirección desconocida";
    });*/

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        punto.latitude,
        punto.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final direccion = "${place.street} ${place.locality}, ${place.country}";

        setState(() {
          controller.text = direccion;
        });
      }
    } catch (e) {
      setState(() {
        controller.text = "Dirección no encontrada";
      });
    }
  }

  Widget _buildFormRutaPoint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),

      child: Form(
        key: _formKeyPoint,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ------------------------------ ORIGEN ------------------------------
            TypeAheadField<Direccion>(
              controller: ubicacion1Controller,
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) return [];

                // ---- DEBOUNCE ----
                if (_debounceOrigen?.isActive ?? false)
                  _debounceOrigen!.cancel();

                final completer = Completer<List<Direccion>>();

                _debounceOrigen = Timer(
                  const Duration(milliseconds: 500),
                  () async {
                    final result = await api.getAddressPoint(
                      pattern.toLowerCase(),
                    );
                    completer.complete(result);
                  },
                );

                return completer.future;
              },
              builder: (context, controller, focusNode) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: "¿Dónde tomarás la ruta?",
                  prefixIcon: Icon(Icons.location_on, color: Colors.green),
                  border: OutlineInputBorder(),
                ),
              ),
              itemBuilder: (context, Direccion suggestion) {
                return ListTile(
                  leading: const Icon(Icons.place, color: Colors.green),
                  title: Text(suggestion.direccion ?? ''),
                );
              },
              onSelected: (Direccion selected) {
                ubicacion1Controller.text = selected.direccion ?? "";
                setState(() {
                  _puntoOrigen = LatLng(
                    double.parse(selected.latitud!),
                    double.parse(selected.longitud!),
                  );
                  _puntoOrigenLast = _puntoOrigen;
                  _direccionOrigenLast = selected.direccion;
                });
                _mapController.move(_puntoOrigen!, 16);
              },
            ),

            const SizedBox(height: 30),

            // ------------------------------ DESTINO ------------------------------
            TypeAheadField<Direccion>(
              controller: ubicacion2Controller,
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty) return [];

                // ---- DEBOUNCE ----
                if (_debounceDestino?.isActive ?? false)
                  _debounceDestino!.cancel();

                final completer = Completer<List<Direccion>>();

                _debounceDestino = Timer(
                  const Duration(milliseconds: 500),
                  () async {
                    final result = await api.getAddressPoint(
                      pattern.toLowerCase(),
                    );
                    completer.complete(result);
                  },
                );

                return completer.future;
              },
              builder: (context, controller, focusNode) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: "¿Dónde irás?",
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Colors.purple,
                  ),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple, width: 2),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Campo requerido" : null,
              ),
              itemBuilder: (context, Direccion suggestion) {
                return ListTile(
                  leading: const Icon(Icons.place, color: Colors.purple),
                  title: Text(suggestion.direccion ?? ''),
                );
              },
              onSelected: (Direccion selected) async {
                ubicacion2Controller.text = selected.direccion ?? "";

                setState(() {
                  _puntoDestino = LatLng(
                    double.parse(selected.latitud!),
                    double.parse(selected.longitud!),
                  );
                  _puntoDestinoLast = _puntoDestino;
                  _direccionDestinoLast = selected.direccion;
                });

                _mapController.move(_puntoDestino!, 16);
              },
            ),

            const SizedBox(height: 30),

            RoundedButton(
              text: 'Buscar',
              textColor: Colors.black,
              heightButton: 40,
              widthButton: 200,
              colors: const [AppColors.primary, AppColors.primary],
              onTap: _validarFormularioPuntos,
            ),
          ],
        ),
      ),
    );
  }

  void _validarFormulario() {
    final form = _formKey.currentState!;
    final estadoSeleccionado = selectedEstadoId != null;
    final municipioSeleccionado = selectedMunicipioId != null;
    final rutaSeleccionado = selectedRutaId != null;

    if (!estadoSeleccionado || !municipioSeleccionado || !rutaSeleccionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Selecciona un estado, un municipio y una ruta antes de continuar.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (form.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Formulario válido ✅")));

      _buscar();
    }
  }

  void _validarFormularioPuntos() {
    final formPoint = _formKeyPoint.currentState!;

    if (formPoint.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Formulario válido ✅")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: _buildDrawer(context),

        body: Stack(
          children: [
            /// MAPA A PANTALLA COMPLETA
            Positioned.fill(child: _buildMapa()),

            /// CARD FLOTANTE CON BLUR + CONTENIDO COMPLETO
            Positioned(
              top: 30,
              left: 15,
              right: 15,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Card(
                    elevation: 6,
                    color: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HEADER
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: AppColors.greyTitle,
                                  ),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                              ),

                              Expanded(
                                child: Center(
                                  child: Image.asset(
                                    AppImages.logoAppSinSlogan,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.layers,
                                  color: AppColors.greyTitle,
                                ),
                                onPressed: _mostrarSeleccionRutas,
                              ),

                              // << ESTE ES EL BOTÓN PARA MOSTRAR/OCULTAR >>
                              IconButton(
                                icon: Icon(
                                  _mostrarCard
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.greyTitle,
                                ),
                                onPressed: () {
                                  setState(() => _mostrarCard = !_mostrarCard);
                                },
                              ),
                            ],
                          ),
                        ),

                        // TABBAR + CONTENIDO, OCULTABLE
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 250),
                          child: _mostrarCard
                              ? Column(
                                  key: ValueKey(true),
                                  children: [
                                    TabBar(
                                      controller: _tabController,
                                      labelColor: Colors.black,
                                      onTap: (index) {
                                        _handleTabChange(index);
                                      },
                                      unselectedLabelColor: Colors.grey,
                                      tabs: [
                                        Tab(text: "Rutas"),
                                        Tab(text: "¿A dónde vas?"),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 350,

                                      child: TabBarView(
                                        controller: _tabController,
                                        children: [
                                          _buildFormRuta(),
                                          _buildFormRutaPoint(),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(key: ValueKey(false)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (_tabController.index == 0)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 30 + cardHeight + 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 65,
                  child: Stack(
                    children: [
                      // LISTVIEW
                      ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        itemCount: resultados.length,
                        itemBuilder: (context, index) {
                          final item = resultados[index];
                          final rutaNumero = item['ruta']?.toString() ?? '';

                          // Buscar la capa WMS correspondiente a esta ruta
                          String? wmsLayer;
                          for (final layer in _wmsLayers) {
                            if (layer.contains(rutaNumero)) {
                              wmsLayer = layer;
                              break;
                            }
                          }

                          // Obtener el color asignado a esta capa WMS
                          final color = wmsLayer != null
                              ? _wmsColores[wmsLayer]
                              : Colors.grey;

                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InputChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Indicador de color
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black38,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "RUTA $rutaNumero",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.white,
                              elevation: 3,
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                _deleteRutaResultado(
                                  item['estado'],
                                  item['municipio'],
                                  item['ruta'],
                                );
                              },
                            ),
                          );
                        },
                      ),

                      if (_showLeft)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: _flechaIzquierda(),
                        ),

                      if (_showRight)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: _flechaDerecha(),
                        ),
                    ],
                  ),
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
      ),
    );
  }
}
