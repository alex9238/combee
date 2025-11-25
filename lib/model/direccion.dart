class Direccion {
  String? _direccion;
  String? _latitud;
  String? _longitud;

  Direccion({String? direccion, String? latitud, String? longitud}) {
    if (direccion != null) {
      this._direccion = direccion;
    }
    if (latitud != null) {
      this._latitud = latitud;
    }
    if (longitud != null) {
      this._longitud = longitud;
    }
  }

  String? get direccion => _direccion;
  set direccion(String? direccion) => _direccion = direccion;
  String? get latitud => _latitud;
  set latitud(String? latitud) => _latitud = latitud;
  String? get longitud => _longitud;
  set longitud(String? longitud) => _longitud = longitud;

  Direccion.fromJson(Map<String, dynamic> json) {
    _direccion = json['direccion'];
    _latitud = json['latitud'];
    _longitud = json['longitud'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['direccion'] = this._direccion;
    data['latitud'] = this._latitud;
    data['longitud'] = this._longitud;
    return data;
  }
}
