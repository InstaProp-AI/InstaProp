import 'package:flutter/material.dart';
import '../models/auction.dart';

class AuctionTimer extends StatefulWidget {
  final Auction auction;
  final TextStyle? textStyle;

  const AuctionTimer({super.key, required this.auction, this.textStyle});

  @override
  State<AuctionTimer> createState() => _AuctionTimerState();
}

class _AuctionTimerState extends State<AuctionTimer> {
  late DateTime _endTime;
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _endTime = widget.auction.endAt;
    _updateTimeRemaining();

    // Update every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
        });
        return true;
      }
      return false;
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(_endTime)) {
      _timeRemaining = 'Ended';
    } else {
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
