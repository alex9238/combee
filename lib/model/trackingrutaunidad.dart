class TrackingRutaUnidad {
  String? _ruta;
  String? _unidad;
  String? _latitud;
  String? _longitud;
  String? _tiempo;
  String? _wms;
  bool? _activo;

  TrackingRutaUnidad({
    String? ruta,
    String? unidad,
    String? latitud,
    String? longitud,
    String? tiempo,
    String? wms,
    bool? activo,
  }) {
    if (ruta != null) {
      this._ruta = ruta;
    }
    if (unidad != null) {
      this._unidad = unidad;
    }
    if (latitud != null) {
      this._latitud = latitud;
    }
    if (longitud != null) {
      this._longitud = longitud;
    }
    if (tiempo != null) {
      this._tiempo = tiempo;
    }
    if (wms != null) {
      this._wms = wms;
    }
    if (activo != null) {
      this._activo = activo;
    }
  }

  String? get ruta => _ruta;
  set ruta(String? ruta) => _ruta = ruta;
  String? get unidad => _unidad;
  set unidad(String? unidad) => _unidad = unidad;
  String? get latitud => _latitud;
  set latitud(String? latitud) => _latitud = latitud;
  String? get longitud => _longitud;
  set longitud(String? longitud) => _longitud = longitud;
  String? get tiempo => _tiempo;
  set tiempo(String? tiempo) => _tiempo = tiempo;
  String? get wms => _wms;
  set wms(String? wms) => _wms = wms;
  bool? get activo => _activo;
  set activo(bool? activo) => _activo = activo;

  TrackingRutaUnidad.fromJson(Map<String, dynamic> json) {
    _ruta = json['ruta'];
    _unidad = json['unidad'];
    _latitud = json['latitud'];
    _longitud = json['longitud'];
    _tiempo = json['tiempo'];
    _wms = json['wms'];
    _activo = json['activo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ruta'] = this._ruta;
    data['unidad'] = this._unidad;
    data['latitud'] = this._latitud;
    data['longitud'] = this._longitud;
    data['tiempo'] = this._tiempo;
    data['wms'] = this._wms;
    data['activo'] = this._activo;
    return data;
  }
}
