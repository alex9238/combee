import 'dart:convert';
import 'dart:math';
import 'dart:convert';
import 'package:combee/model/rutaunidaddetalle.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:combee/model/estadomunicipio.dart';
import 'package:combee/model/rutachecador.dart';
import 'package:combee/model/rutaunidadchecador.dart';
import 'package:combee/model/trackingrutaunidad.dart';

import '../model/api_response.dart';
import '../model/estado.dart';
import '../model/municipio.dart';

class AccountLocation {
  final String urlEndpoint = "https://apirutas.com-mx.com.mx";

  Future<int> sendTracking(
    double latitud,
    double longitud,
    String ruta,
    String unidad,
    int estado,
    int municipio,
  ) async {
    try {
      print("Enviando ubicación servidor");
      var url = Uri.parse("$urlEndpoint/tracking");
      final http.Response response = await http.post(
        url,
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud, // Reemplaza con tu client ID
          'ruta': ruta,
          'unidad': unidad,
          'estado': estado,
          'municipio': municipio,
          'pais': 52,
        }),
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado Envio");
      print("Enviando ubicación servidor ${response.statusCode}");
      //print("Enviando ubicación servidor ${response.body}");

      if (response.statusCode == 200) {
        return 1;
      }
    } catch (e) {
      print("aqui ente");
      print(e);
      return -100;
    }
    return 0;
  }

  Future<List<Estado>> getState() async {
    try {
      print("Enviando ubicación");
      var url = Uri.parse("$urlEndpoint/state");
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      //debugPrint("#### Estados");
      //debugPrint("${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final res = ApiResponse<Estado>.fromJson(
          json,
          (j) => Estado.fromJson(j),
        );

        if (res.message == 1) {
          return res.data;
        }
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return [];
  }

  Future<List<Municipio>> getMunicipality(int estado) async {
    try {
      debugPrint("Estado a buscar ${estado}");
      var url = Uri.parse("$urlEndpoint/state/$estado/municipality");
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      debugPrint("#### Municipios");
      debugPrint("${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<Municipio>.fromJson(
          json,
          (j) => Municipio.fromJson(j),
        );

        if (res.message == 1) {
          return res.data;
        }
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return [];
  }

  Future<ApiResponse<EstadoMunicipio>> getDataLocation(
    double latitud,
    double longitud,
  ) async {
    ApiResponse<EstadoMunicipio> _responseApi = ApiResponse<EstadoMunicipio>();
    _responseApi.message = -1;

    try {
      debugPrint("Obteniendo información en automatico");
      var url = Uri.parse(
        "$urlEndpoint/location?latitud=${latitud}&longitud=${longitud}",
      );
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      debugPrint("#### Municipios");
      debugPrint("${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        _responseApi = ApiResponse<EstadoMunicipio>.fromJson(
          json,
          (j) => EstadoMunicipio.fromJson(j),
        );
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }

    return _responseApi;
  }

  Future<ApiResponse> sendStop(
    double latitud,
    double longitud,
    String ruta,
    String unidad,
    int estado,
    int municipio,
  ) async {
    ApiResponse _responseApi = ApiResponse();
    _responseApi.message = -1;

    try {
      print("Registrando ubicación parada");
      var url = Uri.parse("$urlEndpoint/ruta/paradas");
      final http.Response response = await http.post(
        url,
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud, // Reemplaza con tu client ID
          'ruta': ruta,
          'unidad': unidad,
          'estado': estado,
          'municipio': municipio,
          'pais': 52,
        }),
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado Envio");
      /*print("Enviando ubicación servidor ${response.statusCode}");
        print("Enviando ubicación servidor ${response.body}");*/

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _responseApi = ApiResponse.simple(json);
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return _responseApi;
  }

  Future<List<TrackingRutaUnidad>> getRutaUnidadesTracking(
    List<Map<String, dynamic>> query,
  ) async {
    try {
      print("Obtener coordenadas de unidades ");
      var url = Uri.parse("$urlEndpoint/rutas/unidades/concesionarios");
      final http.Response response = await http.post(
        url,
        body: jsonEncode(query),
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado tracking");

      /*print("Enviando ubicación servidor ${response.statusCode}");
        print("Enviando ubicación servidor ${response.body}");*/

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        //print(json);

        final res = ApiResponse<TrackingRutaUnidad>.fromJson(
          json,
          (j) => TrackingRutaUnidad.fromJson(j),
        );

        if (res.message == 1) {
          return res.data;
        }
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return [];
  }

  Future<List<RutaUnidadChecador>> getRutaUnidadChecador(
    int pais,
    int estado,
    int municipio,
    String ruta,
    int checador,
    String fecha,
  ) async {
    try {
      print("Obtener ruta unidad checador 2 x");

      var url = Uri.parse(
        "$urlEndpoint/rutas/checador?pais=${pais}&estado=${estado}&municipio=${municipio}&ruta=${ruta}&checador=${checador}&fecha=${fecha}",
      );
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado ruta unidad checador");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<RutaUnidadChecador>.fromJson(
          json,
          (j) => RutaUnidadChecador.fromJson(j),
        );

        if (res.message == 1) {
          return res.data;
        }
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return [];
  }

  Future<ApiResponse> sendCheckout(
    double latitud,
    double longitud,
    int ruta,
    int unidad,
    int checador,
    int check,
    String hora,
  ) async {
    ApiResponse _responseApi = ApiResponse();
    _responseApi.message = -1;

    try {
      print("Registrando checkout unidad ");

      var url = Uri.parse("$urlEndpoint/rutas/checkout");
      final http.Response response = await http.post(
        url,
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud, // Reemplaza con tu client ID
          'ruta': ruta,
          'unidad': unidad,
          'checador': checador,
          'check': check,
          'hora': hora,
        }),
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado Envio");
      /*print("Enviando ubicación servidor ${response.statusCode}");
        print("Enviando ubicación servidor ${response.body}");*/

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _responseApi = ApiResponse.simple(json);
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return _responseApi;
  }

  Future<ApiResponse> sendQualification(
    double latitud,
    double longitud,
    int ruta,
    int unidad,
    int checador,
    int check,
    int calificacion,
  ) async {
    ApiResponse _responseApi = ApiResponse();
    _responseApi.message = -1;

    try {
      print("Registrando calificacion unidad ");
      var url = Uri.parse("$urlEndpoint/rutas/unidades/calificaciones");

      final http.Response response = await http.post(
        url,
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud, // Reemplaza con tu client ID
          'ruta': ruta,
          'unidad': unidad,
          'checador': checador,
          'check': check,
          'calificacion': calificacion,
        }),
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado Envio");
      /*print("Enviando ubicación servidor ${response.statusCode}");
        print("Enviando ubicación servidor ${response.body}");*/

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        _responseApi = ApiResponse.simple(json);
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return _responseApi;
  }

  Future<List<RutaChecador>> getRutaChecador(
    int pais,
    int estado,
    int municipio,
    String ruta,
    int tipo,
  ) async {
    try {
      print("Obtener ruta checador ");

      var url = Uri.parse(
        "$urlEndpoint/rutas/paradas?pais=${pais}&estado=${estado}&municipio=${municipio}&ruta=${ruta}&tipo=${tipo}",
      );
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado ruta checador");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<RutaChecador>.fromJson(
          json,
          (j) => RutaChecador.fromJson(j),
        );

        if (res.message == 1) {
          return res.data;
        }
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return [];
  }

  Future<List<TrackingRutaUnidad>> getRutaUnidadChecadorTracking(
    int pais,
    int estado,
    int municipio,
    String ruta,
  ) async {
    try {
      print("Obtener ruta unidad checador 2 -2 ");

      var url = Uri.parse(
        "$urlEndpoint/rutas/checador/tracking?pais=${pais}&estado=${estado}&municipio=${municipio}&ruta=${ruta}",
      );
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado ruta unidad checador");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<TrackingRutaUnidad>.fromJson(
          json,
          (j) => TrackingRutaUnidad.fromJson(j),
        );

        if (res.message == 1) {
          return res.data;
        }
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return [];
  }

  Future<List<RutaUnidadDetalle>> getRutaUnidadChecadorDetalle(
    int pais,
    int estado,
    int municipio,
    String ruta,
    String unidad,
  ) async {
    try {
      print("Obtener ruta unidad checador detalle ");

      print(
        "$urlEndpoint/rutas/unidades/detalle?pais=${pais}&estado=${estado}&municipio=${municipio}&ruta=${ruta}&unidad=${unidad}",
      );
      var url = Uri.parse(
        "$urlEndpoint/rutas/unidades/detalle?pais=${pais}&estado=${estado}&municipio=${municipio}&ruta=${ruta}&unidad=${unidad}",
      );
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado ruta unidad checador");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<RutaUnidadDetalle>.fromJson(
          json,
          (j) => RutaUnidadDetalle.fromJson(j),
        );

        if (res.message == 1) {
          return res.data;
        }
      }
    } catch (e) {
      print("aqui ente");
      print(e);
    }
    return [];
  }
}
