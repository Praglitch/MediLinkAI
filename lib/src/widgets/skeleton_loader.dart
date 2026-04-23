import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Skeleton loading placeholder that replaces CircularProgressIndicator
/// with a polished shimmer effect while Firestore data loads.
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key, this.cardCount = 3});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.panel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card skeleton
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
            const SizedBox(height: 16),
            // Stats row skeleton
            Row(
              children: List.generate(3, (index) => Expanded(
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            // Hospital card skeletons
            ...List.generate(cardCount, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// A single skeleton line for inline placeholders.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width = 120, this.height = 14});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.panel,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
