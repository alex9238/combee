import 'package:combeetracking/views/home/components/hex_button.dart';
import 'package:flutter/material.dart';
import 'package:combeetracking/core/themes/app_themes.dart';

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:combeetracking/helper/databaseHelper.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/views/checker/checker_page.dart';
import 'package:combeetracking/views/checker/checker_select_page.dart';
import 'package:combeetracking/views/tracking/tracking_page.dart';
import 'package:select2dot1/select2dot1.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/constants.dart';

class ConfigurationPageForm extends StatefulWidget {
  final Function(bool) onLogin; // Recibimos el callback
  final Function(bool) onChange; // Recibimos el callback hubo cambios
  final String view; // Recibimos el callback

  const ConfigurationPageForm({
    super.key,
    required this.onLogin,
    required this.view,
    required this.onChange,
  });

  @override
  State<ConfigurationPageForm> createState() => _ConfigurationPageFormState();
}

class _ConfigurationPageFormState extends State<ConfigurationPageForm> {
  final AccountLocation api = AccountLocation();

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
  final TextEditingController rutaController = TextEditingController();
  final TextEditingController unidadController = TextEditingController();

  int? idEstado;
  int? idMunicipio;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _loadConfigurationView();
  }

  _loadConfigurationView() async {
    if (widget.view == AppUser.checador) {
      print("checar checador");
      if (await _checkChecador()) {
        return;
      }
    } else if (widget.view == AppUser.concesionario) {
      /*if (await _checkChecador()) {
        return;
      }*/
    }

    _initLocationFlow();
  }

  Future<void> _initLocationFlow() async {


    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLogin(true);
    });

    final last;

    if (widget.view == AppUser.chofer) {
      last = await DatabaseHelper.instance.getLastLocation();
    } else if (widget.view == AppUser.concesionario) {
      last = await DatabaseHelper.instance.getLastLocationConcesionario();
    } else {
      last = await DatabaseHelper.instance.getLastLocationChecador();
    }

    if (last != null) {
      idEstado = last['idestado'];
      idMunicipio = last['idmunicipio'];
      selectedEstadoName = last['estado'];
      selectedMunicipioName = last['municipio'];

      if (widget.view == AppUser.chofer) {
        rutaController.text = last['ruta'];
        unidadController.text = last['unidad'];
      } else {
        rutaController.text = last['ruta'];
      }
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


    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLogin(false);
    });
    
  }

  Future<bool> _checkChecador() async {
    final prefs = await SharedPreferences.getInstance();

    // Comprobamos si la clave existe
    final exists = prefs.containsKey("check");

    if (exists) {
      bool? value = prefs.getBool(
        "check",
      ); // o getString, según cómo la guardaste
      print("✅ 'isChecker' existe. Valor: $value");

      if (value!) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckerPage()),
        );

        return true;
      }
    } else {
      print("⚠️ 'isChecker' no existe en SharedPreferences.");
    }

    return false;
  }

  Future<void> _guardarDatos() async {
    if (_formKey.currentState!.validate()) {
      if (idEstado != null && idMunicipio != null) {
        widget.onLogin(true);
        await DatabaseHelper.instance.insertLocation(
          idestado: idEstado!,
          estado: selectedEstadoName!,
          idmunicipio: idMunicipio!,
          municipio: selectedMunicipioName!,
          ruta: rutaController.text,
          unidad: unidadController.text,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt("estado", idEstado!);
        await prefs.setInt("municipio", idMunicipio!);
        await prefs.setString("ruta", rutaController.text);
        await prefs.setString("unidad", unidadController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Datos guardados correctamente")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TrackingPage()),
        );

        widget.onLogin(false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debe seleccionar estado y municipio")),
        );
      }
    }
  }

  Future<void> _guardarDatosConcesionario() async {
    if (_formKey.currentState!.validate()) {
      if (idEstado != null && idMunicipio != null) {
        widget.onLogin(true);

        await DatabaseHelper.instance.insertRutaConcesionario(
          idestado: idEstado!,
          estado: selectedEstadoName!,
          idmunicipio: idMunicipio!,
          municipio: selectedMunicipioName!,
          ruta: rutaController.text,
          unidad: unidadController.text,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt("estado", idEstado!);
        await prefs.setInt("municipio", idMunicipio!);
        await prefs.setString("ruta", rutaController.text);
        await prefs.setString("unidad", unidadController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Datos guardados correctamente")),
        );

        widget.onChange(true);

        widget.onLogin(false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debe seleccionar estado y municipio")),
        );
      }
    }
  }

  Future<void> _guardarChecador() async {
    if (_formKey.currentState!.validate()) {
      print("estado ${idEstado}");

      if (idEstado != null && idMunicipio != null) {
        widget.onLogin(true);
        await DatabaseHelper.instance.insertRutaChecador(
          idestado: idEstado!,
          estado: selectedEstadoName!,
          idmunicipio: idMunicipio!,
          municipio: selectedMunicipioName!,
          ruta: rutaController.text,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt("estado", idEstado!);
        await prefs.setInt("municipio", idMunicipio!);
        await prefs.setString("ruta", rutaController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Datos guardados correctamente")),
        );

        /*await prefs.setBool("check", true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CheckerPage()),
        );*/

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CheckerSelectPage()),
        );

        widget.onLogin(false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debe seleccionar estado y municipio")),
        );
      }
    }
  }

  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
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

  void _validarFormulario() {
    final form = _formKey.currentState!;
    final estadoSeleccionado = selectedEstadoId != null;
    final municipioSeleccionado = selectedMunicipioId != null;

    if (!estadoSeleccionado || !municipioSeleccionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Selecciona un estado y un municipio antes de continuar.",
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
      if (widget.view == AppUser.chofer) {
        _guardarDatos();
      } else if (widget.view == AppUser.concesionario) {
        _guardarDatosConcesionario();
      } else {
        _guardarChecador();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.defaultTheme.copyWith(
        inputDecorationTheme: AppTheme.secondaryInputDecorationTheme,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppImages.logoApp, height: 120),

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
                          ),
                        ),

                      const SizedBox(height: 20),

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
                          
                              selectDataController: municipioController!,
                              onChanged: (selectedItems) {
                                final item = selectedItems.isNotEmpty
                                    ? selectedItems.first
                                    : null;
                                selectedMunicipioId = int.tryParse(
                                  item?.value ?? '',
                                );

                                idMunicipio = selectedMunicipioId;

                                selectedMunicipioName = item?.nameSingleItem;
                              },
                              pillboxTitleSettings: const PillboxTitleSettings(
                                title: "Selecciona un municipio",
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),
                      //const SizedBox(height: 24),
                      TypeAheadField<Map<String, dynamic>>(
                        controller: rutaController,
                        suggestionsCallback: (pattern) async {
                          if (idEstado == null ||
                              idMunicipio == null ||
                              pattern.isEmpty)
                            return [];

                          final rutas;
                          if (widget.view == AppUser.chofer) {
                            rutas = await DatabaseHelper.instance
                                .getRutasSaveInDatabase(
                                  estado: idEstado!,
                                  municipio: idMunicipio!,
                                );
                          } else if (widget.view == AppUser.concesionario) {
                            rutas = await DatabaseHelper.instance
                                .getRutasConcesionarioSaveInDatabase(
                                  estado: idEstado!,
                                  municipio: idMunicipio!,
                                );
                          } else {
                            rutas = await DatabaseHelper.instance
                                .getRutasSaveInDatabase(
                                  estado: idEstado!,
                                  municipio: idMunicipio!,
                                );
                          }

                          return rutas
                              .where(
                                (r) => r['ruta']
                                    .toString()
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()),
                              )
                              .toList();
                        },
                        builder: (context, controller, focusNode) =>
                            TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: "Ruta",
                                prefixIcon: Icon(Icons.alt_route),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? "Campo requerido"
                                  : null,
                            ),
                        itemBuilder:
                            (context, Map<String, dynamic> suggestion) {
                              return ListTile(
                                leading: const Icon(Icons.directions),
                                title: Text(suggestion['ruta'] ?? ''),
                              );
                            },
                        onSelected: (suggestion) async {
                          rutaController.text = suggestion['ruta'];
                          final unidades = await DatabaseHelper.instance
                              .getUnidadSaveInDatabase(
                                estado: idEstado!,
                                municipio: idMunicipio!,
                                ruta: suggestion['ruta'],
                              );
                          if (unidades.isNotEmpty) {
                            unidadController.text =
                                unidades.first['unidad'] ?? '';
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      if (widget.view != AppUser.checador)
                        ?TypeAheadField<Map<String, dynamic>>(
                          controller: unidadController,
                          suggestionsCallback: (pattern) async {
                            if (idEstado == null ||
                                idMunicipio == null ||
                                rutaController.text.isEmpty ||
                                pattern.isEmpty)
                              return [];
                            /*final unidades = await DatabaseHelper.instance
                              .getUnidadSaveInDatabase(
                                estado: idEstado!,
                                municipio: idMunicipio!,
                                ruta: rutaController.text,
                              );*/

                            final unidades;
                            if (widget.view == AppUser.chofer) {
                              unidades = await await DatabaseHelper.instance
                                  .getUnidadSaveInDatabase(
                                    estado: idEstado!,
                                    municipio: idMunicipio!,
                                    ruta: rutaController.text,
                                  );
                            } else {
                              return [];
                            }

                            return unidades
                                .where(
                                  (u) => u['unidad']
                                      .toString()
                                      .toLowerCase()
                                      .contains(pattern.toLowerCase()),
                                )
                                .toList();
                          },
                          builder: (context, controller, focusNode) =>
                              TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: "Unidad",
                                  prefixIcon: Icon(Icons.directions_car),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? "Campo requerido"
                                    : null,
                              ),
                          itemBuilder:
                              (context, Map<String, dynamic> suggestion) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.directions_car_filled,
                                  ),
                                  title: Text(suggestion['unidad'] ?? ''),
                                );
                              },
                          onSelected: (suggestion) {
                            unidadController.text = suggestion['unidad'];
                          },
                        ),

                      const SizedBox(height: 32),

                      HexButton(
                        text: 'Guardar',
                        textColor: Colors.black,
                        heightButton: 55,
                        widthButton: 200,
              
                        colors: const [AppColors.primary, AppColors.primary],
                        onTap: _validarFormulario,
                      ),

                      /*ElevatedButton.icon(
                        onPressed: _validarFormulario,

                        icon: const Icon(Icons.check),
                        label: const Text("Guardar"),
                      ),*/
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
