import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> eventDates;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.eventDates = const [],
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
    _selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
      _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Get the first day of the week (0 = Sunday, 1 = Monday, etc.)
    final firstWeekday = firstDay.weekday;

    List<DateTime> days = [];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      days.add(
        DateTime(
          firstDay.year,
          firstDay.month,
          1 - i,
        ).subtract(Duration(days: i - 1)),
      );
    }

    // Add all days in the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }

    return days;
  }

  bool _hasEvent(DateTime date) {
    return widget.eventDates.any(
      (eventDate) =>
          eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day,
    );
  }

  bool _isSelected(DateTime date) {
    return _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == _currentMonth.year && date.month == _currentMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final monthNames = [
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
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary!),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with month/year and navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.surface,
                  ),
                ),
                Text(
                  '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),

          // Weekday headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.secondary!)),
            ),
            child: Row(
              children: weekdayNames
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final hasEvent = _hasEvent(date);
                final isSelected = _isSelected(date);
                final isToday = _isToday(date);
                final isCurrentMonth = _isCurrentMonth(date);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected(date);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.surface
                                  : isToday
                                  ? AppColors.primary
                                  : isCurrentMonth
                                  ? AppColors.textPrimary
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                        if (hasEvent)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.surface
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
