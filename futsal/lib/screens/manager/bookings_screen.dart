import 'package:flutter/material.dart';
import 'package:futsal/models/booking.dart';
import 'package:futsal/models/slot.dart';
import 'package:futsal/models/user.dart';
import 'package:futsal/services/booking_service.dart';
import 'package:intl/intl.dart';
import 'package:futsal/services/user_service.dart';
import 'package:futsal/services/slot_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingService _bookingService = BookingService();
  final UserService _userService = UserService();
  final SlotService _slotService = SlotService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  // Add new variables for search
  final TextEditingController _searchController = TextEditingController();
  List<Booking> _filteredBookings = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _bookingService.getAllBookings(
        date: _searchQuery.isEmpty
            ? DateFormat('yyyy-MM-dd').format(_selectedDate)
            : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response['success']) {
        setState(() {
          _bookings = (response['data'] as List<Booking>)
            ..sort((a, b) {
              // First sort by date
              final dateCompare =
                  DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
              if (dateCompare != 0) return dateCompare;
              // Then by time if same date
              return a.slot!.startTime.compareTo(b.slot!.startTime);
            });
          _filteredBookings = _bookings;
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
        _error = 'Failed to load bookings';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadBookings();
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'paid':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  Future<void> _showBookingDetails(Booking booking) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'Date',
                  DateFormat('MMM dd, yyyy')
                      .format(DateTime.parse(booking.date))),
              _buildDetailRow('Time',
                  '${booking.slot!.startTime} - ${booking.slot!.endTime}'),
              _buildDetailRow('Client', booking.client!.name),
              _buildDetailRow('Phone', booking.client!.phone),
              _buildDetailRow(
                  'Amount', '\$${booking.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Status', booking.paymentStatus.toUpperCase(),
                  color: _getStatusColor(booking.paymentStatus)),
              if (booking.referenceId != null)
                _buildDetailRow('Reference', booking.referenceId!),
              if (booking.otp != null && !booking.isUsed)
                _buildDetailRow('OTP', booking.otp!),
              if (booking.isUsed)
                _buildDetailRow('Status', 'USED', color: '#4CAF50'),
            ],
          ),
        ),
        actions: [
          if (booking.paymentStatus == 'pending')
            TextButton(
              onPressed: () async {
                // Close dialog first
                Navigator.of(dialogContext).pop();
                // Then update status
                await _updateBookingStatus(booking, 'cancelled');
              },
              child: const Text('Cancel Booking'),
            ),
          if (booking.paymentStatus == 'pending')
            ElevatedButton(
              onPressed: () async {
                // Close dialog first
                Navigator.of(dialogContext).pop();
                // Then update status
                await _updateBookingStatus(booking, 'paid');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Paid'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {String? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color != null
                    ? Color(
                        int.parse(color.substring(1), radix: 16) | 0xFF000000)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(Booking booking, String status) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updating booking status...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final response = await _bookingService.updateBooking(
        booking.id,
        {'paymentStatus': status},
      );

      if (!mounted) return;

      if (response['success']) {
        // Reload bookings
        await _loadBookings();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking marked as ${status.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating booking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showBookingDialog([Booking? booking]) async {
    final _formKey = GlobalKey<FormState>();
    String? selectedClientId = booking?.clientId;
    String? selectedSlotId = booking?.slotId;

    // Set initial date - use today's date for past dates when creating new booking
    // Set initial date - use today's date for past dates when creating new booking
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final initialDate = booking != null
        ? DateTime.parse(booking.date)
        : DateTime.parse(DateFormat('yyyy-MM-dd').format(_selectedDate))
                .isBefore(today)
            ? today
            : _selectedDate;

    final _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(initialDate),
    );
    List<User> clients = [];
    List<Slot> slots = [];
    bool isLoading = true;
    String? error;

    // Load clients and slots
    try {
      final clientsResponse = await _userService.getAllUsers();
      final slotsResponse = await _slotService.getAllSlots();

      if (clientsResponse['success'] && slotsResponse['success']) {
        clients = (clientsResponse['data'] as List<User>)
            .where((user) => user.role == 'client')
            .toList();
        slots = slotsResponse['data'] as List<Slot>;
        isLoading = false;
      } else {
        error = 'Failed to load data';
        isLoading = false;
      }
    } catch (e) {
      error = 'An error occurred';
      isLoading = false;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking == null ? 'Create New Booking' : 'Edit Booking'),
        content: SingleChildScrollView(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Text(error)
                  : Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Client Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedClientId,
                            decoration: const InputDecoration(
                              labelText: 'Client',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: clients.map((client) {
                              return DropdownMenuItem(
                                value: client.id,
                                child: Text(client.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedClientId = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a client';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Slot Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedSlotId,
                            decoration: const InputDecoration(
                              labelText: 'Time Slot',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            items: slots.map((slot) {
                              return DropdownMenuItem(
                                value: slot.id,
                                child: Text(
                                    '${slot.startTime} - ${slot.endTime} (\$${slot.price})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedSlotId = value;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a time slot';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Date Picker
                          TextFormField(
                            controller: _dateController,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.parse(
                                                _dateController.text)
                                            .isBefore(today)
                                        ? today
                                        : DateTime.parse(_dateController.text),
                                    firstDate: booking != null
                                        ? today // Allow only today and future dates for updates
                                        : today, // Allow only today and future dates for new bookings
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    _dateController.text =
                                        DateFormat('yyyy-MM-dd').format(picked);
                                  }
                                },
                              ),
                            ),
                            readOnly: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a date';
                              }
                              // Validate that selected date is not in the past for new bookings
                              if (booking == null) {
                                final selectedDate = DateTime.parse(value);
                                final today = DateTime(DateTime.now().year,
                                    DateTime.now().month, DateTime.now().day);
                                if (selectedDate.isBefore(today)) {
                                  return 'Cannot book slots for past dates';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final response = booking == null
                    ? await _bookingService.createBookingByManager(
                        clientId: selectedClientId!,
                        slotId: selectedSlotId!,
                        date: _dateController.text,
                      )
                    : await _bookingService.updateBooking(
                        booking.id,
                        {
                          'clientId': selectedClientId,
                          'slotId': selectedSlotId,
                          'date': _dateController.text,
                        },
                      );

                if (!mounted) return;
                Navigator.pop(context);

                if (response['success']) {
                  _loadBookings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(booking == null
                          ? 'Booking created successfully'
                          : 'Booking updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(booking == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _bookingService.deleteBooking(booking.id);
      if (mounted) {
        if (response['success']) {
          _loadBookings();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by client name or phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _loadBookings(); // Reload with date filter
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            if (_searchQuery.isNotEmpty) {
              // Delay the search to avoid too many API calls
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchQuery == value) {
                  _loadBookings();
                }
              });
            } else {
              _loadBookings(); // Reload with date filter when search is cleared
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _searchQuery.isEmpty
                ? _selectDate
                : null, // Disable date selection during search
          ),
        ],
      ),
      body: Column(
        children: [
          // Show date selector only when not searching
          if (_searchQuery.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bookings for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
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

          _buildSearchBar(),

          // Bookings list with search results
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
                              onPressed: _loadBookings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredBookings.isEmpty
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
                                  _searchQuery.isEmpty
                                      ? 'No bookings found for this date'
                                      : 'No bookings match your search',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredBookings.length,
                              itemBuilder: (context, index) {
                                final booking = _filteredBookings[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    onTap: () => _showBookingDetails(booking),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: Text(
                                        booking.client!.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${booking.slot!.startTime} - ${booking.slot!.endTime}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(booking.client!.name),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              int.parse(
                                                    _getStatusColor(booking
                                                            .paymentStatus)
                                                        .substring(1),
                                                    radix: 16,
                                                  ) |
                                                  0x33000000,
                                            ),
                                          ),
                                          child: Text(
                                            booking.paymentStatus.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(
                                                int.parse(
                                                      _getStatusColor(booking
                                                              .paymentStatus)
                                                          .substring(1),
                                                      radix: 16,
                                                    ) |
                                                    0xFF000000,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _showBookingDialog(booking),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () =>
                                              _deleteBooking(booking),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: _searchQuery.isEmpty
          ? FloatingActionButton(
              onPressed: () => _showBookingDialog(),
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB during search
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
