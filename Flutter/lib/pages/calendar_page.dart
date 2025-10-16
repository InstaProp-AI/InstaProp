import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/api_client.dart';
import 'add_event_dialog.dart';
import 'event_details_dialog.dart';
import 'add_event_choice_dialog.dart';
import 'payment_schedule_scanner_dialog.dart';
import 'auth_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();

      ApiResponse<List<Event>> response;

      if (appState.isLoggedIn) {
        // Load user's personal events + public events
        response = await EventService.getEventsByMonth(
          _currentMonth.year,
          _currentMonth.month,
        );
      } else {
        // Load only public events for non-logged users
        response = await EventService.getPublicEventsByMonth(
          _currentMonth.year,
          _currentMonth.month,
        );
      }

      if (response.success && response.data != null) {
        setState(() {
          _events = response.data!;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load events';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading events: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadEvents();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _showAddEventDialog() async {
    final appState = context.read<AppState>();

    // First, show choice dialog
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => const AddEventChoiceDialog(),
    );

    if (choice == null) return;

    // Check if user is logged in before proceeding
    if (!appState.isLoggedIn) {
      _showSignupPrompt();
      return;
    }

    if (choice == 'manual') {
      // Show manual event dialog
      final result = await showDialog<Event>(
        context: context,
        builder: (context) => const AddEventDialog(),
      );
      if (result != null) {
        _loadEvents();
      }
    } else if (choice == 'scan') {
      // Show payment schedule scanner dialog
      final result = await showDialog<PaymentScheduleScanResult>(
        context: context,
        builder: (context) => const PaymentScheduleScannerDialog(),
      );

      if (result != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reload events
        _loadEvents();
      }
    }
  }

  void _showSignupPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Sign Up Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You need to create an account to use this feature.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sign up now to add and manage your calendar events!',
                      style: TextStyle(fontSize: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEventDetails(Event event) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EventDetailsDialog(
        event: event,
        onEventUpdated: () {
          // Refresh events when an event is marked as paid
          _loadEvents();
        },
      ),
    );

    // Refresh events if dialog returned true (event was updated)
    if (result == true && mounted) {
      await _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Show public calendar if not authenticated
    if (!appState.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Public Calendar'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: AppColors.surface,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEventDialog,
              tooltip: 'Add Event',
            ),
          ],
        ),
        body: _buildCalendarContent(),
      );
    }

    // Show full calendar for logged-in users
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
            tooltip: 'Add Event',
          ),
        ],
      ),
      body: _buildCalendarContent(),
    );
  }

  Widget _buildCalendarContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Events',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadEvents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Always show the calendar, even if there are no events

    return SingleChildScrollView(
      child: Column(
        children: [
          // Month Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const Divider(),

          // Calendar Grid
          SizedBox(
            height: 400, // Fixed height for calendar
            child: _buildCalendarGrid(),
          ),

          // Next Events Section
          _buildNextEventsSection(),

          // Events List for Selected Date
          if (_selectedDate != null) _buildEventsForSelectedDate(),

          // Public Events Info (only for non-logged users)
          if (!context.read<AppState>().isLoggedIn)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Viewing public events only. Log in to see your personal calendar.',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final firstDayOfWeek =
        firstDayOfMonth.weekday % 7; // Convert to 0-based Sunday start

    final daysInMonth = lastDayOfMonth.day;
    final totalCells = firstDayOfWeek + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day headers
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: weeks,
              itemBuilder: (context, weekIndex) {
                return Row(
                  children: List.generate(7, (dayIndex) {
                    final cellIndex = weekIndex * 7 + dayIndex;
                    final dayNumber = cellIndex - firstDayOfWeek + 1;

                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 40));
                    }

                    final date = DateTime(
                      _currentMonth.year,
                      _currentMonth.month,
                      dayNumber,
                    );
                    final dayEvents = _getEventsForDate(date);
                    final isSelected =
                        _selectedDate?.day == dayNumber &&
                        _selectedDate?.month == _currentMonth.month &&
                        _selectedDate?.year == _currentMonth.year;
                    final isToday =
                        date.day == DateTime.now().day &&
                        date.month == DateTime.now().month &&
                        date.year == DateTime.now().year;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onDateSelected(date),
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : isToday
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1)
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            border: isToday
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.surface
                                        : isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ),
                              if (dayEvents.isNotEmpty)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.surface
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsForSelectedDate() {
    final selectedDateEvents = _getEventsForDate(_selectedDate!);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events for ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.day}, ${_selectedDate!.year}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selectedDateEvents.isEmpty
                ? Center(
                    child: Text(
                      'No events for this date',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedDateEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedDateEvents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: event.type.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(event.title),
                          subtitle: event.description != null
                              ? Text(event.description!)
                              : null,
                          trailing: event.startTime != null
                              ? Text(_formatTime(event.startTime!))
                              : null,
                          onTap: () => _showEventDetails(event),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Event> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      return event.eventDate.year == date.year &&
          event.eventDate.month == date.month &&
          event.eventDate.day == date.day;
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildNextEventsSection() {
    final now = DateTime.now();
    // Start from today (midnight) for proper date comparison
    final today = DateTime(now.year, now.month, now.day);
    final twoMonthsFromNow = today.add(const Duration(days: 60));

    final upcomingEvents = _events.where((event) {
      final eventDate = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      // Include events from today onwards (not completed)
      return (eventDate.isAtSameMomentAs(today) || eventDate.isAfter(today)) &&
          eventDate.isBefore(twoMonthsFromNow) &&
          !event.isCompleted;
    }).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upcoming, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upcoming Events (Next 2 Months)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${upcomingEvents.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcomingEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming events in the next 2 months',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...upcomingEvents
                .take(10)
                .map((event) => _buildNextEventItem(event)),
            if (upcomingEvents.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+${upcomingEvents.length - 10} more events',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextEventItem(Event event) {
    final daysUntil = event.eventDate.difference(DateTime.now()).inDays;
    final eventColor = event.type.color;
    final isInstallment = event.type == EventType.installment;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.background),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showEventDetails(event),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: eventColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (event.amount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '\$${event.amount!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.eventDate.year}-${event.eventDate.month.toString().padLeft(2, '0')}-${event.eventDate.day.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: eventColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                daysUntil == 0
                                    ? 'Today'
                                    : daysUntil == 1
                                    ? 'Tomorrow'
                                    : 'In $daysUntil days',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: eventColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (event.description != null &&
                            event.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              event.description!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
          if (isInstallment && !event.isCompleted)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: () async {
                  await _markEventAsPaid(event);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'I Have Paid',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markEventAsPaid(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Mark "${event.title}" as paid?'),
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final response = await EventService.completeEvent(event.eventId);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment marked as completed!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await _loadEvents();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${response.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Removed unused _formatDate method
}
