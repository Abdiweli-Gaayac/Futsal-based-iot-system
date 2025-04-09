import 'package:flutter/material.dart';
import 'package:futsal/models/slot.dart';
import 'package:futsal/services/slot_service.dart';
import 'package:futsal/services/booking_service.dart';
import 'package:intl/intl.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final SlotService _slotService = SlotService();
  final BookingService _bookingService = BookingService();
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
      final response = await _slotService.getPublicSlots();
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
    }
  }

  Future<void> _showBookingConfirmation(Slot slot) async {
    final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
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
              'Would you like to proceed with this booking?',
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
      _createBooking(slot);
    }
  }

  Future<void> _createBooking(Slot slot) async {
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
                      Navigator.pushNamed(context, '/client/bookings');
                    },
                  )
                : null,
          ),
        );

        if (response['success']) {
          Navigator.pushNamed(context, '/client/bookings');
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
      appBar: AppBar(
        title: const Text('Available Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSlots,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _slots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey.shade400,
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
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSlots,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _slots.length,
                              itemBuilder: (context, index) {
                                final slot = _slots[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    onTap: () => _showBookingConfirmation(slot),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: Text(
                                        slot.startTime.substring(0, 2),
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${slot.startTime} - ${slot.endTime}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Price: \$${slot.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () =>
                                          _showBookingConfirmation(slot),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Book Now'),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
