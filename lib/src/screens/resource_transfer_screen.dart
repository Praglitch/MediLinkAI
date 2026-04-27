import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/transfer_suggestion.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/confirm_transfer_dialog.dart';
import '../widgets/network_health_score.dart';
import '../widgets/skeleton_loader.dart';

class ResourceTransferScreen extends StatelessWidget {
  const ResourceTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'AI Resource Optimization',
              subtitle: 'Network-level intelligent redistribution',
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 14,
                    color: Colors.white60,
                  ),
                ),
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const SkeletonLoader(cardCount: 2)
                  : _buildContent(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppState state) {
    final plan = state.currentPlan;

    if (plan == null || !plan.hasActions) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            NetworkHealthScore(
              score: state.networkHealthScore,
              livesImpacted: state.livesImpacted,
              totalTransfers: state.totalTransfers,
            ),
            const SizedBox(height: 24),
            _buildBalancedMessage(),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Network health
              NetworkHealthScore(
                score: state.networkHealthScore,
                livesImpacted: state.livesImpacted,
                totalTransfers: state.totalTransfers,
              ),
              const SizedBox(height: 16),

              // Alert
              _buildAlertCard(plan),
              const SizedBox(height: 16),

              // Health improvement preview
              _buildHealthPreview(plan),
              const SizedBox(height: 16),

              // Transfer suggestions
              ...plan.validSuggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSuggestionCard(
                    context,
                    state,
                    suggestion,
                    index + 1,
                    plan.validSuggestions.length,
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Execute all button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isTransferring
                      ? null
                      : () => _executeAll(context, state, plan),
                  icon: state.isTransferring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    state.isTransferring
                        ? 'Executing...'
                        : 'Execute All ${plan.validSuggestions.length} Transfers',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Insight card
              _buildInsightCard(plan),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertCard(TransferPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withOpacity(0.15),
            AppColors.danger.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.validSuggestions.length} resource imbalance(s) detected',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI has identified uneven resource distribution and generated safe transfer suggestions.',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPreview(TransferPlan plan) {
    final improvement = plan.healthImprovement;
    final color = improvement > 0 ? AppColors.success : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _healthColumn(
            'Before',
            plan.networkHealthBefore,
            AppColors.accent,
          ),
          Icon(Icons.arrow_forward, size: 18, color: color),
          _healthColumn(
            'After',
            plan.networkHealthAfter,
            color,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              improvement > 0
                  ? '+${improvement.toStringAsFixed(0)}%'
                  : '${improvement.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthColumn(String label, double score, Color color) {
    return Column(
      children: [
        Text(
          score.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    AppState state,
    TransferSuggestion suggestion,
    int index,
    int total,
  ) {
    final color =
        suggestion.resourceType == 'oxygen' ? AppColors.info : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Transfer $index/$total',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suggestion.resourceType.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Individual execute button
              GestureDetector(
                onTap: state.isTransferring
                    ? null
                    : () => _executeSingle(context, state, suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.send, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Execute',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transfer visualization
          Row(
            children: [
              Expanded(
                child: _buildEndpoint(
                  'FROM',
                  suggestion.fromHospitalName,
                  suggestion.fromBefore,
                  suggestion.fromAfter,
                  AppColors.danger,
                  suggestion.resourceType,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Icon(Icons.arrow_forward, color: color, size: 16),
                    const SizedBox(height: 4),
                    Text(
                      '${suggestion.transferAmount}',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      suggestion.resourceType,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildEndpoint(
                  'TO',
                  suggestion.toHospitalName,
                  suggestion.toBefore,
                  suggestion.toAfter,
                  AppColors.success,
                  suggestion.resourceType,
                ),
              ),
            ],
          ),

          // Reason
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 13,
                  color: AppColors.primary.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.reason,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Blocked by ambulance warning
          if (suggestion.blockedByAmbulance) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text('🚑', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Transfer blocked — incoming ambulance with ETA < 30min',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndpoint(
    String label,
    String name,
    int before,
    int after,
    Color color,
    String resourceType,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$before',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child:
                    Icon(Icons.arrow_forward, size: 10, color: Color(0xFF6B7280)),
              ),
              Text(
                '$after',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(TransferPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: AppColors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              plan.summary,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.success.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 48,
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'All community nodes are balanced',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No transfer is required right now. All nodes maintain adequate reserves above safety thresholds. Continue monitoring live resource levels.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSingle(
    BuildContext context,
    AppState state,
    TransferSuggestion suggestion,
  ) async {
    HapticFeedback.mediumImpact();
    final confirmed = await ConfirmTransferDialog.show(
      context,
      suggestion: suggestion,
    );

    if (confirmed != true) return;

    final success = await state.executeTransfer(suggestion);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Transfer completed!' : 'Transfer failed: ${state.error}',
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _executeAll(
    BuildContext context,
    AppState state,
    TransferPlan plan,
  ) async {
    HapticFeedback.heavyImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: const Text(
          'Execute All Transfers?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'This will execute ${plan.validSuggestions.length} transfers to '
          'improve network health from '
          '${plan.networkHealthBefore.toStringAsFixed(0)} → '
          '${plan.networkHealthAfter.toStringAsFixed(0)}.',
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Execute All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final count = await state.executePlan();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count transfers completed successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
