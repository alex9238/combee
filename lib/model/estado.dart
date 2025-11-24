class Estado {
  int? _idestado;
  String? _estado;

  Estado({int? idestado, String? estado}) {
    if (idestado != null) {
      this._idestado = idestado;
    }
    if (estado != null) {
      this._estado = estado;
    }
  }

  int? get idestado => _idestado;
  set idestado(int? idestado) => _idestado = idestado;
  String? get estado => _estado;
  set estado(String? estado) => _estado = estado;

  Estado.fromJson(Map<String, dynamic> json) {
    _idestado = json['idestado'];
    _estado = json['estado'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['idestado'] = this._idestado;
    data['estado'] = this._estado;
    return data;
  }
}
