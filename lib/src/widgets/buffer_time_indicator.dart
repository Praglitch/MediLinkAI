import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

/// Compact buffer-time indicator: shows predicted hours until depletion.
class BufferTimeIndicator extends StatelessWidget {
  const BufferTimeIndicator({super.key, required this.hours, this.compact = false});

  final double hours;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = TimeUtils.bufferTimeColor(hours);
    final text = TimeUtils.formatBufferTime(hours);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            '~$text remaining',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
