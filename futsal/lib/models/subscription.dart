import 'slot.dart';
import 'user.dart';

class Subscription {
  final String id;
  final String clientId;
  final String slotId;
  final DateTime startDate;
  final DateTime endDate;
  final int weeklyDay;
  final double monthlyAmount;
  final String status;
  final bool autoRenew;
  final DateTime lastBillingDate;
  final DateTime nextBillingDate;
  final String paymentStatus;
  final String? referenceId;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Slot? slot;
  final User? client;

  Subscription({
    required this.id,
    required this.clientId,
    required this.slotId,
    required this.startDate,
    required this.endDate,
    required this.weeklyDay,
    required this.monthlyAmount,
    required this.status,
    required this.autoRenew,
    required this.lastBillingDate,
    required this.nextBillingDate,
    required this.paymentStatus,
    this.referenceId,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.slot,
    this.client,
  });

  // Helper method to get local start date
  DateTime get localStartDate => startDate.toLocal();

  // Helper method to get local end date
  DateTime get localEndDate => endDate.toLocal();

  // Helper method to get day of week name
  String get dayOfWeekName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[weeklyDay];
  }

  // Helper method to check if subscription is active
  bool get isActive => status == 'active';

  // Helper method to check if subscription is expired
  bool get isExpired => status == 'expired';

  // Helper method to check if subscription is cancelled
  bool get isCancelled => status == 'cancelled';

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'] ?? json['id'],
      clientId: json['clientId'] is Map
          ? json['clientId']['_id'] ?? ''
          : json['clientId'] ?? '',
      slotId: json['slotId'] is Map
          ? json['slotId']['_id'] ?? ''
          : json['slotId'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      weeklyDay: json['weeklyDay'] ?? 0,
      monthlyAmount: (json['monthlyAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      autoRenew: json['autoRenew'] ?? true,
      lastBillingDate: DateTime.parse(json['lastBillingDate']),
      nextBillingDate: DateTime.parse(json['nextBillingDate']),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      referenceId: json['referenceId'],
      description: json['description'] ?? 'Monthly Futsal Subscription',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      slot: json['slotId'] != null && json['slotId'] is Map
          ? Slot.fromJson(json['slotId'])
          : null,
      client: json['clientId'] != null && json['clientId'] is Map
          ? User.fromJson(json['clientId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'slotId': slotId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'weeklyDay': weeklyDay,
      'monthlyAmount': monthlyAmount,
      'status': status,
      'autoRenew': autoRenew,
      'lastBillingDate': lastBillingDate.toIso8601String(),
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'paymentStatus': paymentStatus,
      'referenceId': referenceId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
