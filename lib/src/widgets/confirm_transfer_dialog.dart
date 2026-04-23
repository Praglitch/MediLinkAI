import 'package:flutter/material.dart';

import '../models/transfer_suggestion.dart';
import '../theme/app_theme.dart';

/// Confirmation dialog shown before executing a resource transfer.
/// Displays the full before → after impact so the user makes an informed decision.
class ConfirmTransferDialog extends StatelessWidget {
  const ConfirmTransferDialog({super.key, required this.suggestion});

  final TransferSuggestion suggestion;

  static Future<bool?> show(
    BuildContext context, {
    required TransferSuggestion suggestion,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmTransferDialog(suggestion: suggestion),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Confirm Transfer',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer ${suggestion.transferAmount} ${suggestion.resourceType}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'From',
            suggestion.fromHospitalName,
            '${suggestion.fromBefore} → ${suggestion.fromAfter}',
            AppColors.danger,
          ),
          const SizedBox(height: 10),
          _buildRow(
            'To',
            suggestion.toHospitalName,
            '${suggestion.toBefore} → ${suggestion.toAfter}',
            AppColors.success,
          ),
          if (suggestion.deteriorationDuringTransit > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '~${suggestion.deteriorationDuringTransit} units may be '
                      'consumed during ${suggestion.transitMinutes}min transit',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: AppColors.accent)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Execute Transfer'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String name, String values, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                values,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
