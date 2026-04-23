import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/app_header.dart';
import '../widgets/buffer_time_indicator.dart';
import '../widgets/network_health_score.dart';

/// Digital Twin Simulation Mode — lets users manipulate parameters and watch
/// the network respond in real time without touching Firestore.
class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Digital Twin Simulation',
              subtitle: 'Predict outcomes without affecting live data',
              leading: GestureDetector(
                onTap: () {
                  state.exitSimulation();
                  Navigator.pop(context);
                },
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
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'SIMULATION',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Network health with simulated data
                  NetworkHealthScore(
                    score: state.networkHealthScore,
                    livesImpacted: state.livesImpacted,
                    totalTransfers: state.totalTransfers,
                  ),
                  const SizedBox(height: 16),

                  // Simulation controls
                  _buildControlPanel(context, state),
                  const SizedBox(height: 16),

                  // Simulated hospital states
                  const Text(
                    'SIMULATED HOSPITAL STATUS',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...state.effectiveHospitals.map(
                    (h) => _buildSimulatedCard(h, state),
                  ),

                  const SizedBox(height: 16),

                  // What-If section
                  _buildWhatIfSection(context, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.08),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppColors.purple, size: 16),
              const SizedBox(width: 8),
              const Text(
                'SIMULATION PARAMETERS',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Patient arrival rate
          _buildSlider(
            label: 'Patient Arrival Rate',
            value: state.simPatientRate,
            min: 0,
            max: 20,
            unit: 'patients/hr',
            color: AppColors.warning,
            onChanged: (v) => state.updateSimulation(patientRate: v),
          ),
          const SizedBox(height: 18),

          // Resource consumption rate
          _buildSlider(
            label: 'Resource Consumption Rate',
            value: state.simConsumptionRate,
            min: 0.5,
            max: 10,
            unit: 'beds/hr',
            color: AppColors.danger,
            onChanged: (v) => state.updateSimulation(consumptionRate: v),
          ),

          const SizedBox(height: 16),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                state.updateSimulation(patientRate: 5.0, consumptionRate: 2.0);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset to Defaults'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.border.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.accent, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatedCard(hospital, AppState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hospital.statusColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hospital.statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: hospital.statusColor.withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hospital.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              BufferTimeIndicator(
                hours: hospital.criticalBufferHours,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _simStat('Beds', '${hospital.beds}', hospital.statusColor),
              _simStat('O₂', '${hospital.oxygen}', AppColors.info),
              _simStat('ICU', '${hospital.icuBeds}', AppColors.warning),
              _simStat(
                'Buffer',
                TimeUtils.formatBufferTime(hospital.criticalBufferHours),
                TimeUtils.bufferTimeColor(hospital.criticalBufferHours),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildWhatIfSection(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withOpacity(0.08),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.danger, size: 16),
              const SizedBox(width: 8),
              const Text(
                'WHAT-IF SCENARIO',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap a hospital to see what happens if it goes offline:',
            style: TextStyle(color: AppColors.accent, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.effectiveHospitals.map((h) {
              return GestureDetector(
                onTap: () => _showWhatIfResult(context, state, h.id, h.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    h.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showWhatIfResult(
    BuildContext context,
    AppState state,
    String hospitalId,
    String hospitalName,
  ) {
    final plan = state.whatIfOffline(hospitalId);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.offline_bolt, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$hospitalName Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.summary,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _impactChip(
                  'Health Before',
                  plan.networkHealthBefore.toStringAsFixed(0),
                  AppColors.success,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                _impactChip(
                  'Health After',
                  plan.networkHealthAfter.toStringAsFixed(0),
                  AppColors.danger,
                ),
              ],
            ),
            if (plan.suggestions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                '${plan.suggestions.length} redistributions would be needed.',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _impactChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9),
          ),
        ],
      ),
    );
  }
}
