class Municipio {
  int? _idestado;
  int? _idmunicipio;
  String? _municipio;

  Municipio({int? idestado, int? idmunicipio, String? municipio}) {
    if (idestado != null) {
      this._idestado = idestado;
    }
    if (idmunicipio != null) {
      this._idmunicipio = idmunicipio;
    }
    if (municipio != null) {
      this._municipio = municipio;
    }
  }

  int? get idestado => _idestado;
  set idestado(int? idestado) => _idestado = idestado;
  int? get idmunicipio => _idmunicipio;
  set idmunicipio(int? idmunicipio) => _idmunicipio = idmunicipio;
  String? get municipio => _municipio;
  set municipio(String? municipio) => _municipio = municipio;

  Municipio.fromJson(Map<String, dynamic> json) {
    _idestado = json['idestado'];
    _idmunicipio = json['idmunicipio'];
    _municipio = json['municipio'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idestado'] = this._idestado;
    data['idmunicipio'] = this._idmunicipio;
    data['municipio'] = this._municipio;
    return data;
  }
}