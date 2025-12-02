/*class TrazoRuta {
  List<String>? _wms;
  String? _ruta1;
  String? _ruta2;
  String? _distancia;

  TrazoRuta({
    List<String>? wms,
    String? ruta1,
    String? ruta2,
    String? distancia,
  }) {
    if (wms != null) {
      this._wms = wms;
    }
    if (ruta1 != null) {
      this._ruta1 = ruta1;
    }
    if (ruta2 != null) {
      this._ruta2 = ruta2;
    }
    if (distancia != null) {
      this._distancia = distancia;
    }
  }

  List<String>? get wms => _wms;
  set wms(List<String>? wms) => _wms = wms;
  String? get ruta1 => _ruta1;
  set ruta1(String? ruta1) => _ruta1 = ruta1;
  String? get ruta2 => _ruta2;
  set ruta2(String? ruta2) => _ruta2 = ruta2;
  String? get distancia => _distancia;
  set distancia(String? distancia) => _distancia = distancia;

  TrazoRuta.fromJson(Map<String, dynamic> json) {
    _wms = json['wms'].cast<String>();
    _ruta1 = json['ruta_1'];
    _ruta2 = json['ruta_2'];
    _distancia = json['distancia'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['wms'] = this._wms;
    data['ruta_1'] = this._ruta1;
    data['ruta_2'] = this._ruta2;
    data['distancia'] = this._distancia;
    return data;
  }
}*/

class TrazoRuta {
  List<String>? _wms;
  String? _ruta1;
  String? _ruta2;
  String? _distancia;

  bool checkboxActivo = false; // 👈 NUEVO

  TrazoRuta({
    List<String>? wms,
    String? ruta1,
    String? ruta2,
    String? distancia,
    this.checkboxActivo = false, // 👈 inicialización
  }) {
    if (wms != null) this._wms = wms;
    if (ruta1 != null) this._ruta1 = ruta1;
    if (ruta2 != null) this._ruta2 = ruta2;
    if (distancia != null) this._distancia = distancia;
  }

  List<String>? get wms => _wms;
  set wms(List<String>? wms) => _wms = wms;
  String? get ruta1 => _ruta1;
  set ruta1(String? ruta1) => _ruta1 = ruta1;
  String? get ruta2 => _ruta2;
  set ruta2(String? ruta2) => _ruta2 = ruta2;
  String? get distancia => _distancia;
  set distancia(String? distancia) => _distancia = distancia;

  TrazoRuta.fromJson(Map<String, dynamic> json) {
    _wms = json['wms'].cast<String>();
    _ruta1 = json['ruta_1'];
    _ruta2 = json['ruta_2'];
    _distancia = json['distancia'];
    checkboxActivo = false; // 👈 por defecto apagado
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['wms'] = this._wms;
    data['ruta_1'] = this._ruta1;
    data['ruta_2'] = this._ruta2;
    data['distancia'] = this._distancia;
    return data;
  }
}
