class RutaUnidadDetalle {
  String? _ruta;
  String? _unidad;
  String? _checkin;
  String? _checkout; // <-- corregido
  String? _definicion;
  int? _tipo;
  int? _calificacion;

  RutaUnidadDetalle({
    String? ruta,
    String? unidad,
    String? checkin,
    String? checkout,
    String? definicion,
    int? tipo,
    int? calificacion,
  }) {
    _ruta = ruta;
    _unidad = unidad;
    _checkin = checkin;
    _checkout = checkout;
    _definicion = definicion;
    _tipo = tipo;
    _calificacion = calificacion;
  }

  String? get ruta => _ruta;
  String? get unidad => _unidad;
  String? get checkin => _checkin;
  String? get checkout => _checkout; // <-- corregido
  String? get definicion => _definicion;
  int? get tipo => _tipo;
  int? get calificacion => _calificacion;

  RutaUnidadDetalle.fromJson(Map<String, dynamic> json) {
    _ruta = json['ruta'];
    _unidad = json['unidad'];
    _checkin = json['checkin'];
    _checkout = json['checkout']; // <-- acepta null sin problema
    _definicion = json['definicion'];
    _tipo = json['tipo'];
    _calificacion = json['calificacion'];
  }

  Map<String, dynamic> toJson() {
    return {
      'ruta': _ruta,
      'unidad': _unidad,
      'checkin': _checkin,
      'checkout': _checkout,
      'definicion': _definicion,
      'tipo': _tipo,
      'calificacion': _calificacion,
    };
  }
}
