import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ResourceBar extends StatelessWidget {
  const ResourceBar({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: AppColors.accent, fontSize: 12),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: AppColors.border.withValues(alpha: 0.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  minHeight: 8,
                  value: value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withValues(alpha: 0.8),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
