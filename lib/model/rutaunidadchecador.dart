class RutaUnidadChecador {
  int? _idcheck;

  int? _idruta;
  String? _ruta;

  int? _idunidad;
  String? _unidad;
  String? _entrada;
  String? _parada;
  String? _salida;
  int? _bit;
  int? _estatus;

  RutaUnidadChecador({
    int? idcheck,
    int? idruta,
    String? ruta,
    int? idunidad,
    String? unidad,
    String? entrada,
    String? parada,
    String? salida,
    int? bit,
    int? estatus,
  }) {
    if (idcheck != null) {
      this._idcheck = idcheck;
    }

    if (idruta != null) {
      this._idruta = idruta;
    }
    if (ruta != null) {
      this._ruta = ruta;
    }

    if (idunidad != null) {
      this._idunidad = idunidad;
    }
    if (unidad != null) {
      this._unidad = unidad;
    }
    if (entrada != null) {
      this._entrada = entrada;
    }
    if (parada != null) {
      this._parada = parada;
    }
    if (salida != null) {
      this._salida = salida;
    }
    if (bit != null) {
      this._bit = bit;
    }
    if (estatus != null) {
      this._estatus = estatus;
    }
  }

  int? get idcheck => _idcheck;
  set idcheck(int? idcheck) => _idcheck = idcheck;

  int? get idruta => _idruta;
  set idruta(int? idruta) => _idruta = idruta;

  String? get ruta => _ruta;
  set ruta(String? ruta) => _ruta = ruta;

  int? get idunidad => _idunidad;
  set idunidad(int? idunidad) => _idunidad = idunidad;

  String? get unidad => _unidad;
  set unidad(String? unidad) => _unidad = unidad;
  String? get entrada => _entrada;
  set entrada(String? entrada) => _entrada = entrada;
  String? get parada => _parada;
  set parada(String? parada) => _parada = parada;
  String? get salida => _salida;
  set salida(String? salida) => _salida = salida;
  int? get bit => _bit;
  set bit(int? bit) => _bit = bit;
  int? get estatus => _estatus;
  set estatus(int? estatus) => _estatus = estatus;

  RutaUnidadChecador.fromJson(Map<String, dynamic> json) {
    _idcheck = json['idcheck'];
    _idruta = json['idruta'];
    _ruta = json['ruta'];
    _idunidad = json['idunidad'];
    _unidad = json['unidad'];
    _entrada = json['entrada'];
    _parada = json['parada'];
    _salida = json['salida'];
    _bit = json['bit'];
    _estatus = json['estatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idcheck'] = this._idcheck;
    data['idruta'] = this._idruta;
    data['ruta'] = this._ruta;
    data['unidad'] = this._unidad;
    data['idunidad'] = this._idunidad;
    data['entrada'] = this._entrada;
    data['parada'] = this._parada;
    data['salida'] = this._salida;
    data['bit'] = this._bit;
    data['estatus'] = this._estatus;
    return data;
  }
}
