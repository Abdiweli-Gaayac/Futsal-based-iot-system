import 'package:futsal/models/user.dart';
import 'package:futsal/services/service_manager.dart';
import 'package:futsal/utils/model_mapper.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  // Service manager for manager endpoints
  final ServiceManager _managerManager = ServiceManager('/manager/users');

  // Model mapper for transforming responses
  final ModelMapper<User> _mapper =
      ModelMapper<User>((json) => User.fromJson(json));

  // Singleton pattern
  factory UserService() => _instance;
  UserService._internal();

  // Get all users with optional search
  Future<Map<String, dynamic>> getAllUsers({String? search}) async {
    final queryParams = search != null ? {'search': search} : null;
    final response = await _managerManager.getAll(queryParams: queryParams);
    return _mapper.transformResponse(response);
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await _managerManager.getById(userId);
    return _mapper.transformResponse(response);
  }

  // Create new user
  Future<Map<String, dynamic>> createUser({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _managerManager.create({
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
    });
    return _mapper.transformResponse(response);
  }

  // Update user
  Future<Map<String, dynamic>> updateUser(
    String userId, {
    String? name,
    String? phone,
    String? currentPassword,
    String? newPassword,
    String? role,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (currentPassword != null) updates['currentPassword'] = currentPassword;
    if (newPassword != null) updates['newPassword'] = newPassword;
    if (role != null) updates['role'] = role;

    final response = await _managerManager.update(userId, updates);
    return _mapper.transformResponse(response);
  }

  // Delete user
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    return await _managerManager.delete(userId);
  }
}
