import 'dart:async';

import 'package:flutter/material.dart';
//import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/*
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String _locationInfo = 'Esperando datos de ubicación...';

  @override
  void initState() {
    super.initState();
    _startListening();  // Iniciar la escucha de eventos
  }

  void _startListening() {
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && data is Map<String, dynamic>) {
        // Actualizar el texto del overlay con la nueva información
        setState(() {
          _locationInfo = data["location_info"] ?? 'Sin información';
        });
      }
    });
  }

  void _closeOverlay() {
    FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _closeOverlay,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color.fromARGB(255, 0, 156, 151),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 16),
                  const SizedBox(width: 5),
                  const Text(
                    'UBICACIÓN EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _closeOverlay,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _locationInfo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Toca para cerrar',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
/*
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String _locationInfo = 'Esperando datos de ubicación...';
  StreamSubscription? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    _initializeOverlay();
  }

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    super.dispose();
  }

  void _initializeOverlay() {
    // ✅ Inicializar el listener aquí también por si acaso
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      print('🎯 [OVERLAY WIDGET] Datos recibidos: $data');
      
      if (data != null && data is Map<String, dynamic>) {
        final newInfo = data["location_info"];
        if (newInfo != null && mounted) {
          setState(() {
            _locationInfo = newInfo;
          });
        }
      }
    });

    // ✅ Solicitar datos actuales al iniciar
    _requestInitialData();
  }

  void _requestInitialData() {
    // Enviar señal para solicitar datos actuales
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterOverlayWindow.shareData({'request_data': true});
    });
  }

  void _closeOverlay() {
    FlutterOverlayWindow.closeOverlay();
  }

  void _refreshData() {
    // Solicitar actualización de datos
    FlutterOverlayWindow.shareData({'request_data': true});
    // También forzar update del servicio
    _requestInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        //onTap: _closeOverlay,
        onLongPress: _refreshData,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color.fromARGB(255, 0, 156, 151),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 16),
                  const SizedBox(width: 5),
                  const Text(
                    'UBICACIÓN EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: _closeOverlay,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _locationInfo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Toca para cerrar • Mantén para actualizar',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/

/*

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String _locationInfo = 'Esperando datos de ubicación...';
  StreamSubscription? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    _initializeOverlay();
  }

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    super.dispose();
  }

  void _initializeOverlay() {
    _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((
      data,
    ) async {
      print('🎯 [OVERLAY WIDGET] Datos recibidos: $data');

      if (data == null) return;

      if (data is Map<String, dynamic>) {
        // 🟢 Si es un ping, responde con pong
        if (data['ping'] == true) {
          print('🏓 Recibido PING, respondiendo PONG');
          FlutterOverlayWindow.shareData({'pong': true});
          return;
        }

        // 🗺️ Actualizar ubicación
        final newInfo = data["location_info"];
        if (newInfo != null && mounted) {
          setState(() => _locationInfo = newInfo);

          // Guardar respaldo
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_overlay_location', newInfo);
        }
      }
    });
  }

  void _closeOverlay() {
    FlutterOverlayWindow.closeOverlay();
  }

  void _refreshData() {
    // Enviar petición al servicio (para actualizar datos)
    FlutterOverlayWindow.shareData({'request_data': true});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onLongPress: _refreshData,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color.fromARGB(255, 0, 156, 151),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 16),
                  const SizedBox(width: 5),
                  const Text(
                    'UBICACIÓN EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _refreshData,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: _closeOverlay,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _locationInfo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Mantén para actualizar',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
