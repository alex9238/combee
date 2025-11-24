class ApiResponse<T> {
  int? message;
  dynamic data; // puede ser T, List<T> o null

  ApiResponse({this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawData = json['data'];

    if (rawData == null) {
      // Caso: data es null
      return ApiResponse<T>(message: json['message'], data: null);
    } else if (rawData is List) {
      // Caso: data es lista
      return ApiResponse<T>(
        message: json['message'],
        data: rawData.map((item) => fromJsonT(item)).toList(),
      );
    } else if (rawData is Map<String, dynamic>) {
      // Caso: data es un solo objeto
      return ApiResponse<T>(message: json['message'], data: fromJsonT(rawData));
    } else {
      // Caso inesperado
      return ApiResponse<T>(message: json['message'], data: null);
    }
  }

  factory ApiResponse.simple(Map<String, dynamic> json) {
    return ApiResponse<T>(message: json['message'], data: null);
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    final Map<String, dynamic> result = {};
    result['message'] = message;

    if (data == null) {
      result['data'] = null;
    } else if (data is List<T>) {
      result['data'] = (data as List<T>).map((e) => toJsonT(e)).toList();
    } else if (data is T) {
      result['data'] = toJsonT(data);
    }

    return result;
  }
}
