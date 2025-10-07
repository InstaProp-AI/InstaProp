import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auction.dart';

class AuctionTimer extends StatefulWidget {
  final Auction auction;
  final TextStyle? textStyle;
  final VoidCallback? onAuctionEnded;

  const AuctionTimer({
    super.key,
    required this.auction,
    this.textStyle,
    this.onAuctionEnded,
  });

  @override
  State<AuctionTimer> createState() => _AuctionTimerState();
}

class _AuctionTimerState extends State<AuctionTimer> {
  late DateTime _endTime;
  String _timeRemaining = '';
  Timer? _timer;
  bool _wasActive = true;

  @override
  void initState() {
    super.initState();
    _endTime = widget.auction.endAt;
    _updateTimeRemaining();

    // Start timer that updates every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final isNowEnded = now.isAfter(_endTime);

    if (isNowEnded) {
      _timeRemaining = 'Ended';

      // If auction just ended (was active before, now ended), trigger callback
      if (_wasActive && widget.onAuctionEnded != null) {
        widget.onAuctionEnded!();
        _wasActive = false;
      }
    } else {
      _wasActive = true;
      final remaining = _endTime.difference(now);

      if (remaining.inDays > 0) {
        _timeRemaining = '${remaining.inDays}d ${remaining.inHours % 24}h';
      } else if (remaining.inHours > 0) {
        _timeRemaining = '${remaining.inHours}h ${remaining.inMinutes % 60}m';
      } else if (remaining.inMinutes > 0) {
        _timeRemaining = '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
      } else {
        _timeRemaining = '${remaining.inSeconds}s';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        DateTime.now().isBefore(_endTime) && widget.auction.status == 'Active';

    return Text(
      _timeRemaining,
      style:
          widget.textStyle?.copyWith(
            color: isActive ? Colors.redAccent : Colors.grey,
          ) ??
          TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.redAccent : Colors.grey,
          ),
    );
  }
}
