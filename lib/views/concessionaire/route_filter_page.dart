import 'package:flutter/material.dart';
import 'package:combeetracking/helper/databaseHelper.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/views/auth/login_page.dart';
import 'package:combeetracking/views/concessionaire/tracking_map_concessionaire.dart';
import 'package:combeetracking/views/configuration/configuration_page.dart';
import 'package:select2dot1/select2dot1.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/constants.dart';

class RouteFilterPage extends StatefulWidget {
  const RouteFilterPage({super.key});

  @override
  State<RouteFilterPage> createState() => _RouteFilterPageState();
}

class _RouteFilterPageState extends State<RouteFilterPage> {
  // Controladores y estados existentes
  SelectDataController? estadoController;
  SelectDataController? municipioController;

  bool loadingEstados = true;
  bool loadingMunicipios = false;
  bool municipioEnabled = false;

  int? selectedEstadoId;
  int? selectedMunicipioId;
  int? idEstado;
  int? idMunicipio;

  final TextEditingController rutaController = TextEditingController();
  final TextEditingController unidadController = TextEditingController();

  List<Map<String, dynamic>> resultados = [];

  final AccountLocation api = AccountLocation();

  bool _expanded = false;

  @override
  void initState() {
    super.initState();

    municipioController = SelectDataController(
      data: [
        SingleCategoryModel(
          nameCategory: "Municipios",
          singleItemCategoryList: [],
        ),
      ],
      isMultiSelect: false,
    );
    _loadEstados();
    _buscar();
  }

  // ------------------ CARGAR ESTADOS ------------------
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

  // ------------------ ACCIONES DE BOTONES ------------------
  /*void _buscar() async {
    final data = await DatabaseHelper.instance.getAllUnidadConcesionario();

    final mapped =
        data?.map((item) {
          return {
            'ruta': item['ruta'] ?? '',
            'unidad': item['unidad'] ?? '',
            'municipio': item['municipio'] ?? '',
            'estado': item['estado'] ?? '',
          };
        }).toList() ??
        [];

    setState(() {
      resultados = mapped;
    });
  }*/

  void _buscar() async {
      final data = await DatabaseHelper.instance.getAllUnidadConcesionario();

      // Mapeo normal
      List<Map<String, dynamic>> mapped = data?.map((item) {
            return {
              'ruta': item['ruta'] ?? '',
              'unidad': item['unidad'] ?? '',
              'municipio': item['municipio'] ?? '',
              'estado': item['estado'] ?? '',
              'idestado': item['idestado'],
              'idmunicipio': item['idmunicipio'],
            };
          }).toList() ??
          [];

      // ---------------------- FILTROS ----------------------

      // FILTRO ESTADO
      if (selectedEstadoId != null) {
        mapped = mapped
            .where((e) => e['idestado'] == selectedEstadoId)
            .toList();
      }

      // FILTRO MUNICIPIO
      if (selectedMunicipioId != null) {
        mapped = mapped
            .where((e) => e['idmunicipio'] == selectedMunicipioId)
            .toList();
      }

      // FILTRO RUTA
      if (rutaController.text.isNotEmpty) {
        mapped = mapped
            .where((e) => e['ruta']
                .toString()
                .toLowerCase()
                .contains(rutaController.text.toLowerCase()))
            .toList();
      }

      // FILTRO UNIDAD
      if (unidadController.text.isNotEmpty) {
        mapped = mapped
            .where((e) => e['unidad']
                .toString()
                .toLowerCase()
                .contains(unidadController.text.toLowerCase()))
            .toList();
      }

      // Actualizamos
      setState(() {
        resultados = mapped;
      });
    }

    void _limpiar() {
      setState(() {
        // Limpiar campos de texto y variables de selección
        rutaController.clear();
        unidadController.clear();
        selectedEstadoId = null;
        selectedMunicipioId = null;

        // Si ya tenías cargados los "estados" en el controller, 
        // recreamos el controller con la misma data pero sin selección.
        if (estadoController != null) {
          final existingData = estadoController!.data;
          estadoController = SelectDataController(
            data: existingData,
            isMultiSelect: false,
          );
        }

        // Reiniciar municipios a vacío y deshabilitado
        municipioController = SelectDataController(
          data: [
            SingleCategoryModel(
              nameCategory: "Municipios",
              singleItemCategoryList: [],
            ),
          ],
          isMultiSelect: false,
        );
        municipioEnabled = false;

        // Limpiar resultados (se volverán a poblar en _buscar)
        resultados.clear();
      });

      // Volver a cargar la lista completa
      _buscar();
  }


  void _verMapa() {
    Navigator.pushNamed(context, '/mapa');
  }

  void _eliminarUnidad(
    int estado,
    int municipio,
    String ruta,
    String unidad,
  ) async {
    await DatabaseHelper.instance.deleteUnidadConcesionario(
      estado,
      municipio,
      ruta,
      unidad,
    );

    _buscar();
  }

  // ------------------ UI ------------------
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
              'Rutas Concesionario',
              style: TextStyle(
                color: AppColors.greyTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.greyTitle),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("isLogin", "false");

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.greyTitle),
            onPressed: () async {
              // Acción del botón
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ConfigurationPage(view: AppUser.concesionario),
                ),
              );

              if (result == true) {
                // Aquí recargas tu información, por ejemplo:
                setState(() {
                  // Llama tu función para refrescar datos
                  //cargarDatos();
                  _buscar();
                });
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---------- CARD DE FILTRO ----------
              /*
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Estado
                      if (loadingEstados || estadoController == null)
                        const Center(child: CircularProgressIndicator())
                      else
                        Select2dot1(
                          searchEmptyInfoModalSettings:
                              const SearchEmptyInfoModalSettings(
                                text: "No se encontraron resultados",
                              ),
                          searchEmptyInfoOverlaySettings:
                              const SearchEmptyInfoOverlaySettings(
                                text: "No se encontraron resultados",
                              ),

                          // 🔹 Texto del botón "Done" (cuando se elige)
                          doneButtonModalSettings:
                              const DoneButtonModalSettings(title: "Aceptar"),

                          // 🔹 Texto cuando no hay datos
                          selectEmptyInfoSettings:
                              const SelectEmptyInfoSettings(
                                text: "-- Seleccione --",
                              ),
                          selectDataController: estadoController!,
                          onChanged: (selectedItems) async {
                            final item = selectedItems.isNotEmpty
                                ? selectedItems.first
                                : null;
                            final id = int.tryParse(item?.value ?? "");

                            if (id != null) {
                              selectedEstadoId = id;
                              selectedMunicipioId = null; // reset
                              municipioEnabled = false;
                              municipioController = null; // limpia el select
                              setState(() {}); // actualiza el estado visual
                              await _loadMunicipios(id); // carga municipios
                            }
                          },
                          pillboxTitleSettings: const PillboxTitleSettings(
                            title: "Selecciona un estado",
                            titleStyleDefault: TextStyle(color: Colors.black),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ----------- SELECT MUNICIPIO -----------
                      Builder(
                        builder: (context) {
                          // 🔹 Si está cargando municipios
                          if (loadingMunicipios) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // 🔹 Si todavía no hay controlador (no se ha cargado nada)
                          if (municipioController == null) {
                            return IgnorePointer(
                              ignoring: true,
                              child: Opacity(
                                opacity: 0,
                                child: Select2dot1(
                                  // 🔹 Texto cuando no se encuentran resultados
                                  searchEmptyInfoModalSettings:
                                      const SearchEmptyInfoModalSettings(
                                        text: "No se encontraron resultados",
                                      ),
                                  searchEmptyInfoOverlaySettings:
                                      const SearchEmptyInfoOverlaySettings(
                                        text: "No se encontraron resultados",
                                      ),

                                  // 🔹 Texto del botón "Done" (cuando se elige)
                                  doneButtonModalSettings:
                                      const DoneButtonModalSettings(
                                        title: "Aceptar",
                                      ),

                                  // 🔹 Texto cuando no hay datos
                                  selectEmptyInfoSettings:
                                      const SelectEmptyInfoSettings(
                                        text: "-- Seleccione --",
                                      ),
                                  selectDataController: SelectDataController(
                                    data: [
                                      SingleCategoryModel(
                                        nameCategory: "Municipios",
                                        singleItemCategoryList: [],
                                      ),
                                    ],
                                  ),
                                  pillboxTitleSettings:
                                      const PillboxTitleSettings(
                                        titleStyleDefault: TextStyle(
                                          color: Colors.black,
                                        ),
                                        title: "Selecciona un municipio",
                                      ),
                                ),
                              ),
                            );
                          }

                          // 🔹 Si ya hay datos y está habilitado
                          return IgnorePointer(
                            ignoring: !municipioEnabled,
                            child: Opacity(
                              opacity: municipioEnabled ? 1.0 : 0.5,
                              child: Select2dot1(
                                // 🔹 Texto cuando no se encuentran resultados
                                searchEmptyInfoModalSettings:
                                    const SearchEmptyInfoModalSettings(
                                      text: "No se encontraron resultados",
                                    ),
                                searchEmptyInfoOverlaySettings:
                                    const SearchEmptyInfoOverlaySettings(
                                      text: "No se encontraron resultados",
                                    ),

                                // 🔹 Texto del botón "Done" (cuando se elige)
                                doneButtonModalSettings:
                                    const DoneButtonModalSettings(
                                      title: "Aceptar",
                                    ),

                                // 🔹 Texto cuando no hay datos
                                selectEmptyInfoSettings:
                                    const SelectEmptyInfoSettings(
                                      text: "-- Seleccione --",
                                    ),

                                selectDataController: municipioController!,
                                onChanged: (selectedItems) {
                                  final item = selectedItems.isNotEmpty
                                      ? selectedItems.first
                                      : null;
                                  selectedMunicipioId = int.tryParse(
                                    item?.value ?? '',
                                  );
                                },
                                pillboxTitleSettings:
                                    const PillboxTitleSettings(
                                      title: "Selecciona un municipio",
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Ruta y Unidad
                      TextField(
                        controller: rutaController,
                        decoration: const InputDecoration(
                          labelText: "Ruta",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.alt_route),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: unidadController,
                        decoration: const InputDecoration(
                          labelText: "Unidad",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_bus),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _buscar,
                            icon: const Icon(Icons.search),
                            label: const Text("Buscar"),
                          ),
                          OutlinedButton.icon(
                            onPressed: _limpiar,
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text("Limpiar"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),*/
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  // 🔹 Título visible cuando está cerrado
                  title: const Text(
                    "Filtros de búsqueda",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: const Icon(Icons.filter_alt, color: Colors.blue),
                  iconColor: Colors.blue,
                  collapsedIconColor: Colors.grey,
                  childrenPadding: const EdgeInsets.all(16),

                  initiallyExpanded: _expanded,

                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expanded = expanded;
                    });
                  },
                  children: [
                    // === Contenido original de tu filtro ===
                    if (loadingEstados || estadoController == null)
                      const Center(child: CircularProgressIndicator())
                    else
                      Select2dot1(
                        searchEmptyInfoModalSettings:
                            const SearchEmptyInfoModalSettings(
                              text: "No se encontraron resultados",
                              textStyle: TextStyle(color: Colors.black)
                            ),
                        searchEmptyInfoOverlaySettings:
                            const SearchEmptyInfoOverlaySettings(
                              text: "No se encontraron resultados",
                              textStyle: TextStyle(color: Colors.black)
                            ),
                        doneButtonModalSettings:
                            const DoneButtonModalSettings(title: "Aceptar"),
                        selectEmptyInfoSettings:
                            const SelectEmptyInfoSettings(
                              text: "-- Seleccione --",
                              textStyle: TextStyle(color: Colors.black)
                            ),
                        
                        selectDataController: estadoController!,
                        onChanged: (selectedItems) async {
                          final item = selectedItems.isNotEmpty
                              ? selectedItems.first
                              : null;
                          final id = int.tryParse(item?.value ?? "");
                          if (id != null) {
                            selectedEstadoId = id;
                            selectedMunicipioId = null;
                            municipioEnabled = false;
                            municipioController = null;
                            setState(() {});
                            await _loadMunicipios(id);
                          }
                        },
                        pillboxTitleSettings: const PillboxTitleSettings(
                          title: "Selecciona un estado",
                          titleStyleDefault: TextStyle(color: Colors.black),
                        ),
                      ),

                    const SizedBox(height: 16),

                    Builder(
                      builder: (context) {
                        if (loadingMunicipios) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (municipioController == null) {
                          return IgnorePointer(
                            ignoring: true,
                            child: Opacity(
                              opacity: 0,
                              child: Select2dot1(
                                searchEmptyInfoModalSettings:
                              const SearchEmptyInfoModalSettings(
                                text: "No se encontraron resultados",
                                textStyle: TextStyle(color: Colors.black)
                              ),
                          searchEmptyInfoOverlaySettings:
                              const SearchEmptyInfoOverlaySettings(
                                text: "No se encontraron resultados",
                                textStyle: TextStyle(color: Colors.black)
                              ),
                          doneButtonModalSettings:
                              const DoneButtonModalSettings(title: "Aceptar"),
                          selectEmptyInfoSettings:
                              const SelectEmptyInfoSettings(
                                text: "-- Seleccione --",
                                textStyle: TextStyle(color: Colors.black)
                              ),
                          
                                selectDataController: SelectDataController(
                                  data: [
                                    SingleCategoryModel(
                                      nameCategory: "Municipios",
                                      singleItemCategoryList: [],
                                    ),
                                  ],
                                ),
                                pillboxTitleSettings:
                                    const PillboxTitleSettings(
                                      titleStyleDefault: TextStyle(
                                        color: Colors.black,
                                      ),
                                      title: "Selecciona un municipio",
                                    ),
                              ),
                            ),
                          );
                        }

                        return IgnorePointer(
                          ignoring: !municipioEnabled,
                          child: Opacity(
                            opacity: municipioEnabled ? 1.0 : 0.5,
                            child: Select2dot1(
                              searchEmptyInfoModalSettings:
                                  const SearchEmptyInfoModalSettings(
                                    text: "No se encontraron resultados",
                                  ),
                              searchEmptyInfoOverlaySettings:
                                  const SearchEmptyInfoOverlaySettings(
                                    text: "No se encontraron resultados",
                                  ),
                              doneButtonModalSettings:
                                  const DoneButtonModalSettings(
                                    title: "Aceptar",
                                  ),
                              selectEmptyInfoSettings:
                                  const SelectEmptyInfoSettings(
                                    text: "-- Seleccione --",
                                  ),
                              selectDataController: municipioController!,
                              onChanged: (selectedItems) {
                                final item = selectedItems.isNotEmpty
                                    ? selectedItems.first
                                    : null;
                                selectedMunicipioId = int.tryParse(
                                  item?.value ?? '',
                                );
                              },
                              pillboxTitleSettings: const PillboxTitleSettings(
                                title: "Selecciona un municipio",
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: rutaController,
                      decoration: const InputDecoration(
                        labelText: "Ruta",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alt_route),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unidadController,
                      decoration: const InputDecoration(
                        labelText: "Unidad",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_bus),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _buscar,
                          icon: const Icon(Icons.search),
                          label: const Text("Buscar"),
                        ),
                        OutlinedButton.icon(
                          onPressed: _limpiar,
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text("Limpiar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------- LISTADO DE RESULTADOS ----------
              if (resultados.isEmpty)
                const Center(child: Text('No hay resultados'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resultados.length,
                  itemBuilder: (context, index) {
                    final item = resultados[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.directions_bus,
                          color: Colors.blue,
                        ),
                        title: Text('Ruta: ${item['ruta']}'),
                        subtitle: Text(
                          'Unidad: ${item['unidad']}\nMunicipio: ${item['municipio']}\nEstado: ${item['estado']}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "eliminar") {
                              _eliminarUnidad(
                                item['idestado'],
                                item['idmunicipio'],
                                item['ruta'],
                                item['unidad'],
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Quitar unidad'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Presionado");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MapaTrackingPage()),
          );
        },
        child: const Icon(Icons.map),
      ),
    );
  }
}
