import 'package:flutter/material.dart';
import 'package:futsal/models/subscription.dart';
import 'package:futsal/services/subscription_service.dart';
import 'package:intl/intl.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // all, active, expired, cancelled

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _subscriptionService.getMySubscriptions(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (response.success) {
        setState(() {
          _subscriptions = response.data as List<Subscription>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              response.message?.toString() ?? 'Failed to load subscriptions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscriptions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Subscription> get _filteredSubscriptions {
    return _subscriptions.where((subscription) {
      switch (_selectedFilter) {
        case 'active':
          return subscription.isActive;
        case 'expired':
          return subscription.isExpired;
        case 'cancelled':
          return subscription.isCancelled;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _showSubscriptionDetails(Subscription subscription) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Day', subscription.dayOfWeekName),
              _buildDetailRow('Time',
                  '${subscription.slot?.startTime} - ${subscription.slot?.endTime}'),
              _buildDetailRow(
                  'Start Date',
                  DateFormat('MMM dd, yyyy')
                      .format(subscription.localStartDate)),
              _buildDetailRow('End Date',
                  DateFormat('MMM dd, yyyy').format(subscription.localEndDate)),
              _buildDetailRow('Monthly Amount',
                  '\$${subscription.monthlyAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Status', subscription.status.toUpperCase()),
              _buildDetailRow(
                  'Payment Status', subscription.paymentStatus.toUpperCase()),
              _buildDetailRow(
                  'Auto Renew', subscription.autoRenew ? 'Yes' : 'No'),
              if (subscription.referenceId != null)
                _buildDetailRow('Reference ID', subscription.referenceId!),
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

  Widget _buildDetailRow(String label, String value, {String? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
          _loadSubscriptions();
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
          'My Subscriptions',
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
              colors: [Colors.purple.shade600, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
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
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Expired', 'expired'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          // Subscriptions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildModernErrorState()
                    : _filteredSubscriptions.isEmpty
                        ? _buildModernEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadSubscriptions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSubscriptions.length,
                              itemBuilder: (context, index) {
                                final subscription =
                                    _filteredSubscriptions[index];
                                return _buildModernSubscriptionCard(
                                    subscription);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSubscriptionCard(Subscription subscription) {
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
          onTap: () => _showSubscriptionDetails(subscription),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.dayOfWeekName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subscription.slot?.startTime} - ${subscription.slot?.endTime}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: subscription.isActive
                                ? Colors.green.shade100
                                : subscription.isExpired
                                    ? Colors.orange.shade100
                                    : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subscription.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: subscription.isActive
                                  ? Colors.green.shade700
                                  : subscription.isExpired
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u0024${subscription.monthlyAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${DateFormat('MMM dd').format(subscription.localStartDate)} - ${DateFormat('MMM dd, yyyy').format(subscription.localEndDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (subscription.paymentStatus == 'paid')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PAID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
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
              Icons.subscriptions_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No subscriptions found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t subscribed to any slots yet.',
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
            _error?.toString() ?? 'Unknown error',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSubscriptions,
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
