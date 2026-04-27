import 'package:flutter/material.dart';

import '../models/transfer_suggestion.dart';
import '../models/volunteer_model.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

/// Confirmation dialog shown before executing a resource transfer.
/// Displays the task as an "Open Task" for a volunteer to claim.
class ConfirmTransferDialog extends StatefulWidget {
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
  State<ConfirmTransferDialog> createState() => _ConfirmTransferDialogState();
}

class _ConfirmTransferDialogState extends State<ConfirmTransferDialog> {
  bool _isClaimed = false;
  Volunteer? _matchedVolunteer;

  void _claimTask() {
    // Intelligent volunteer matching using Haversine distance
    final available = MockData.volunteers
        .where((v) => v.status == VolunteerStatus.available)
        .toList();

    // Find the source hospital to compute proximity
    final sourceHospital = MockData.hospitals
        .where((h) => h.name == widget.suggestion.fromHospitalName)
        .toList();

    Volunteer? best;
    if (available.isNotEmpty && sourceHospital.isNotEmpty) {
      final src = sourceHospital.first;
      if (src.latitude != null && src.longitude != null) {
        available.sort((a, b) =>
            a.distanceTo(src.latitude!, src.longitude!)
                .compareTo(b.distanceTo(src.latitude!, src.longitude!)));
      }
      best = available.first;
    } else if (available.isNotEmpty) {
      best = available.first;
    }

    setState(() {
      _isClaimed = true;
      _matchedVolunteer = best;
    });
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
          Icon(Icons.assignment_late_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Open Task',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.danger.withOpacity(0.5)),
            ),
            child: Text(
              'URGENT',
              style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move ${widget.suggestion.transferAmount} ${widget.suggestion.resourceType}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'From',
            widget.suggestion.fromHospitalName,
            '${widget.suggestion.fromBefore} → ${widget.suggestion.fromAfter}',
            AppColors.danger,
          ),
          const SizedBox(height: 10),
          _buildRow(
            'To',
            widget.suggestion.toHospitalName,
            '${widget.suggestion.toBefore} → ${widget.suggestion.toAfter}',
            AppColors.success,
          ),
          if (_isClaimed && _matchedVolunteer != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.success.withOpacity(0.2),
                    child: Icon(Icons.person, color: AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Claimed by ${_matchedVolunteer!.name}',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_matchedVolunteer!.vehicleType} • ETA: ~14 mins',
                          style: TextStyle(color: AppColors.success.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (widget.suggestion.deteriorationDuringTransit > 0) ...[
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
                      '~${widget.suggestion.deteriorationDuringTransit} units may be '
                      'consumed during ${widget.suggestion.transitMinutes}min transit',
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
        if (!_isClaimed) ...[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.accent)),
          ),
          ElevatedButton.icon(
            onPressed: _claimTask,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Claim Task'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Done'),
          ),
        ]
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
