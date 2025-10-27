import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final Color? accentColor;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.textStyle,
    this.accentColor,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remainingTime;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    // Update every second - defer to next frame to avoid layout errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), _tick);
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    if (widget.endTime.isAfter(now)) {
      _remainingTime = widget.endTime.difference(now);
      _isExpired = false;
    } else {
      _remainingTime = const Duration();
      _isExpired = true;
    }
  }

  void _tick() {
    if (mounted) {
      setState(() {
        _updateRemainingTime();
      });
      if (!_isExpired) {
        Future.delayed(const Duration(seconds: 1), _tick);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        widget.textStyle ??
        const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isExpired
            ? Colors.grey
            : (widget.accentColor ?? AppColors.error),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (widget.accentColor ?? AppColors.error).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isExpired ? Icons.schedule : Icons.timer_outlined,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            _isExpired ? 'Expired' : _formatDuration(_remainingTime),
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
