import 'package:combeetracking/model/rutaunidaddetalle.dart';
import 'package:combeetracking/provider/WalkieTalkieProvider.dart';
import 'package:flutter/material.dart';
import 'package:combeetracking/http/http_location.dart';
import 'package:combeetracking/model/rutaunidadchecador.dart';
import 'package:combeetracking/views/checker/tracking_map_checker.dart';
import 'package:combeetracking/views/configuration/configuration_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/constants.dart';

class CheckerPage extends StatefulWidget {
  const CheckerPage({super.key});

  @override
  State<CheckerPage> createState() => _CheckerPageState();
}

class _CheckerPageState extends State<CheckerPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  bool showSearch = false;

  late TabController _tabController;

  final AccountLocation api = AccountLocation();

  List<RutaUnidadChecador> unidadesEnParada = [];

  List<RutaUnidadChecador> unidadesEnRuta = [];

  RutaUnidadChecador? unidadActivaEnRuta;

  final TextEditingController fechaController = TextEditingController();
  final TextEditingController unidadController = TextEditingController();
  bool _expanded = false;

  List<RutaUnidadChecador> tempunidadesEnParada = [];

  List<RutaUnidadChecador> tempunidadesEnRuta = [];

  List<RutaUnidadDetalle> unidadRutaDetalle = [];

  bool _isLoading = false;

  String paradaName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fechaController.text =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    _cargarChecador();
    initConfig();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    Provider.of<WalkieTalkieProvider>(context, listen: false).dispose();
    super.dispose();
  }

  Future<void> initConfig() async {
    await _handlePermissionsAndConnect();
  }

  Future<void> _handlePermissionsAndConnect() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final prefs = await SharedPreferences.getInstance();
      String? ruta = prefs.getString("ruta");
      paradaName = prefs.getString("paradaName")!;

      String limpioParada = paradaName.replaceAll(' ', '');

      await Provider.of<WalkieTalkieProvider>(
        context,
        listen: false,
      ).connect("${ruta}_${limpioParada}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de micrófono denegado.')),
      );
    }
  }

  Future<void> _cargarChecador() async {
    try {
      _mostrarLoading();
      final prefs = await SharedPreferences.getInstance();
      int? estado = prefs.getInt("estado");
      int? municipio = prefs.getInt("municipio");
      String? ruta = prefs.getString("ruta");
      int? parada = prefs.getInt("parada");

      setState(() {
        paradaName = prefs.getString("paradaName")!;
      });
      final lista = await api.getRutaUnidadChecador(
        52,
        estado!,
        municipio!,
        ruta!,
        parada!,
        fechaController.text,
      );

      if (lista.isNotEmpty) {
        // Suponiendo que cada item tiene un campo: item.bit
        List<RutaUnidadChecador> parada = lista
            .where((item) => item.bit == 0)
            .toList();
        List<RutaUnidadChecador> ruta = lista
            .where((item) => item.bit == 1)
            .toList();

        parada.sort((a, b) {
          final fechaA =
              DateTime.tryParse(a.entrada ?? "") ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final fechaB =
              DateTime.tryParse(b.entrada ?? "") ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return fechaB.compareTo(fechaA); // DESC
        });

        ruta.sort((a, b) {
          final fa =
              DateTime.tryParse(a.salida ?? "") ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final fb =
              DateTime.tryParse(b.salida ?? "") ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return fb.compareTo(fa);
        });

        // Si quieres guardarlas en variables de estado
        setState(() {
          unidadesEnParada = parada;
          unidadesEnRuta = ruta;

          tempunidadesEnParada = unidadesEnParada;
          tempunidadesEnRuta = unidadesEnRuta;

          if (ruta.isNotEmpty) {
            unidadActivaEnRuta = ruta.first;
          }
        });
      }
      _ocultarLoading();
    } catch (e) {
      print('Error al obtener checador: $e');
    }

    _ocultarLoading();
  }

  Future<void> _obtenerRutaUnidadDetalle(String ruta, String unidad) async {
    try {
      _mostrarLoading();

      final prefs = await SharedPreferences.getInstance();
      int? estado = prefs.getInt("estado");
      int? municipio = prefs.getInt("municipio");

      final listaDetalle = await api.getRutaUnidadChecadorDetalle(
        52,
        estado!,
        municipio!,
        ruta!,
        unidad!,
      );

      setState(() {
        unidadRutaDetalle = listaDetalle;
      });

      _ocultarLoading();
    } catch (e) {
      print('Error al obtener checador: $e');
    }

    _ocultarLoading();
  }

  _buscar() {
    List<RutaUnidadChecador> parada = tempunidadesEnParada;
    List<RutaUnidadChecador> ruta = tempunidadesEnRuta;

    String unidadFiltro = unidadController.text.trim();

    print(unidadFiltro);

    if (unidadFiltro.isNotEmpty) {
      parada = parada
          .where(
            (item) =>
                (item.unidad ?? '').toLowerCase() == unidadFiltro.toLowerCase(),
          )
          .toList();

      ruta = ruta
          .where(
            (item) =>
                (item.unidad ?? '').toLowerCase() == unidadFiltro.toLowerCase(),
          )
          .toList();
    }

    parada.sort((a, b) {
      final fechaA =
          DateTime.tryParse(a.entrada ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final fechaB =
          DateTime.tryParse(b.entrada ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return fechaB.compareTo(fechaA); // DESC
    });

    ruta.sort((a, b) {
      final fa =
          DateTime.tryParse(a.salida ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final fb =
          DateTime.tryParse(b.salida ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return fb.compareTo(fa);
    });

    setState(() {
      unidadesEnParada = parada;
      unidadesEnRuta = ruta;
      _expanded = false;
    });
  }

  _limpiar() {
    setState(() {
      unidadController.text = "";
      fechaController.text =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    });

    _cargarChecador();
  }

  Future<void> _darSalida(
    int idcheck,
    int ruta,
    int unidad,
    String horaSalida,
  ) async {
    try {
      // Aquí llamas a tu API, ejemplo:
      final prefs = await SharedPreferences.getInstance();

      int? parada = prefs.getInt("parada");
      await api.sendCheckout(0, 0, ruta, unidad, parada!, idcheck, horaSalida);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salida registrada correctamente')),
      );
    } catch (e) {
      print('Error al registrar salida: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar salida')),
      );
    }
  }

  Future<void> _darCalificacion(
    int idcheck,
    int ruta,
    int unidad,
    int calificacion,
  ) async {
    try {
      // Aquí llamas a tu API, ejemplo:

      final prefs = await SharedPreferences.getInstance();

      int? parada = prefs.getInt("parada");

      await api.sendQualification(
        0,
        0,
        ruta,
        unidad,
        parada!,
        idcheck,
        calificacion,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status registrado correctamente')),
      );
    } catch (e) {
      print('Error al registrar salida: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar calificacion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Evita overflow al abrir teclado
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
                'Checador ${paradaName}',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.greyTitle),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool("check", false);

            final walkie = Provider.of<WalkieTalkieProvider>(
              context,
              listen: false,
            );

            await walkie.disposeAsync();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ConfigurationPage(view: AppUser.checador),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.greyTitle),
            onPressed: _cargarChecador,
          ),
        ],
      ),
      body: _buildContenido(),
    );
  }

  Widget _buildContenido() {
    return Column(
      children: [
        // Botón de filtros
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              _mostrarDialogoFiltro(); // no uses setState aquí
            },
            icon: const Icon(Icons.filter_list), // ← icono de filtro
            label: const Text("Filtros"),
          ),
        ),

        // Último dato
        _buildUltimoDato(),

        // Tabs
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.directions_bus), text: "En Parada"),
                  Tab(icon: Icon(Icons.route), text: "En Ruta"),
                  Tab(icon: Icon(Icons.radio), text: "Control"),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEnParada(),
                    _buildEnRuta(),
                    _buildWalkiTalkieUser(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUltimoDato() {
    return Container(
      width: double.infinity,
      //color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: unidadActivaEnRuta != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Última ruta registrada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Ruta: ${unidadActivaEnRuta!.ruta}'),
                      Text('Unidad: ${unidadActivaEnRuta!.unidad}'),
                      Text('Hora de salida: ${unidadActivaEnRuta!.salida}'),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'No hay ruta registrada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoSalida(
    int idChecador,
    int ruta,
    int unidad,
  ) async {
    // Hora inicial: ahora mismo
    TimeOfDay horaActual = TimeOfDay.now();
    TimeOfDay horaSeleccionada = horaActual;

    await showDialog(
      context: context,
      barrierDismissible: false, // no se cierra tocando afuera
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Dar salida',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ajusta la hora de salida si es necesario:'),
                  const SizedBox(height: 16),
                  Text(
                    '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          final totalMinutes =
                              horaSeleccionada.hour * 60 +
                              horaSeleccionada.minute -
                              1;
                          if (totalMinutes >= 0) {
                            setState(() {
                              horaSeleccionada = TimeOfDay(
                                hour: totalMinutes ~/ 60,
                                minute: totalMinutes % 60,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          final totalMinutes =
                              horaSeleccionada.hour * 60 +
                              horaSeleccionada.minute +
                              1;
                          if (totalMinutes < 24 * 60) {
                            setState(() {
                              horaSeleccionada = TimeOfDay(
                                hour: totalMinutes ~/ 60,
                                minute: totalMinutes % 60,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    Navigator.pop(context); // cierra el diálogo de calificación

                    _mostrarLoading();

                    final horaString =
                        '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}:00';

                    await _darSalida(idChecador, ruta, unidad, horaString);

                    _ocultarLoading();
                    _cargarChecador();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoFiltro() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // no se cierra tocando afuera
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtro de Busqueda',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fechaController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Fecha",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          fechaController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
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
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        _mostrarLoading();

                        await _buscar();

                        _ocultarLoading();

                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.search),
                      label: const Text("Buscar"),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        _mostrarLoading();

                        await _limpiar();

                        _ocultarLoading();

                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text("Limpiar"),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoDetalle() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // no se cierra tocando afuera
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 600, // o el tamaño que gustes
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: unidadRutaDetalle.length,
                  itemBuilder: (context, index) {
                    final unidad = unidadRutaDetalle[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          unidad.tipo == 1
                              ? Icons.directions_bus
                              : Icons.location_on, // icono cuando no es tipo 1
                          color: Colors.blue,
                        ),

                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Unidad: ${unidad.ruta} - ${unidad.unidad}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildEstatusIcon(unidad.calificacion),
                          ],
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Parada: ${unidad.definicion}'),
                            Text('Llegó: ${unidad.checkin}'),

                            // 👇 Solo se muestra si tipo == 1
                            if (unidad.tipo == 1 && unidad.checkout != null)
                              Text('Salida: ${unidad.checkout}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _ocultarLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _mostrarDialogoCalificacion(
    int idChecador,
    int ruta,
    int unidad,
  ) async {
    int calificacion = 1; // valor inicial (1 = En tiempo)

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Dar salida',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Selecciona el estatus de salida:'),
                  const SizedBox(height: 16),

                  // 🔹 Opción 1 - En tiempo
                  RadioListTile<int>(
                    value: 1,
                    groupValue: calificacion,
                    onChanged: (value) {
                      setState(() => calificacion = value!);
                    },
                    title: const Text('En tiempo'),
                    secondary: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),

                  // 🔹 Opción 2 - Retardo
                  RadioListTile<int>(
                    value: 2,
                    groupValue: calificacion,
                    onChanged: (value) {
                      setState(() => calificacion = value!);
                    },
                    title: const Text('Retardo'),
                    secondary: const Icon(
                      Icons.access_time_filled,
                      color: Colors.orange,
                    ),
                  ),

                  // 🔹 Opción 3 - Algo
                  RadioListTile<int>(
                    value: 3,
                    groupValue: calificacion,
                    onChanged: (value) {
                      setState(() => calificacion = value!);
                    },
                    title: const Text('Incidencia'),
                    secondary: const Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    final parentContext =
                        context; // contexto del diálogo principal
                    Navigator.pop(context); // cierra el diálogo de calificación

                    _mostrarLoading();

                    await _darCalificacion(
                      idChecador,
                      ruta,
                      unidad,
                      calificacion,
                    );
                    _ocultarLoading();
                    _cargarChecador();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEnParada() {
    if (unidadesEnParada.isEmpty) {
      return Center(child: Text("No hay unidades"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unidadesEnParada.length,
      itemBuilder: (context, index) {
        final unidad = unidadesEnParada[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.directions_bus, color: Colors.blue),

            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ruta: ${unidad.ruta}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                _buildEstatusIcon(unidad.estatus),
              ],
            ),

            subtitle: Text(
              'Unidad: ${unidad.unidad}\nLlegó: ${unidad.entrada}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'salida') {
                  _mostrarDialogoSalida(
                    unidad.idcheck!,
                    unidad.idruta!,
                    unidad.idunidad!,
                  );
                }

                if (value == 'calificacion') {
                  _mostrarDialogoCalificacion(
                    unidad.idcheck!,
                    unidad.idruta!,
                    unidad.idunidad!,
                  );
                }

                if (value == 'detalle') {
                  await _obtenerRutaUnidadDetalle(unidad.ruta!, unidad.unidad!);

                  await _mostrarDialogoDetalle();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'salida', child: Text('Dar salida')),
                const PopupMenuItem(
                  value: 'calificacion',
                  child: Text('Dar status'),
                ),
                const PopupMenuItem(
                  value: 'detalle',
                  child: Text('Ver detalle'),
                ),
                const PopupMenuItem(
                  value: 'reporte',
                  child: Text('Hacer reporte'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstatusIcon(int? estatus) {
    switch (estatus) {
      case 1:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 4),
          ],
        );
      case 2:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.access_time_filled, color: Colors.orange, size: 20),
            SizedBox(width: 4),
          ],
        );
      case 3:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 20),
            SizedBox(width: 4),
          ],
        );
      default:
        return const SizedBox(); // sin estatus
    }
  }

  Widget _buildEnRuta() {
    if (unidadesEnRuta.isEmpty) {
      return Center(child: Text("No hay unidades"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unidadesEnRuta.length,
      itemBuilder: (context, index) {
        final unidad = unidadesEnRuta[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.route, color: Colors.green),
            //title: Text('Ruta: ${unidad.ruta}'),
            title: Text('Ruta: ${unidad.ruta}'),
            subtitle: Text(
              'Unidad: ${unidad.unidad}\nSalida: ${unidad.salida}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // Manejar acción

                if (value == "trayecto") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackingMapCheckerPage(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reporte',
                  child: Text('Hacer reporte'),
                ),
                const PopupMenuItem(
                  value: 'trayecto',
                  child: Text('Ver trayecto'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalkiTalkieUser() {
    return SafeArea(
      child: Consumer<WalkieTalkieProvider>(
        builder: (context, provider, child) {
          final filtered = provider.connectedUsers
              .where(
                (u) => u.toLowerCase().contains(_searchCtrl.text.toLowerCase()),
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
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
                            provider.wsConnected ? Icons.wifi : Icons.wifi_off,
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
                            icon: Icon(showSearch ? Icons.close : Icons.search),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          backgroundColor: Colors.blue.shade100,
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
                                            Colors.grey.shade100.withOpacity(
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
                            onLongPressStart: (_) => provider.startSpeaking(),
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

              // agrega más cards aquí...
            ],
          );
        },
      ),
    );
  }
}
