// lib/services/service_manager.dart
import 'package:futsal/services/api_client.dart';

class ServiceManager {
  final ApiClient _apiClient = ApiClient();
  final String _basePath;

  ServiceManager(this._basePath);

  Future<Map<String, dynamic>> getAll(
      {Map<String, dynamic>? queryParams,
      Map<String, String>? queryParameters}) async {
    return await _apiClient.request(
      method: 'GET',
      path: _basePath,
      queryParameters: queryParams,
    );
  }

  Future<Map<String, dynamic>> getById(String id) async {
    return await _apiClient.request(
      method: 'GET',
      path: '$_basePath/$id',
    );
  }

  Future<Map<String, dynamic>> create(
    Map<String, dynamic> data, {
    String? path,
  }) async {
    return await _apiClient.request(
      method: 'POST',
      path: path ?? _basePath,
      data: data,
    );
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _apiClient.request(
      method: 'PATCH',
      path: '$_basePath/$id',
      data: data,
    );
  }

  Future<Map<String, dynamic>> delete(String id) async {
    return await _apiClient.request(
      method: 'DELETE',
      path: '$_basePath/$id',
    );
  }
}
