import 'dart:convert';
import 'package:futsal/models/subscription.dart';
import 'package:futsal/services/api_client.dart';
import 'package:futsal/services/api_response.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse> createSubscription({
    required String slotId,
    required String startDate,
    required int weeklyDay,
    int months = 1,
  }) async {
    try {
      final response = await _apiClient.request(
        method: 'POST',
        path: '/subscriptions',
        data: {
          'slotId': slotId,
          'startDate': startDate,
          'weeklyDay': weeklyDay,
          'months': months,
        },
      );

      if (response['success']) {
        return ApiResponse(
          success: true,
          message: response['message'] ?? 'Subscription created successfully',
          data: response['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: response['message']?.toString() ??
              'Failed to create subscription',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> getMySubscriptions({String? status}) async {
    try {
      Map<String, dynamic>? queryParams;
      if (status != null) {
        queryParams = {'status': status};
      }

      final response = await _apiClient.request(
        method: 'GET',
        path: '/subscriptions/my-subscriptions',
        queryParameters: queryParams,
      );

      if (response['success']) {
        final subscriptions = (response['data'] as List)
            .map((json) => Subscription.fromJson(json))
            .toList();

        return ApiResponse(
          success: true,
          message:
              response['message'] ?? 'Subscriptions retrieved successfully',
          data: subscriptions,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response['message']?.toString() ??
              'Failed to retrieve subscriptions',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> cancelSubscription(String subscriptionId) async {
    try {
      final response = await _apiClient.request(
        method: 'PUT',
        path: '/subscriptions/cancel/$subscriptionId',
        data: {},
      );

      if (response['success']) {
        return ApiResponse(
          success: true,
          message: response['message'] ?? 'Subscription cancelled successfully',
          data: response['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: response['message']?.toString() ??
              'Failed to cancel subscription',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Manager methods
  Future<ApiResponse> getAllSubscriptions(
      {String? status, String? search}) async {
    try {
      Map<String, dynamic>? queryParams;
      if (status != null || search != null) {
        queryParams = {};
        if (status != null) queryParams['status'] = status;
        if (search != null && search.isNotEmpty) queryParams['search'] = search;
      }

      final response = await _apiClient.request(
        method: 'GET',
        path: '/subscriptions/all',
        queryParameters: queryParams,
      );

      if (response['success']) {
        final subscriptions = (response['data'] as List)
            .map((json) => Subscription.fromJson(json))
            .toList();

        return ApiResponse(
          success: true,
          message:
              response['message'] ?? 'Subscriptions retrieved successfully',
          data: subscriptions,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response['message']?.toString() ??
              'Failed to retrieve subscriptions',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> createSubscriptionByManager({
    required String clientId,
    required String slotId,
    required String startDate,
    required int weeklyDay,
    int months = 1,
  }) async {
    try {
      final response = await _apiClient.request(
        method: 'POST',
        path: '/subscriptions/manager',
        data: {
          'clientId': clientId,
          'slotId': slotId,
          'startDate': startDate,
          'weeklyDay': weeklyDay,
          'months': months,
        },
      );

      if (response['success']) {
        return ApiResponse(
          success: true,
          message: response['message'] ?? 'Subscription created successfully',
          data: response['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: response['message']?.toString() ??
              'Failed to create subscription',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> updateSubscription(
      String subscriptionId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.request(
        method: 'PUT',
        path: '/subscriptions/$subscriptionId',
        data: updates,
      );

      if (response['success']) {
        return ApiResponse(
          success: true,
          message: response['message'] ?? 'Subscription updated successfully',
          data: response['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: response['message']?.toString() ??
              'Failed to update subscription',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> deleteSubscription(String subscriptionId) async {
    try {
      final response = await _apiClient.request(
        method: 'DELETE',
        path: '/subscriptions/$subscriptionId',
      );

      if (response['success']) {
        return ApiResponse(
          success: true,
          message: response['message'] ?? 'Subscription deleted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response['message']?.toString() ??
              'Failed to delete subscription',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
