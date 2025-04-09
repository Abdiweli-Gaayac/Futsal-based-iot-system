class ModelMapper<T> {
  final T Function(Map<String, dynamic>) fromJson;

  ModelMapper(this.fromJson);

  // Map a single object
  T mapOne(Map<String, dynamic> json) {
    try {
      return fromJson(json);
    } catch (e) {
      print('Error mapping single object: $e');
      rethrow;
    }
  }

  // Map a list of objects
  List<T> mapList(List<dynamic> jsonList) {
    try {
      return jsonList
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error mapping list: $e');
      rethrow;
    }
  }

  // Transform API response to model or list of models
  Map<String, dynamic> transformResponse(Map<String, dynamic> response) {
    if (!response['success']) {
      return response;
    }

    final data = response['data'];
    if (data == null) {
      return response;
    }

    try {
      if (data is List) {
        response['data'] = mapList(data);
      } else if (data is Map<String, dynamic>) {
        response['data'] = mapOne(data);
      }
      return response;
    } catch (e) {
      print('Error transforming response: $e');
      return {
        'success': false,
        'message': 'Error processing data: ${e.toString()}',
      };
    }
  }
}
