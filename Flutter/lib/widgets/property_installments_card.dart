import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class PropertyInstallmentsCard extends StatefulWidget {
  final int propertyId;
  final VoidCallback? onPaymentMade;

  const PropertyInstallmentsCard({
    super.key,
    required this.propertyId,
    this.onPaymentMade,
  });

  @override
  State<PropertyInstallmentsCard> createState() =>
      _PropertyInstallmentsCardState();
}

class _PropertyInstallmentsCardState extends State<PropertyInstallmentsCard> {
  List<Event> _installments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  Future<void> _loadInstallments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await EventService.getEventsByProperty(
        widget.propertyId,
      );

      if (response.success && response.data != null) {
        setState(() {
          _installments =
              response.data!
                  .where((event) => event.type == EventType.installment)
                  .toList()
                ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load installments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsPaid(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Mark installment of \$${event.amount?.toStringAsFixed(0) ?? "0"} as paid?',
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
          await _loadInstallments();
          widget.onPaymentMade?.call();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_installments.isEmpty) {
      return const SizedBox.shrink();
    }

    final unpaidInstallments = _installments
        .where((e) => !e.isCompleted)
        .toList();
    final paidInstallments = _installments.where((e) => e.isCompleted).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Installments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (unpaidInstallments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      '${unpaidInstallments.length} unpaid',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total',
                    _installments.length.toString(),
                    Icons.list,
                    Colors.blue,
                  ),
                  _buildSummaryItem(
                    'Paid',
                    paidInstallments.length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildSummaryItem(
                    'Unpaid',
                    unpaidInstallments.length.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ],
              ),
            ),

            if (unpaidInstallments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Upcoming Payments',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              ...unpaidInstallments
                  .take(5)
                  .map((event) => _buildInstallmentItem(event, false)),
              if (unpaidInstallments.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${unpaidInstallments.length - 5} more',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],

            if (paidInstallments.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'Paid Installments (${paidInstallments.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                children: paidInstallments
                    .take(5)
                    .map((event) => _buildInstallmentItem(event, true))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildInstallmentItem(Event event, bool isPaid) {
    final daysUntil = event.eventDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntil < 0 && !isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid
              ? Colors.green.withOpacity(0.3)
              : isOverdue
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? Colors.green
                  : isOverdue
                  ? Colors.red
                  : Colors.orange,
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
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (event.amount != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
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
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 11,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.eventDate.year}-${event.eventDate.month.toString().padLeft(2, '0')}-${event.eventDate.day.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    if (!isPaid)
                      Text(
                        isOverdue
                            ? 'Overdue ${-daysUntil} days'
                            : daysUntil == 0
                            ? 'Due today'
                            : daysUntil == 1
                            ? 'Due tomorrow'
                            : 'Due in $daysUntil days',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOverdue ? Colors.red : Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!isPaid)
            ElevatedButton(
              onPressed: () => _markAsPaid(event),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('I Have Paid', style: TextStyle(fontSize: 11)),
            )
          else
            Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
