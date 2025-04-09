// lib/services/slot_service.dart
import 'package:futsal/models/slot.dart';
import 'package:futsal/services/service_manager.dart';
import 'package:futsal/utils/model_mapper.dart';

class SlotService {
  final ServiceManager _publicManager = ServiceManager('/public/slots');
  final ServiceManager _managerManager = ServiceManager('/manager/slots');
  final ModelMapper<Slot> _mapper =
      ModelMapper<Slot>((json) => Slot.fromJson(json));

  // Public methods
  Future<Map<String, dynamic>> getPublicSlots() async {
    final response = await _publicManager.getAll();
    return _mapper.transformResponse(response);
  }

  // Manager methods
  Future<Map<String, dynamic>> getAllSlots() async {
    final response = await _managerManager.getAll();
    return _mapper.transformResponse(response);
  }

  Future<Map<String, dynamic>> createSlot(
      String startTime, String endTime, double price) async {
    final response = await _managerManager.create({
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
    });
    return _mapper.transformResponse(response);
  }

  Future<Map<String, dynamic>> updateSlot(
      String slotId, Map<String, dynamic> updates) async {
    final response = await _managerManager.update(slotId, updates);
    return _mapper.transformResponse(response);
  }

  Future<Map<String, dynamic>> deleteSlot(String slotId) async {
    return await _managerManager.delete(slotId);
  }
}
