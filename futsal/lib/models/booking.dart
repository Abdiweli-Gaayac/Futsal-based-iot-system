import 'package:futsal/models/slot.dart';
import 'package:futsal/models/user.dart';
import 'package:futsal/utils/timezone.dart';

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

  // Helper method to get Somalia date from UTC date string
  DateTime get somaliaDate {
    // Parse the UTC date string and convert to Somalia timezone
    final utcDate = DateTime.parse(date);
    return SomaliaTimezone.utcToSomalia(utcDate);
  }

  // Helper method to get date string in YYYY-MM-DD format for Somalia timezone
  String get somaliaDateString {
    final somalia = somaliaDate;
    return '${somalia.year.toString().padLeft(4, '0')}-'
        '${somalia.month.toString().padLeft(2, '0')}-'
        '${somalia.day.toString().padLeft(2, '0')}';
  }

  // Helper method to get local date from UTC date string (for backward compatibility)
  DateTime get localDate {
    return somaliaDate;
  }

  // Helper method to get date string in YYYY-MM-DD format for local timezone (for backward compatibility)
  String get localDateString {
    return somaliaDateString;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'],
      clientId:
          json['clientId'] is Map ? json['clientId']['_id'] : json['clientId'],
      slotId: json['slotId'] is Map ? json['slotId']['_id'] : json['slotId'],
      date: json['date'],
      amount: json['amount'].toDouble(),
      paymentStatus: json['paymentStatus'],
      referenceId: json['referenceId'],
      otp: json['otp'],
      isUsed: json['isUsed'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      slot: json['slotId'] is Map ? Slot.fromJson(json['slotId']) : null,
      client: json['clientId'] is Map ? User.fromJson(json['clientId']) : null,
    );
  }
}
