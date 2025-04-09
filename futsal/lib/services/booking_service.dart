import 'package:futsal/models/booking.dart';
import 'package:futsal/services/service_manager.dart';
import 'package:futsal/utils/model_mapper.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();

  // Service managers for different endpoints
  final ServiceManager _clientManager = ServiceManager('/public/my-bookings');
  final ServiceManager _managerManager = ServiceManager('/manager/bookings');

  // Model mapper for transforming responses
  final ModelMapper<Booking> _mapper =
      ModelMapper<Booking>((json) => Booking.fromJson(json));

  // Singleton pattern
  factory BookingService() => _instance;
  BookingService._internal();

  // Client methods
  Future<Map<String, dynamic>> getMyBookings({String? status}) async {
    final queryParams = status != null ? {'status': status} : null;
    final response = await _clientManager.getAll(queryParameters: queryParams);
    return _mapper.transformResponse(response);
  }

  Future<Map<String, dynamic>> createBooking(String slotId, String date) async {
    final response = await _clientManager.create({
      'slotId': slotId,
      'date': date,
    });
    return response; // API client already handles success/error responses
  }

  // Manager methods
  Future<Map<String, dynamic>> getAllBookings({
    String? date,
    String? search,
  }) async {
    final queryParams = {
      if (date != null) 'date': date,
      if (search != null) 'search': search,
    };

    final response = await _managerManager.getAll(
        queryParams: queryParams.isNotEmpty ? queryParams : null);
    return _mapper.transformResponse(response);
  }

  Future<Map<String, dynamic>> createBookingByManager({
    required String clientId,
    required String slotId,
    required String date,
  }) async {
    final response = await _managerManager.create({
      'clientId': clientId,
      'slotId': slotId,
      'date': date,
    });
    return _mapper.transformResponse(response);
  }

  Future<Map<String, dynamic>> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _managerManager.update(bookingId, updates);
    return _mapper.transformResponse(response);
  }

  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    return await _managerManager.delete(bookingId);
  }

  // Verify OTP (can be used by ESP32)
  Future<Map<String, dynamic>> verifyOTP(String otp) async {
    final response = await _clientManager.create(
      {'otp': otp},
      path: '/verify-otp',
    );
    return response;
  }
}
