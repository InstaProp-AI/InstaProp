import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/reward_popup.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController = TextEditingController();
  final _recurrenceIntervalController = TextEditingController(text: '1');

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  EventType _selectedType = EventType.other;
  bool _isAllDay = true;
  bool _isLoading = false;
  bool _showAmountField = false;

  // Recurring event fields
  bool _isRecurring = false;
  RecurrencePattern _recurrencePattern = RecurrencePattern.daily;
  DateTime? _recurrenceEndDate;
  int? _recurrenceCount;
  String _recurrenceEndType = 'never'; // 'never', 'date', 'count'

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _recurrenceIntervalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? _selectedDate.add(const Duration(days: 30)),
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        _recurrenceEndDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation for recurring events
    if (_isRecurring) {
      final interval = int.tryParse(_recurrenceIntervalController.text);
      if (interval == null || interval < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid recurrence interval'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_recurrenceEndType == 'date' && _recurrenceEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an end date for recurring event'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_recurrenceEndType == 'count' &&
          (_recurrenceCount == null || _recurrenceCount! < 1)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid occurrence count'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final eventDto = EventCreateDto(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        eventDate: _selectedDate,
        type: _selectedType,
        location: _locationController.text.isEmpty
            ? null
            : _locationController.text,
        isAllDay: _isAllDay,
        startTime: _isAllDay || _startTime == null
            ? null
            : DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _startTime!.hour,
                _startTime!.minute,
              ),
        amount: _showAmountField && _amountController.text.isNotEmpty
            ? double.tryParse(_amountController.text)
            : null,
        isRecurring: _isRecurring,
        recurrencePattern: _isRecurring ? _recurrencePattern : null,
        recurrenceInterval: _isRecurring
            ? int.tryParse(_recurrenceIntervalController.text)
            : null,
        recurrenceEndDate: _isRecurring && _recurrenceEndType == 'date'
            ? _recurrenceEndDate
            : null,
        recurrenceCount: _isRecurring && _recurrenceEndType == 'count'
            ? _recurrenceCount
            : null,
      );

      final response = await EventService.createEvent(eventDto);
      if (response.success) {
        if (mounted) {
          // Show reward popup
          final appState = context.read<AppState>();
          await appState.refreshUserProfile();
          if (mounted && appState.user?.totalPoints != null) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => RewardPopup(
                pointsAwarded: 2,
                totalPoints: appState.user!.totalPoints!,
              ),
            );
          }
          if (mounted) {
            Navigator.of(context).pop(response.data);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to create event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onEventTypeSelected(EventType type) {
    setState(() {
      _selectedType = type;
      // Show amount field for payment-related events
      _showAmountField =
          type == EventType.installment || type == EventType.maintenance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfo(),
                      const SizedBox(height: 24),
                      _buildEventTypeSelector(),
                      const SizedBox(height: 24),
                      _buildDateTimeSection(),
                      if (_showAmountField) ...[
                        const SizedBox(height: 24),
                        _buildAmountField(),
                      ],
                      const SizedBox(height: 24),
                      _buildRecurringSection(),
                      const SizedBox(height: 24),
                      _buildLocationField(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available,
              color: AppColors.surface,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Event',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add an event to your calendar',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.surface),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Event Title *',
            hintText: 'e.g., Payment Due, Property Visit',
            prefixIcon: const Icon(Icons.title, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.background,
          ),
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter a title' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Add more details about this event',
            prefixIcon: const Icon(Icons.description, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.background,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildEventTypeSelector() {
    final eventTypes = [
      _EventTypeInfo(
        EventType.installment,
        'Payment',
        Icons.payments,
        Colors.blue,
      ),
      _EventTypeInfo(
        EventType.propertyInspection,
        'Inspection',
        Icons.search,
        Colors.green,
      ),
      _EventTypeInfo(EventType.meeting, 'Meeting', Icons.people, Colors.indigo),
      _EventTypeInfo(
        EventType.maintenance,
        'Maintenance',
        Icons.build,
        Colors.brown,
      ),
      _EventTypeInfo(
        EventType.contractSigning,
        'Contract',
        Icons.edit_document,
        Colors.purple,
      ),
      _EventTypeInfo(EventType.other, 'Other', Icons.event, Colors.grey),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: eventTypes.map((typeInfo) {
            final isSelected = _selectedType == typeInfo.type;
            return GestureDetector(
              onTap: () => _onEventTypeSelected(typeInfo.type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? typeInfo.color.withOpacity(0.15)
                      : AppColors.background,
                  border: Border.all(
                    color: isSelected ? typeInfo.color : AppColors.secondary,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      typeInfo.icon,
                      color: isSelected ? typeInfo.color : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typeInfo.label,
                      style: TextStyle(
                        color: isSelected ? typeInfo.color : AppColors.primary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.secondary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.secondary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('All Day Event', style: TextStyle(fontSize: 16)),
              ),
              Switch(
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value;
                    if (value) {
                      _startTime = null;
                    }
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (!_isAllDay) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.secondary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          _startTime != null
                              ? _startTime!.format(context)
                              : 'Select time',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount (Optional)',
            hintText: '0.00',
            prefixIcon: const Icon(
              Icons.attach_money,
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.background,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
      ],
    );
  }

  Widget _buildRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Repeat Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            Switch(
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.repeat,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recurrence Pattern',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _recurrenceIntervalController,
                        decoration: InputDecoration(
                          labelText: 'Every',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<RecurrencePattern>(
                        value: _recurrencePattern,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: RecurrencePattern.values.map((pattern) {
                          return DropdownMenuItem(
                            value: pattern,
                            child: Text(pattern.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _recurrencePattern = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ends',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Never'),
                  value: 'never',
                  groupValue: _recurrenceEndType,
                  onChanged: (value) {
                    setState(() {
                      _recurrenceEndType = value!;
                    });
                  },
                  dense: true,
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('On '),
                      if (_recurrenceEndType == 'date' &&
                          _recurrenceEndDate != null)
                        Text(
                          '${_recurrenceEndDate!.day}/${_recurrenceEndDate!.month}/${_recurrenceEndDate!.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  value: 'date',
                  groupValue: _recurrenceEndType,
                  onChanged: (value) {
                    setState(() {
                      _recurrenceEndType = value!;
                    });
                    if (value == 'date') {
                      _selectRecurrenceEndDate();
                    }
                  },
                  dense: true,
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('After '),
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: _recurrenceCount?.toString() ?? '10',
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            _recurrenceCount = int.tryParse(value);
                          },
                          enabled: _recurrenceEndType == 'count',
                        ),
                      ),
                      const Text(' occurrences'),
                    ],
                  ),
                  value: 'count',
                  groupValue: _recurrenceEndType,
                  onChanged: (value) {
                    setState(() {
                      _recurrenceEndType = value!;
                      _recurrenceCount = 10;
                    });
                  },
                  dense: true,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location (Optional)',
            hintText: 'e.g., Office, Property Address',
            prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.secondary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.surface,
                      ),
                    ),
                  )
                : const Text(
                    'Create Event',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventTypeInfo {
  final EventType type;
  final String label;
  final IconData icon;
  final Color color;

  _EventTypeInfo(this.type, this.label, this.icon, this.color);
}
