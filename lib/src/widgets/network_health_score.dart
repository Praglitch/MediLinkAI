import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated network health gauge (0–100) displayed at the top of the dashboard.
class NetworkHealthScore extends StatelessWidget {
  const NetworkHealthScore({
    super.key,
    required this.score,
    this.livesImpacted = 0,
    this.totalTransfers = 0,
  });

  final double score;
  final int livesImpacted;
  final int totalTransfers;

  Color get _color {
    if (score < 40) return const Color(0xFFEF4444);
    if (score < 70) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get _label {
    if (score < 40) return 'CRITICAL';
    if (score < 70) return 'MODERATE';
    return 'HEALTHY';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _color.withValues(alpha: 0.12),
            _color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Score circle
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 5,
                    backgroundColor: _color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(_color),
                  ),
                ),
                Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(
                    color: _color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Network Health',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _label,
                        style: TextStyle(
                          color: _color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (totalTransfers > 0)
                  Row(
                    children: [
                      Text(
                        '🫀 ',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        '$totalTransfers transfers → ~$livesImpacted patients served faster',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Monitoring all connected hospitals',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
