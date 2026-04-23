import 'package:flutter/material.dart';

import 'constants.dart';

/// Shared time-formatting utilities — no more duplicate helpers per screen.
class TimeUtils {
  TimeUtils._();

  static String formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String formatBufferTime(double hours) {
    if (hours <= 0) return 'DEPLETED';
    if (hours == double.infinity) return '∞';
    if (hours < 1) return '${(hours * 60).round()}m';
    if (hours < 24) return '${hours.toStringAsFixed(1)}h';
    return '${(hours / 24).toStringAsFixed(1)}d';
  }

  static Color bufferTimeColor(double hours) {
    if (hours < AppConstants.bufferCriticalHours) {
      return const Color(0xFFEF4444);
    }
    if (hours < AppConstants.bufferWarningHours) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF10B981);
  }

  static String formatEta(DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return 'Arrived';
    if (diff.inMinutes < 1) return '<1 min';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}
