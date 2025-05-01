import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A widget that displays a real-time countdown for streak freeze expiry
class StreakFreezeCountdown extends StatefulWidget {
  final DateTime? expiryTime;
  final bool compact;
  final Color? textColor;

  const StreakFreezeCountdown({
    Key? key,
    required this.expiryTime,
    this.compact = false,
    this.textColor,
  }) : super(key: key);

  @override
  State<StreakFreezeCountdown> createState() => _StreakFreezeCountdownState();
}

class _StreakFreezeCountdownState extends State<StreakFreezeCountdown> {
  late Timer _timer;
  late String _countdownText;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (widget.expiryTime == null) {
      _countdownText = 'Active';
      _remaining = Duration.zero;
      return;
    }

    final now = DateTime.now();
    final difference = widget.expiryTime!.difference(now);
    _remaining = difference;

    if (difference.isNegative) {
      _countdownText = 'Expired';
    } else if (difference.inDays > 0) {
      final hours = difference.inHours - (difference.inDays * 24);
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      if (widget.compact) {
        _countdownText = '${difference.inDays}d ${hours}h ${minutes}m';
      } else {
        _countdownText =
            '${difference.inDays}d ${hours}h ${minutes}m ${seconds}s';
      }
    } else if (difference.inHours > 0) {
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      if (widget.compact) {
        _countdownText = '${difference.inHours}h ${minutes}m';
      } else {
        _countdownText = '${difference.inHours}h ${minutes}m ${seconds}s';
      }
    } else if (difference.inMinutes > 0) {
      final seconds = difference.inSeconds % 60;

      if (widget.compact) {
        _countdownText = '${difference.inMinutes}m ${seconds}s';
      } else {
        _countdownText = '${difference.inMinutes}m ${seconds}s';
      }
    } else if (difference.inSeconds > 0) {
      _countdownText = '${difference.inSeconds}s';
    } else {
      _countdownText = 'Now';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.textColor ?? Colors.blue.shade700;

    if (widget.compact) {
      return Text(
        _countdownText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIconsFill.clock,
          color: textColor,
          size: 14,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Expires in $_countdownText',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
