import 'package:combee/views/home/components/hex_button.dart';
import 'package:flutter/material.dart';
import 'package:combee/core/themes/app_themes.dart';
import 'package:combee/http/http_location.dart';
import 'package:combee/views/checker/checker_page.dart';
import 'package:select2dot1/select2dot1.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/constants.dart';

class CheckerSelectFormPage extends StatefulWidget {
  final Function(bool) onLogin; // Recibimos el callback
  final Function(bool) onChange; // Recibimos el callback hubo cambios

  const CheckerSelectFormPage({
    super.key,
    required this.onLogin,

    required this.onChange,
  });

  @override
  State<CheckerSelectFormPage> createState() => _CheckerSelectFormState();
}

class _CheckerSelectFormState extends State<CheckerSelectFormPage> {
  final AccountLocation api = AccountLocation();

  SelectDataController? paradaController;

  bool loadingEstados = true;

  int? selectedParadaId;
  String? selectedParadaName;

  final _formKey = GlobalKey<FormState>();

  int? idParada;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _loadConfigurationView();
  }

  _loadConfigurationView() async {
    _initLocationFlow();
  }

  Future<void> _initLocationFlow() async {
    // Siempre cargamos estados desde la API

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLogin(true);
    });

    await _loadParadas();

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
      if (idParada != null) {
        widget.onLogin(true);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool("check", true);
        await prefs.setInt("parada", idParada!);
        await prefs.setString("paradaName", selectedParadaName!);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CheckerPage()),
        );

        widget.onLogin(false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debe seleccionar parada")),
        );
      }
    }
  }

  Future<void> _loadParadas() async {
    final prefs = await SharedPreferences.getInstance();
    int? estado = prefs.getInt("estado");
    int? municipio = prefs.getInt("municipio");
    String? ruta = prefs.getString("ruta");

    final paradas = await api.getRutaChecador(
      52,
      estado!,
      municipio!,
      ruta!,
      1,
    );

    final items = paradas
        .map(
          (e) => SingleItemCategoryModel(
            nameSingleItem: e.denominacion ?? '',
            value: e.idchecador.toString(),
          ),
        )
        .toList();

    // Si ya tenemos un idEstado detectado, lo preseleccionamos
    SingleItemCategoryModel? selectedParadaItem;
    if (idParada != null) {
      selectedParadaItem = items.firstWhere(
        (item) => item.value == idParada.toString(),
        orElse: () => items.first,
      );
      selectedParadaId = int.tryParse(selectedParadaItem.value);
    }

    paradaController = SelectDataController(
      data: [
        SingleCategoryModel(
          nameCategory: "Paradas",
          singleItemCategoryList: items,
        ),
      ],
      isMultiSelect: false,
      initSelected: selectedParadaItem != null ? [selectedParadaItem] : null,
    );

    setState(() {
      loadingEstados = false;
    });
  }

  Future<void> _validarFormulario() async {
    final form = _formKey.currentState!;
    final estadoSeleccionado = selectedParadaId != null;

    if (!estadoSeleccionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona una parada"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (form.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Formulario válido ✅")));

      _guardarDatos();
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

                      if (loadingEstados || paradaController == null)
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
                          doneButtonModalSettings:
                              const DoneButtonModalSettings(title: "Aceptar"),
                          selectEmptyInfoSettings:
                              const SelectEmptyInfoSettings(
                                text: "-- Seleccione --",
                                textStyle: TextStyle(color: Colors.black),
                              ),
                          selectDataController: paradaController!,
                          onChanged: (selectedItems) async {
                            final item = selectedItems.isNotEmpty
                                ? selectedItems.first
                                : null;
                            final id = int.tryParse(item?.value ?? "");
                            final selectParadaName = item?.nameSingleItem;

                            if (id != null) {
                              selectedParadaId = id;
                              selectedParadaName = selectParadaName;
                              idParada = selectedParadaId;
                            }
                          },
                          pillboxTitleSettings: const PillboxTitleSettings(
                            title: "Selecciona una parada",
                            titleStyleDefault: TextStyle(color: Colors.black),
                          ),
                        ),

                      const SizedBox(height: 20),
                      HexButton(
                        text: 'Iniciar',
                        textColor: Colors.black,
                        heightButton: 55,
                        widthButton: 200,

                        colors: const [AppColors.primary, AppColors.primary],
                        onTap: _validarFormulario,
                      ),

                      //const SizedBox(height: 24),
                      /*ElevatedButton.icon(
                        onPressed: _validarFormulario,

                        icon: const Icon(Icons.check),
                        label: const Text("Iniciar"),
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
