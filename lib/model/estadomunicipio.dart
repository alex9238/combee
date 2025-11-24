class EstadoMunicipio {
  int? _idestado;
  String? _estado;
  int? _idmunicipio;
  String? _municipio;

  EstadoMunicipio(
      {int? idestado, String? estado, int? idmunicipio, String? municipio}) {
    if (idestado != null) {
      this._idestado = idestado;
    }
    if (estado != null) {
      this._estado = estado;
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
  String? get estado => _estado;
  set estado(String? estado) => _estado = estado;
  int? get idmunicipio => _idmunicipio;
  set idmunicipio(int? idmunicipio) => _idmunicipio = idmunicipio;
  String? get municipio => _municipio;
  set municipio(String? municipio) => _municipio = municipio;

  EstadoMunicipio.fromJson(Map<String, dynamic> json) {
    _idestado = json['idestado'];
    _estado = json['estado'];
    _idmunicipio = json['idmunicipio'];
    _municipio = json['municipio'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idestado'] = this._idestado;
    data['estado'] = this._estado;
    data['idmunicipio'] = this._idmunicipio;
    data['municipio'] = this._municipio;
    return data;
  }
}