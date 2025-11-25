class Ruta {
  int? _idruta;
  String? _ruta;
  int? _idestado;
  int? _idmunicipio;
  int? _verificada;
  String? _wms;
  bool? _activo;

  Ruta({
    int? idruta,
    String? ruta,
    int? idestado,
    int? idmunicipio,
    int? verificada,
    String? wms,
    bool? activo,
  }) {
    if (idruta != null) {
      this._idruta = idruta;
    }
    if (ruta != null) {
      this._ruta = ruta;
    }
    if (idestado != null) {
      this._idestado = idestado;
    }
    if (idmunicipio != null) {
      this._idmunicipio = idmunicipio;
    }
    if (verificada != null) {
      this._verificada = verificada;
    }
    if (wms != null) {
      this._wms = wms;
    }
    if (activo != null) {
      this._activo = activo;
    }
  }

  int? get idruta => _idruta;
  set idruta(int? idruta) => _idruta = idruta;
  String? get ruta => _ruta;
  set ruta(String? ruta) => _ruta = ruta;
  int? get idestado => _idestado;
  set idestado(int? idestado) => _idestado = idestado;
  int? get idmunicipio => _idmunicipio;
  set idmunicipio(int? idmunicipio) => _idmunicipio = idmunicipio;
  int? get verificada => _verificada;
  set verificada(int? verificada) => _verificada = verificada;
  String? get wms => _wms;
  set wms(String? wms) => _wms = wms;
  bool? get activo => _activo;
  set activo(bool? activo) => _activo = activo;

  Ruta.fromJson(Map<String, dynamic> json) {
    _idruta = json['idruta'];
    _ruta = json['ruta'];
    _idestado = json['idestado'];
    _idmunicipio = json['idmunicipio'];
    _verificada = json['verificada'];
    _wms = json['wms'];
    _activo = json['activo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idruta'] = this._idruta;
    data['ruta'] = this._ruta;
    data['idestado'] = this._idestado;
    data['idmunicipio'] = this._idmunicipio;
    data['verificada'] = this._verificada;
    data['wms'] = this._wms;
    data['activo'] = this._activo;
    return data;
  }
}
