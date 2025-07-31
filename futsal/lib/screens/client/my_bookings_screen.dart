import 'package:flutter/material.dart';
import 'package:futsal/models/booking.dart';
import 'package:futsal/services/booking_service.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'upcoming'; // upcoming, past, all

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
      final response = await _bookingService.getMyBookings();
      if (response['success']) {
        setState(() {
          _bookings = (response['data'] as List<Booking>)
            ..sort((a, b) => a.localDate.compareTo(b.localDate));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Booking> get _filteredBookings {
    final now = DateTime.now();
    return _bookings.where((booking) {
      final bookingDate = booking.localDate;
      switch (_selectedFilter) {
        case 'upcoming':
          return bookingDate.isAfter(now.subtract(const Duration(days: 1)));
        case 'past':
          return bookingDate.isBefore(now);
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _showBookingDetails(Booking booking) async {
    final bookingDate = booking.localDate;
    final isUpcoming =
        bookingDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'Date', DateFormat('MMM dd, yyyy').format(bookingDate)),
              _buildDetailRow('Time',
                  '${booking.slot?.startTime ?? 'N/A'} - ${booking.slot?.endTime ?? 'N/A'}'),
              _buildDetailRow(
                  'Amount', '\$${booking.amount.toStringAsFixed(2)}'),
              _buildDetailRow(
                'Status',
                booking.paymentStatus.toUpperCase(),
                // color: _getStatusColor(booking.paymentStatus),
              ),
              if (booking.referenceId != null)
                _buildDetailRow('Reference', booking.referenceId!),
              if (booking.otp != null && !booking.isUsed && isUpcoming)
                _buildDetailRow(
                  'OTP',
                  booking.otp!,
                  subtitle: 'Show this code at the venue',
                ),
              if (booking.isUsed)
                _buildDetailRow('Usage', 'USED', color: '#4CAF50'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {String? subtitle, String? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color != null
                        ? Color(int.parse(color.replaceAll('#', '0xFF')))
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
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
              colors: [Colors.green.shade600, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Enhanced filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip('Upcoming', 'upcoming'),
                const SizedBox(width: 8),
                _buildFilterChip('Past', 'past'),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all'),
              ],
            ),
          ),
          // Bookings list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildModernErrorState()
                    : _filteredBookings.isEmpty
                        ? _buildModernEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredBookings.length,
                              itemBuilder: (context, index) {
                                final booking = _filteredBookings[index];
                                final bookingDate = booking.localDate;
                                final isUpcoming = bookingDate.isAfter(
                                    DateTime.now()
                                        .subtract(const Duration(days: 1)));
                                return _buildModernBookingCard(
                                    booking, bookingDate, isUpcoming);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBookingCard(
      Booking booking, DateTime bookingDate, bool isUpcoming) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showBookingDetails(booking),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Date and time info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM dd, yyyy').format(bookingDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.slot?.startTime ?? 'N/A'} - ${booking.slot?.endTime ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status and amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: booking.paymentStatus == 'paid'
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: booking.paymentStatus == 'paid'
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${booking.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (booking.otp != null &&
                        !booking.isUsed &&
                        isUpcoming) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'OTP: ${booking.otp!}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                    if (booking.isUsed) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'USED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
              Icons.book_online_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any bookings yet.',
            style: TextStyle(
              color: Colors.grey.shade500,
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
            onPressed: _loadBookings,
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
