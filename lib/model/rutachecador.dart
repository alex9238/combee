class RutaChecador {
  int? _idchecador;
  String? _denominacion;
  String? _latitud;
  String? _longitud;
  int? _tipo;

  RutaChecador({
    int? idchecador,
    String? denominacion,
    String? latitud,
    String? longitud,
    int? tipo,
  }) {
    if (idchecador != null) {
      this._idchecador = idchecador;
    }
    if (denominacion != null) {
      this._denominacion = denominacion;
    }
    if (latitud != null) {
      this._latitud = latitud;
    }
    if (longitud != null) {
      this._longitud = longitud;
    }
    if (tipo != null) {
      this._tipo = tipo;
    }
  }

  int? get idchecador => _idchecador;
  set idchecador(int? idchecador) => _idchecador = idchecador;
  String? get denominacion => _denominacion;
  set denominacion(String? denominacion) => _denominacion = denominacion;
  String? get latitud => _latitud;
  set latitud(String? latitud) => _latitud = latitud;
  String? get longitud => _longitud;
  set longitud(String? longitud) => _longitud = longitud;
  int? get tipo => _tipo;
  set tipo(int? tipo) => _tipo = tipo;

  RutaChecador.fromJson(Map<String, dynamic> json) {
    _idchecador = json['idchecador'];
    _denominacion = json['denominacion'];
    _latitud = json['latitud'];
    _longitud = json['longitud'];
    _tipo = json['tipo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idchecador'] = this._idchecador;
    data['denominacion'] = this._denominacion;
    data['latitud'] = this._latitud;
    data['longitud'] = this._longitud;
    data['tipo'] = this._tipo;
    return data;
  }
}
