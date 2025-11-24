import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  LocationPermission? _currentPermission;
  bool _overlayPermission = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);

    final perm = await Geolocator.checkPermission();

    // 🔧 cambio importante: usa isPermissionGranted() (no checkPermission)
    /*final overlay = Platform.isAndroid
        ? await FlutterOverlayWindow.isPermissionGranted()
        : true;*/

    setState(() {
      _currentPermission = perm;
      //_overlayPermission = overlay;
      _checking = false;
    });
  }

  Future<void> _requestAlwaysPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (Platform.isAndroid && perm != LocationPermission.always) {
      final abrir =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Se necesita permiso "Siempre"'),
              content: const Text(
                'Para rastreo en segundo plano, la app necesita el permiso "Permitir todo el tiempo". ¿Deseas abrir los ajustes de la app para cambiarlo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Abrir Ajustes'),
                ),
              ],
            ),
          ) ??
          false;

      if (abrir) await openAppSettings();
    } else if (perm == LocationPermission.always) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación: Siempre ✅')),
        );
      }
    }

    await _refreshStatus();
  }

  Future<void> _requestOverlayPermission() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Overlay solo aplica en Android')),
      );
      return;
    }

    // 🔧 cambio: maneja correctamente la respuesta del requestPermission()
    //final result = await FlutterOverlayWindow.requestPermission();

    /*final granted =
        result == true || result.toString().toLowerCase().contains('granted');*/

    /*if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso overlay concedido ✅')),
      );
    } else {
      final abrir =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permiso de superposición'),
              content: const Text(
                'No se ha concedido permiso para "Mostrar sobre otras apps". ¿Deseas abrir ajustes para habilitarlo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Abrir Ajustes'),
                ),
              ],
            ),
          ) ??
          false;

      if (abrir) await openAppSettings();
    }

    await _refreshStatus();*/
  }

  Future<void> _openBatteryOptimization() async {
    await openAppSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abriendo ajustes (optimización de batería)...'),
      ),
    );
  }

  Widget _stepTile({
    required int number,
    required String title,
    required String description,
    required Widget action,
    bool done = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done ? Colors.green : Colors.blue,
          child: Text('$number', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perm = _currentPermission;
    final locationAlways = perm == LocationPermission.always;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial: permisos y overlay'),
        backgroundColor: const Color(0xFF009C97),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Sigue estos pasos para que el rastreo y el overlay funcionen correctamente:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Paso 1: comprobar permiso ubicación
                  _stepTile(
                    number: 1,
                    title: 'Comprobar permiso de Ubicación',
                    description:
                        'Verifica el permiso actual de ubicación (Necesitamos "Permitir todo el tiempo").',
                    done: locationAlways,
                    action: ElevatedButton(
                      onPressed: _refreshStatus,
                      child: const Text('Comprobar'),
                    ),
                  ),

                  // Paso 2: solicitar permiso Always
                  _stepTile(
                    number: 2,
                    title: 'Solicitar permiso "Siempre"',
                    description: locationAlways
                        ? 'Ya concedido: Permiso "Siempre" activo.'
                        : 'Solicita permiso o abre ajustes si hace falta.',
                    done: locationAlways,
                    action: ElevatedButton(
                      onPressed: _requestAlwaysPermission,
                      child: Text(
                        locationAlways
                            ? 'Concedido'
                            : 'Solicitar / Abrir Ajustes',
                      ),
                    ),
                  ),

                  // Paso 3: comprobar permiso overlay
                  _stepTile(
                    number: 3,
                    title:
                        'Comprobar permiso Overlay (Mostrar sobre otras apps)',
                    description: _overlayPermission
                        ? 'Permiso overlay concedido.'
                        : 'Permiso overlay no concedido.',
                    done: _overlayPermission,
                    action: ElevatedButton(
                      onPressed: _refreshStatus,
                      child: const Text('Comprobar'),
                    ),
                  ),

                  // Paso 4: solicitar permiso overlay
                  _stepTile(
                    number: 4,
                    title: 'Solicitar permiso Overlay',
                    description: _overlayPermission
                        ? 'Listo: la app puede mostrarse sobre otras apps.'
                        : 'Si falla la solicitud, abre ajustes manualmente.',
                    done: _overlayPermission,
                    action: ElevatedButton(
                      onPressed: _requestOverlayPermission,
                      child: Text(
                        _overlayPermission ? 'Concedido' : 'Solicitar Overlay',
                      ),
                    ),
                  ),

                  // Paso 5: optimización batería
                  _stepTile(
                    number: 5,
                    title: 'Desactivar optimización de batería',
                    description:
                        'En algunos dispositivos es necesario permitir que la app funcione en segundo plano sin restricciones de batería.',
                    done: false,
                    action: ElevatedButton(
                      onPressed: _openBatteryOptimization,
                      child: const Text('Abrir Ajustes'),
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: const Text('Hecho, volver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
