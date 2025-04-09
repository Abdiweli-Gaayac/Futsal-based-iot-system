import 'package:flutter/material.dart';
import 'package:futsal/models/slot.dart';
import 'package:futsal/services/slot_service.dart';
import 'package:intl/intl.dart';

class SlotsScreen extends StatefulWidget {
  const SlotsScreen({super.key});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  final SlotService _slotService = SlotService();
  List<Slot> _slots = [];
  bool _isLoading = true;
  String? _error;

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
      final response = await _slotService.getAllSlots();
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

  Future<void> _showSlotDialog([Slot? slot]) async {
    final _formKey = GlobalKey<FormState>();
    final _startTimeController = TextEditingController(text: slot?.startTime);
    final _endTimeController = TextEditingController(text: slot?.endTime);
    final _priceController =
        TextEditingController(text: slot?.price.toString() ?? '');

    Future<void> _selectTime(
        BuildContext context, TextEditingController controller) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: controller.text.isNotEmpty
            ? TimeOfDay(
                hour: int.parse(controller.text.split(':')[0]),
                minute: int.parse(controller.text.split(':')[1]),
              )
            : TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true, // Force 24-hour format
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        // Format time to always show leading zeros
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        controller.text = '$hour:$minute';
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(slot == null ? 'Add New Slot' : 'Edit Slot'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start Time Field
              TextFormField(
                controller: _startTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () => _selectTime(context, _startTimeController),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select start time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // End Time Field
              TextFormField(
                controller: _endTimeController,
                decoration: InputDecoration(
                  labelText: 'End Time',
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () => _selectTime(context, _endTimeController),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select end time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
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
                final response = slot == null
                    ? await _slotService.createSlot(
                        _startTimeController.text,
                        _endTimeController.text,
                        double.parse(_priceController.text),
                      )
                    : await _slotService.updateSlot(
                        slot.id,
                        {
                          'startTime': _startTimeController.text,
                          'endTime': _endTimeController.text,
                          'price': double.parse(_priceController.text),
                        },
                      );

                if (mounted) {
                  Navigator.pop(context);
                  if (response['success']) {
                    _loadSlots();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(slot == null
                            ? 'Slot created successfully'
                            : 'Slot updated successfully'),
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
            },
            child: Text(slot == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSlot(Slot slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this slot?'),
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
      final response = await _slotService.deleteSlot(slot.id);
      if (mounted) {
        if (response['success']) {
          _loadSlots();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Slot deleted successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Slots'),
      ),
      body: _isLoading
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showSlotDialog(slot),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _deleteSlot(slot),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSlotDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
