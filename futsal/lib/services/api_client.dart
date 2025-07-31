// lib/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  // Singleton pattern
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:5500',
      validateStatus: (status) => true, // Handle all status codes ourselves
      // Remove timeouts to allow long-running requests
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  void setToken(String token) {
    // Ensure headers are initialized
    _dio.options.headers ??= {};
    // Set with Bearer prefix
    _dio.options.headers!['Authorization'] = token;
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Generic request method
  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(path, queryParameters: queryParameters);
          break;
        case 'POST':
          response = await _dio.post(path,
              data: data, queryParameters: queryParameters);
          break;
        case 'PATCH':
          response = await _dio.patch(path,
              data: data, queryParameters: queryParameters);
          break;
        case 'DELETE':
          response = await _dio.delete(path,
              data: data, queryParameters: queryParameters);
          break;
        default:
          throw Exception('Unsupported method: $method');
      }

      // Handle response
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'Success',
        };
      } else {
        String errorMessage = 'An error occurred';

        // Check if response is HTML
        if (response.headers
                .value(Headers.contentTypeHeader)
                ?.contains('text/html') ==
            true) {
          errorMessage =
              'Server returned unexpected response. Please try again.';
        } else if (response.data is Map) {
          // Check for both 'message' and 'error' fields
          errorMessage = response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        } else if (response.data is String) {
          // If response is plain string, use it
          errorMessage = response.data.toString();
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on DioException catch (e) {
      String errorMessage;

      if (e.response != null) {
        // Try to extract error message from response
        if (e.response!.data is Map) {
          // Check for both 'message' and 'error' fields
          errorMessage = e.response!.data['message'] ??
              e.response!.data['error'] ??
              _getErrorMessage(e);
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        } else {
          errorMessage = _getErrorMessage(e);
        }
      } else {
        errorMessage = _getErrorMessage(e);
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

// In lib/services/api_client.dart
  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check the server URL or try again later.';
      case DioExceptionType.badResponse:
        final response = error.response;
        // Handle HTML responses from server
        if (response != null &&
            response.headers
                    .value(Headers.contentTypeHeader)
                    ?.contains('text/html') ==
                true) {
          return 'Server error occurred. Please contact support.';
        }
        // Handle API error responses
        final statusCode = response?.statusCode;
        if (statusCode == 401)
          return 'Authentication failed. Please log in again.';
        if (statusCode == 403) return 'Permission denied.';
        if (statusCode == 404)
          return 'Server resource not found. Check server configuration.';
        return 'Server error occurred (${statusCode ?? 'unknown'})';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}
