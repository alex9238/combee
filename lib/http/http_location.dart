import 'dart:convert';
import 'dart:math';
import 'dart:convert';
import 'package:combee/model/direccion.dart';
import 'package:combee/model/ruta.dart';
import 'package:combee/model/rutaunidaddetalle.dart';
import 'package:combee/model/trazorutar.dart';
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

  Future<List<Estado>> getState() async {
    try {
      print("Enviando ubicación");
      var url = Uri.parse("$urlEndpoint/routes/state");
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
      var url = Uri.parse("$urlEndpoint/routes/state/$estado/municipality");
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

  /*
      #################################################
      METODOS PUBLICOS
      #################################################
  */

  Future<List<Ruta>> getRouteByStateMunicipality(
    int estado,
    int municipio,
  ) async {
    try {
      debugPrint("Rutas buscando  ${estado}  ${municipio}");
      var url = Uri.parse(
        "$urlEndpoint/routes/state/$estado/municipality/$municipio",
      );
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      debugPrint("#### Rutas ");
      debugPrint("${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<Ruta>.fromJson(json, (j) => Ruta.fromJson(j));

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

  Future<List<TrackingRutaUnidad>> getRutaUnidadTracking(
    List<Map<String, dynamic>> query,
  ) async {
    try {
      print("Obtener ruta unidad checador 2 -2 ");

      if (query.length == 0) {
        return [];
      }

      var url = Uri.parse("$urlEndpoint/routes/units");
      final http.Response response = await http.post(
        url,
        body: jsonEncode(query),
        headers: {"Content-Type": "application/json"},
      );
      print("#### Resultado ruta unidad publico ");

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

  Future<List<Direccion>> getAddressPoint(String addresss) async {
    try {
      debugPrint("Direccion buscando ");
      var url = Uri.parse("$urlEndpoint/address?q=$addresss");
      final http.Response response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );
      debugPrint("#### Direccion ");
      debugPrint("${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<Direccion>.fromJson(
          json,
          (j) => Direccion.fromJson(j),
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

  Future<List<TrazoRuta>> getRouteTrace(
    double latitud_1,
    double longitud_1,
    double latitud_2,
    double longitud_2,
  ) async {
    try {
      debugPrint("Trazo buscando ");

      print(
        jsonEncode({
          "latitud_1": latitud_1,
          "longitud_1": longitud_1,
          "latitud_2": latitud_2,
          "longitud_2": longitud_2,
        }),
      );
      var url = Uri.parse("$urlEndpoint/routes/maps");
      final http.Response response = await http.post(
        url,
        body: jsonEncode({
          "latitud_1": latitud_1,
          "longitud_1": longitud_1,
          "latitud_2": latitud_2,
          "longitud_2": longitud_2,
        }),
        headers: {"Content-Type": "application/json"},
      );
      debugPrint("#### Trazo ");
      debugPrint("${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final res = ApiResponse<TrazoRuta>.fromJson(
          json,
          (j) => TrazoRuta.fromJson(j),
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
