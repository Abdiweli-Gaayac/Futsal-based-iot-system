import 'package:flutter/material.dart';
import 'package:futsal/models/slot.dart';
import 'package:futsal/services/slot_service.dart';
import 'package:futsal/services/booking_service.dart';
import 'package:futsal/services/subscription_service.dart';
import 'package:intl/intl.dart';
import 'package:futsal/utils/timezone.dart';

import 'package:futsal/screens/client/my_bookings_screen.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final SlotService _slotService = SlotService();
  final BookingService _bookingService = BookingService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Slot> _slots = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _slotService.getPublicSlots(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      if (response['success']) {
        setState(() {
          _slots = (response['data'] as List<Slot>)
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load slots';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime date) {
        // Allow booking only for future dates
        return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSlots(); // Reload slots for the new date
    }
  }

  Future<void> _showBookingOptions(Slot slot) async {
    final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Options',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Time: ${slot.startTime} - ${slot.endTime}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Date: $formattedDate',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Single Booking Option
            _buildBookingOption(
              context,
              title: 'Single Booking',
              subtitle: 'Book this slot for one day only',
              price: '${slot.price.toStringAsFixed(2)}',
              icon: Icons.calendar_today,
              onTap: () {
                Navigator.pop(context);
                _showSingleBookingConfirmation(slot);
              },
            ),

            const SizedBox(height: 12),

            // Monthly Subscription Option
            _buildBookingOption(
              context,
              title: 'Monthly Subscription',
              subtitle: 'Book this slot every week for a month',
              price: '\$${(slot.price * 4).toStringAsFixed(2)}/month',
              icon: Icons.repeat,
              onTap: () {
                Navigator.pop(context);
                _showSubscriptionOptions(slot);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSingleBookingConfirmation(Slot slot) async {
    final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Single Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $formattedDate'),
            const SizedBox(height: 8),
            Text('Time: ${slot.startTime} - ${slot.endTime}'),
            const SizedBox(height: 8),
            Text('Price: \$${slot.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to proceed with this single booking?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _createSingleBooking(slot);
    }
  }

  Future<void> _showSubscriptionOptions(Slot slot) async {
    final weeklyDay =
        _selectedDate.weekday % 7; // Convert to 0-6 (Sunday-Saturday)
    final dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${slot.startTime} - ${slot.endTime}'),
            const SizedBox(height: 8),
            Text('Day: ${dayNames[weeklyDay]}'),
            const SizedBox(height: 8),
            Text('Monthly Price: \$${(slot.price * 4).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Text(
              'This will book this slot every ${dayNames[weeklyDay]} for one month.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createSubscription(slot, weeklyDay);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSingleBooking(Slot slot) async {
    setState(() => _isLoading = true);

    try {
      final response = await _bookingService.createBooking(
        slot.id,
        DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Unknown error occurred'),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
            action: response['success']
                ? SnackBarAction(
                    label: 'View Bookings',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyBookingsScreen()),
                      );
                    },
                  )
                : null,
          ),
        );

        if (response['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyBookingsScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createSubscription(Slot slot, int weeklyDay) async {
    setState(() => _isLoading = true);

    try {
      final response = await _subscriptionService.createSubscription(
        slotId: slot.id,
        startDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        weeklyDay: weeklyDay,
        months: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Unknown error occurred'),
            backgroundColor: response.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        if (response.success) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyBookingsScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Available Slots',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slots for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Change Date'),
                ),
              ],
            ),
          ),
          // Slots list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildModernErrorState()
                    : _slots.isEmpty
                        ? _buildModernEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadSlots,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _slots.length,
                              itemBuilder: (context, index) {
                                final slot = _slots[index];
                                return _buildModernSlotCard(slot);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSlotCard(Slot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: slot.isBooked == true ? null : () => _showBookingOptions(slot),
        leading: CircleAvatar(
          backgroundColor: slot.isBooked == true
              ? Colors.red.shade100
              : Colors.green.shade100,
          child: Text(
            slot.startTime.substring(0, 2),
            style: TextStyle(
              color: slot.isBooked == true
                  ? Colors.red.shade700
                  : Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${slot.startTime} - ${slot.endTime}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (slot.isBooked == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'BOOKED',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price: ${slot.price.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.green.shade700),
            ),
            if (slot.isBooked == true && slot.bookedBy != null)
              Text(
                'Booked by: ${slot.bookedBy}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            if (slot.isSubscriptionBooking == true)
              Text(
                'Subscription Booking',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: slot.isBooked == true
            ? const Icon(
                Icons.block,
                color: Colors.red,
              )
            : ElevatedButton(
                onPressed: () => _showBookingOptions(slot),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Book Now'),
              ),
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No slots available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSlots,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
