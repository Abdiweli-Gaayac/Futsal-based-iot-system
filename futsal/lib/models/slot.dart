// lib/models/slot.dart
class Slot {
  final String id;
  final String startTime;
  final String endTime;
  final double price;

  Slot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['_id'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      price: json['price'].toDouble(),
    );
  }
}
