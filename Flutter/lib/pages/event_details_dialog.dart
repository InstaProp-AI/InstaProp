import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventDetailsDialog extends StatefulWidget {
  final Event event;
  final VoidCallback? onEventUpdated;

  const EventDetailsDialog({
    super.key,
    required this.event,
    this.onEventUpdated,
  });

  @override
  State<EventDetailsDialog> createState() => _EventDetailsDialogState();
}

class _EventDetailsDialogState extends State<EventDetailsDialog> {
  bool _isLoading = false;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.event.isCompleted;
  }

  Future<void> _markAsPaid() async {
    setState(() => _isLoading = true);

    try {
      final response = await EventService.completeEvent(widget.event.eventId);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _isCompleted = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment marked as completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Notify parent to refresh
        widget.onEventUpdated?.call();

        // Close dialog after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as paid: ${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInstallment = widget.event.type == EventType.installment;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.event.title)),
          if (isInstallment && widget.event.amount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                '\$${widget.event.amount!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.event.description != null &&
                widget.event.description!.isNotEmpty) ...[
              Text(
                'Description:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.event.description!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(Icons.event, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${widget.event.eventDate.day}/${widget.event.eventDate.month}/${widget.event.eventDate.year}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.label, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(widget.event.type.displayName),
              ],
            ),
            if (widget.event.location != null &&
                widget.event.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.event.location!)),
                ],
              ),
            ],
            if (!widget.event.isAllDay && widget.event.startTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(_formatTime(widget.event.startTime!)),
                ],
              ),
            ],
            if (_isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      isInstallment ? 'Payment Completed' : 'Completed',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.event.isPublic) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.public, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Public Event'),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isInstallment && !_isCompleted)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _markAsPaid,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle, size: 18),
            label: Text(_isLoading ? 'Processing...' : 'I Have Paid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
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
}
