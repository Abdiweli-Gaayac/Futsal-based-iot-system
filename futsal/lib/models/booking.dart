import 'package:futsal/models/slot.dart';
import 'package:futsal/models/user.dart';

class Booking {
  final String id;
  final String clientId;
  final String slotId;
  final String date;
  final double amount;
  final String paymentStatus;
  final String? referenceId;
  final String? otp;
  final bool isUsed;
  final DateTime createdAt;
  final Slot? slot;
  final User? client;

  Booking({
    required this.id,
    required this.clientId,
    required this.slotId,
    required this.date,
    required this.amount,
    required this.paymentStatus,
    this.referenceId,
    this.otp,
    required this.isUsed,
    required this.createdAt,
    this.slot,
    this.client,
  });

  // Helper method to get local date from UTC date string
  DateTime get localDate {
    // Parse the UTC date string and convert to local timezone
    final utcDate = DateTime.parse(date);
    return utcDate.toLocal();
  }

  // Helper method to get date string in YYYY-MM-DD format for local timezone
  String get localDateString {
    final local = localDate;
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'],
      clientId: json['clientId'] != null && json['clientId'] is Map 
          ? json['clientId']['_id'] 
          : json['clientId'] ?? '',
      slotId: json['slotId'] is Map ? json['slotId']['_id'] : json['slotId'],
      date: json['date'],
      amount: json['amount'].toDouble(),
      paymentStatus: json['paymentStatus'],
      referenceId: json['referenceId'],
      otp: json['otp'],
      isUsed: json['isUsed'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      slot: json['slotId'] is Map ? Slot.fromJson(json['slotId']) : null,
      client: json['clientId'] != null && json['clientId'] is Map 
          ? User.fromJson(json['clientId']) 
          : null,
    );
  }
}
