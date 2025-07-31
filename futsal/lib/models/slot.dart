// lib/models/slot.dart
class Slot {
  final String id;
  final String startTime;
  final String endTime;
  final double price;
  final bool? isBooked;
  final String? bookedBy;
  final String? paymentStatus;
  final bool? isSubscriptionBooking;

  Slot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.isBooked,
    this.bookedBy,
    this.paymentStatus,
    this.isSubscriptionBooking,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['_id'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      price: json['price'].toDouble(),
      isBooked: json['isBooked'] ?? false,
      bookedBy: json['bookedBy'],
      paymentStatus: json['paymentStatus'],
      isSubscriptionBooking: json['isSubscriptionBooking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'isBooked': isBooked,
      'bookedBy': bookedBy,
      'paymentStatus': paymentStatus,
      'isSubscriptionBooking': isSubscriptionBooking,
    };
  }
}
