import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:combee/helper/databaseHelper.dart';
import 'package:combee/http/http_location.dart';
import 'package:combee/model/rutachecador.dart';
import 'package:combee/model/trackingrutaunidad.dart';
import 'package:combee/views/home/components/hex_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:combee/views/configuration/configuration_page.dart';
import 'package:select2dot1/select2dot1.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/constants.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  SelectDataController? estadoController;
  SelectDataController? municipioController;

  bool loadingEstados = true;
  bool loadingMunicipios = false;
  bool municipioEnabled = false;

  int? selectedEstadoId;
  String? selectedEstadoName;

  int? selectedMunicipioId;
  String? selectedMunicipioName;

  final _formKey = GlobalKey<FormState>();

  int? idEstado;
  int? idMunicipio;
  bool cargando = true;

  @override
  void initState() {
    super.initState();

    //_buscar();
    //_iniciarActualizacionPeriodica();
    _iniciarUbicacion();
    _initLocationFlow();
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
      int? estado = 7;
      int? municipio = 102;
      String? ruta = "18";

      await _cargarTracking(52, estado!, municipio!, ruta!);
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
                  "${unidad.ruta} - ${unidad.unidad}",
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
    );
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
                      title: "Selecciona una ruta",
                      titleStyleDefault: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            HexButton(
              text: 'Buscar',
              textColor: Colors.black,
              heightButton: 20,
              widthButton: 200,
              colors: const [AppColors.primary, AppColors.primary],
              onTap: () {}, // _validarFormulario,
            ),
          ],
        ),
      ),
    );
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
                    color: AppColors.primary, //.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    /// IMPORTANTE: Card contiene header + tabs + contenido
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ====== HEADER ======
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  return IconButton(
                                    icon: const Icon(
                                      Icons.menu,
                                      color: AppColors.greyTitle,
                                    ),
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                  );
                                },
                              ),

                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Combee',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.greyTitle,
                                    ),
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
                            ],
                          ),
                        ),

                        // ====== TAB BAR ======
                        const TabBar(
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Tab(text: "Rutas"),
                            Tab(text: "Búsqueda por puntos"),
                          ],
                        ),

                        // ====== TAB CONTENT DENTRO DEL CARD ======
                        SizedBox(
                          height: 350, // puedes ajustar altura
                          child: TabBarView(
                            children: [
                              // TAB 1
                              _buildFormRuta(),

                              // TAB 2
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Contenido de búsqueda por puntos",
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
