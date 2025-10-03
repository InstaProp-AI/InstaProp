import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'main.dart';
import 'i18n.dart';

class InstallmentReminder {
  final String propertyName;
  final String note;
  final double amount;
  final TimeOfDay time;

  const InstallmentReminder({
    required this.propertyName,
    required this.note,
    required this.amount,
    required this.time,
  });
}

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});

  @override
  State<CalenderPage> createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> {
  late final ValueNotifier<List<InstallmentReminder>> _selectedReminders;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Simple in-memory reminders map keyed by date (at midnight)
  final Map<DateTime, List<InstallmentReminder>> _reminders = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
    _seedDemoData();
    _selectedReminders = ValueNotifier(_getRemindersForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedReminders.dispose();
    super.dispose();
  }

  void _seedDemoData() {
    // Seed a few demo installment reminders for illustration
    void add(DateTime date, InstallmentReminder r) {
      final key = DateTime(date.year, date.month, date.day);
      _reminders.putIfAbsent(key, () => []);
      _reminders[key]!.add(r);
    }

    final now = DateTime.now();
    add(
      now,
      const InstallmentReminder(
        propertyName: 'Luxury Villa',
        note: 'Monthly installment',
        amount: 15000,
        time: TimeOfDay(hour: 10, minute: 0),
      ),
    );
    add(
      now.add(const Duration(days: 2)),
      const InstallmentReminder(
        propertyName: 'Downtown Apartment',
        note: 'Quarterly payment',
        amount: 32000,
        time: TimeOfDay(hour: 14, minute: 30),
      ),
    );
    add(
      DateTime(now.year, now.month, 1).add(const Duration(days: 27)),
      const InstallmentReminder(
        propertyName: 'Cozy Cottage',
        note: 'Second installment',
        amount: 9000,
        time: TimeOfDay(hour: 9, minute: 0),
      ),
    );
  }

  List<InstallmentReminder> _getRemindersForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _reminders[key] ?? const [];
  }

  // Range helper can be added later if needed

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedReminders.value = _getRemindersForDay(selectedDay);
    }
  }

  void _addReminder() async {
    final selectedDate = _selectedDay ?? _focusedDay;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;

    if (!mounted) return;
    final controller = TextEditingController();
    double? amount;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Installment Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Property name'),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (EGP)'),
                onChanged: (v) => amount = double.tryParse(v),
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
                if (controller.text.isEmpty || amount == null) return;
                final entry = InstallmentReminder(
                  propertyName: controller.text,
                  note: 'Custom reminder',
                  amount: amount!,
                  time: time,
                );
                final key = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                );
                _reminders.putIfAbsent(key, () => []);
                _reminders[key]!.add(entry);
                _selectedReminders.value = _getRemindersForDay(key);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Strings.of(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          t.installmentCalendar,
          style: TextStyle(color: kText, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: kText),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar<InstallmentReminder>(
                firstDay: DateTime.utc(2010, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: true,
                  titleTextStyle: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.bold,
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  formatButtonDecoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  markerDecoration: BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                eventLoader: (day) => _getRemindersForDay(day),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, reminders) {
                    if (reminders.isEmpty) return null;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            reminders.length.clamp(0, 3),
                            (i) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: i == 0 ? kPrimary : kAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.alarm, color: kPrimary),
                const SizedBox(width: 8),
                Text(
                  _selectedDay == null
                      ? t.reminders
                      : t.remindersFor(_selectedDay!),
                  style: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addReminder,
                  icon: const Icon(Icons.add),
                  label: Text(t.add),
                  style: TextButton.styleFrom(foregroundColor: kPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ValueListenableBuilder<List<InstallmentReminder>>(
              valueListenable: _selectedReminders,
              builder: (context, reminders, _) {
                if (reminders.isEmpty) {
                  return Center(
                    child: Text(
                      t.noReminders,
                      style: TextStyle(color: kText.withOpacity(0.7)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: reminders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = reminders[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: kPrimary,
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          r.propertyName,
                          style: TextStyle(
                            color: kText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${r.note} • ${r.time.format(context)}',
                          style: TextStyle(color: kText.withOpacity(0.7)),
                        ),
                        trailing: Text(
                          'EGP ${r.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
