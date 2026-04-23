import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Live ambulance count badge displayed on hospital cards.
class AmbulanceBadge extends StatelessWidget {
  const AmbulanceBadge({
    super.key,
    required this.incomingCount,
    this.urgentCount = 0,
  });

  final int incomingCount;
  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    if (incomingCount <= 0) return const SizedBox.shrink();

    final isUrgent = urgentCount > 0;
    final color = isUrgent ? AppColors.danger : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🚑', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            '$incomingCount incoming',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isUrgent) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
