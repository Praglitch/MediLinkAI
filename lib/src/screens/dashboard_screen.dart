import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/hospital.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/time_utils.dart';
import '../widgets/ambulance_badge.dart';
import '../widgets/app_header.dart';
import '../widgets/buffer_time_indicator.dart';
import '../widgets/network_health_score.dart';
import '../widgets/resource_bar.dart';
import '../widgets/skeleton_loader.dart';
import 'audit_log_screen.dart';
import 'hospital_panel_screen.dart';
import 'resource_transfer_screen.dart';
import 'simulation_screen.dart';
import 'volunteer_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _sortMode = 'urgency'; // urgency, status, name

  List<Map<String, dynamic>> get _quickChips => const [
    {'label': 'Fever', 'icon': Icons.thermostat, 'color': Color(0xFFEF4444)},
    {'label': 'ICU', 'icon': Icons.monitor_heart, 'color': Color(0xFFF59E0B)},
    {'label': 'Oxygen', 'icon': Icons.air, 'color': Color(0xFF06B6D4)},
    {'label': 'Critical', 'icon': Icons.warning_amber, 'color': Color(0xFFEF4444)},
    {'label': 'Breathing', 'icon': Icons.air, 'color': Color(0xFF8B5CF6)},
    {'label': 'Trauma', 'icon': Icons.emergency, 'color': Color(0xFFEC4899)},
    {'label': 'Pediatric', 'icon': Icons.child_care, 'color': Color(0xFF10B981)},
  ];

  void _applyChip(AppState state, String label) {
    _queryController.text = label;
    state.analyseQuery(label);
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<Hospital> _sortHospitals(List<Hospital> hospitals) {
    final sorted = List<Hospital>.from(hospitals);
    switch (_sortMode) {
      case 'urgency':
        sorted.sort((a, b) =>
            a.criticalBufferHours.compareTo(b.criticalBufferHours));
        break;
      case 'status':
        sorted.sort((a, b) =>
            a.status.index.compareTo(b.status.index));
        break;
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'MediLink AI Command Center',
              subtitle: 'Unifying community data, identifying urgent needs, coordinating volunteers.',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFreshnessPill(state),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      state.authService.signOut();
                    },
                    child: Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.accent.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const SkeletonLoader()
                  : state.error != null
                      ? _buildErrorState(state.error!)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onRefresh: () async {
                            // Streams auto-refresh, but add a visible delay
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          child: _buildContent(context, state),
                        ),
            ),
            _buildNavigationBar(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              color: AppColors.danger.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AppState>().enableMockMode();
              },
              child: const Text('Fallback to Mock Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppState state) {
    final hospitals = state.effectiveHospitals;
    final sorted = _sortHospitals(hospitals);
    final statusLabel = state.systemStatusLabel;
    final statusColor =
        state.effectiveHospitals.isEmpty
            ? AppColors.success
            : state.effectiveHospitals
                  .where((h) =>
                      h.status == ResourceStatus.critical ||
                      h.status == ResourceStatus.low)
                  .isEmpty
                ? AppColors.success
                : AppColors.danger;
    final criticalCount =
        hospitals
            .where((h) =>
                h.status == ResourceStatus.critical ||
                h.status == ResourceStatus.low)
            .length;
    final stableCount = hospitals.length - criticalCount;
    final earliest = state.earliestCollapse;

    // Determine recommended hospital from AI analysis
    final topPick = state.analysisResult?.topPick;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),

        // Network health score
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: NetworkHealthScore(
            score: state.networkHealthScore,
            livesImpacted: state.livesImpacted,
            totalTransfers: state.totalTransfers,
          ),
        ),
        const SizedBox(height: 12),

        // Earliest collapse alert
        if (earliest != null &&
            earliest.criticalBufferHours < 6 &&
            earliest.criticalBufferHours != double.infinity)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCollapseAlert(earliest),
          ),
        if (earliest != null &&
            earliest.criticalBufferHours < 6 &&
            earliest.criticalBufferHours != double.infinity)
          const SizedBox(height: 12),

        // Hero card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildHeroCard(statusLabel, statusColor, hospitals.length),
        ),
        const SizedBox(height: 16),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatsRow(stableCount, criticalCount, hospitals.length),
        ),
        const SizedBox(height: 20),

        // Search section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchSection(state),
        ),

        // AI recommendation
        if (state.isAnalysing)
          _buildAnalysingIndicator(),
        if (topPick != null && !state.isAnalysing)
          _buildRecommendationCard(state, topPick.hospitalId),

        // System-wide metrics
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: _buildSystemMetrics(state),
        ),

        // Transfer recommendation box (visible when imbalance exists)
        if (state.currentPlan != null && state.currentPlan!.hasActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildTransferRecommendation(state),
          ),

        // Sort controls + hospital list header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: _buildListHeader(hospitals),
        ),

        // Hospital cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: sorted.map((hospital) {
                  final cardWidth = constraints.maxWidth > 700
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return SizedBox(
                    width: cardWidth,
                    child: _buildHospitalCard(hospital, state),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCollapseAlert(Hospital hospital) {
    final color = TimeUtils.bufferTimeColor(hospital.criticalBufferHours);
    String resourceName = 'critical resources';
    if (hospital.bedBufferHours == hospital.criticalBufferHours) {
      resourceName = 'beds';
    } else if (hospital.oxygenBufferHours == hospital.criticalBufferHours) {
      resourceName = 'oxygen supplies';
    } else if (hospital.icuBufferHours == hospital.criticalBufferHours) {
      resourceName = 'ICU beds';
    } else if (hospital.ventilatorBufferHours == hospital.criticalBufferHours) {
      resourceName = 'ventilators';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_off, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '⚠ ${hospital.name} will run out of $resourceName in '
              '~${TimeUtils.formatBufferTime(hospital.criticalBufferHours)} '
              'at current consumption rate',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String statusLabel, Color statusColor, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Live AI Monitoring',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Smart Resource Allocation Engine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Data-driven volunteer coordination with predictive routing, buffer-time analysis, shadow-load awareness, and AI-powered transfer recommendations.',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _smallInfoChip(Icons.local_hospital_outlined, '$total nodes'),
              const SizedBox(width: 10),
              _smallInfoChip(Icons.timeline, 'Updated live'),
              const SizedBox(width: 10),
              _smallInfoChip(Icons.shield_outlined, 'Secured'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int stable, int critical, int total) {
    final staleFeedCount = _countStaleFeeds(context);
    final transferCount = context.read<AppState>().totalTransfers;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _numericCard('Hospitals', total.toString(), AppColors.primary,
            Icons.local_hospital_outlined),
        _numericCard('Stable', stable.toString(), AppColors.success,
            Icons.check_circle_outline),
        _numericCard('Critical', critical.toString(), AppColors.danger,
            Icons.warning_amber_rounded),
        _numericCard('Transfers', transferCount.toString(), AppColors.info,
            Icons.swap_horiz_rounded),
        _numericCard('Stale feeds', staleFeedCount.toString(), AppColors.warning,
            Icons.wifi_off_rounded),
      ],
    );
  }

  int _countStaleFeeds(BuildContext context) {
    final hospitals = context.read<AppState>().effectiveHospitals;
    int stale = 0;
    for (final h in hospitals) {
      if (h.lastUpdated != null) {
        final age = DateTime.now().difference(h.lastUpdated!);
        if (age.inMinutes > 10) stale++;
      }
    }
    return stale;
  }

  Widget _buildSearchSection(AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _queryController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe an emergency or tap a quick option',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 18),
              suffixIcon: state.currentQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _queryController.clear();
                        state.clearAnalysis();
                      },
                      child: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 16),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickChips.map((chip) {
              final label = chip['label'] as String;
              final color = chip['color'] as Color;
              final selected =
                  state.currentQuery.toLowerCase() == label.toLowerCase();
              return GestureDetector(
                onTap: () => _applyChip(state, label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.22)
                        : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? color.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chip['icon'] as IconData, size: 12, color: color),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isAnalysing
                  ? null
                  : () {
                      final query = _queryController.text.trim();
                      if (query.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a description to analyze.',
                            ),
                          ),
                        );
                        return;
                      }
                      HapticFeedback.mediumImpact();
                      state.analyseQuery(query);
                    },
              icon: state.isAnalysing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                state.isAnalysing ? 'Analyzing...' : 'Analyze with AI',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          if (!state.hasAIKey)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'ℹ Using offline scoring — set GEMINI_API_KEY for real AI',
                style: TextStyle(
                  color: AppColors.accent.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'AI is analyzing your query...',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(AppState state, String hospitalId) {
    final hospital = state.effectiveHospitals
        .where((h) => h.id == hospitalId)
        .firstOrNull;
    if (hospital == null) return const SizedBox.shrink();

    final result = state.analysisResult!;
    final reasoning = result.reasoningFor(hospitalId) ?? 'Best overall match.';
    final score = result.scoreFor(hospitalId) ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                const SizedBox(width: 10),
                Text(
                  result.isFromAI ? 'GEMINI AI RECOMMENDATION' : 'AI RECOMMENDATION (OFFLINE)',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Score: ${score.toStringAsFixed(0)}/100',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              hospital.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(Icons.bed, '${hospital.beds} Beds', AppColors.primary),
                _statusChip(Icons.air, '${hospital.oxygen} O₂', AppColors.info),
                if (hospital.icuBeds > 0)
                  _statusChip(Icons.monitor_heart, '${hospital.icuBeds} ICU', AppColors.warning),
                if (hospital.ventilators > 0)
                  _statusChip(Icons.medical_services, '${hospital.ventilators} Vent', AppColors.purple),
              ],
            ),
            const SizedBox(height: 14),
            BufferTimeIndicator(hours: hospital.criticalBufferHours),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.psychology, color: AppColors.primary.withOpacity(0.7), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reasoning,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            if (result.summary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                result.summary,
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.6),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(List<Hospital> hospitals) {
    return Row(
      children: [
        const Text(
          'HOSPITAL NETWORK',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${hospitals.length} live facilities',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
          ),
        ),
        const Spacer(),
        // Sort buttons
        _sortButton('urgency', 'Urgency'),
        const SizedBox(width: 6),
        _sortButton('status', 'Status'),
        const SizedBox(width: 6),
        _sortButton('name', 'Name'),
        const SizedBox(width: 10),
        const Icon(Icons.circle, color: AppColors.success, size: 7),
        const SizedBox(width: 4),
        const Text(
          'Live',
          style: TextStyle(color: AppColors.success, fontSize: 11),
        ),
      ],
    );
  }

  Widget _sortButton(String mode, String label) {
    final active = _sortMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _sortMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : const Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital, AppState state) {
    final topPick = state.analysisResult?.topPick;
    final isRecommended = topPick != null && topPick.hospitalId == hospital.id;
    final reasoning = state.analysisResult?.reasoningFor(hospital.id);
    final aiScore = state.analysisResult?.scoreFor(hospital.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRecommended
              ? [const Color(0xFF0A1628), const Color(0xFF0F1A2A)]
              : [AppColors.surface, AppColors.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: isRecommended
              ? AppColors.primary.withOpacity(0.45)
              : AppColors.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: hospital.statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: hospital.statusColor.withOpacity(0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hospital.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'AI Pick',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hospital.lastUpdated != null)
                      Text(
                        'Updated ${TimeUtils.formatRelativeTime(hospital.lastUpdated!)}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                    Text(
                      '${hospital.city} · ${hospital.tier}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Snapshot: ${hospital.beds} beds, ${hospital.oxygen} LPM oxygen',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hospital.statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hospital.statusLabel,
                      style: TextStyle(
                        color: hospital.statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  BufferTimeIndicator(
                    hours: hospital.criticalBufferHours,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),

          // Ambulance badge
          if (hospital.incomingAmbulanceCount(state.ambulances) > 0) ...[
            const SizedBox(height: 10),
            AmbulanceBadge(
              incomingCount: hospital.incomingAmbulanceCount(state.ambulances),
              urgentCount: hospital.urgentAmbulanceCount(state.ambulances),
            ),
          ],

          const SizedBox(height: 14),

          // Resource bars
          ResourceBar(
            label: 'Beds',
            value: '${hospital.beds}',
            progress: hospital.bedsFraction,
            color: hospital.statusColor,
            icon: Icons.bed_outlined,
          ),
          const SizedBox(height: 12),
          ResourceBar(
            label: 'Oxygen',
            value: '${hospital.oxygen} units',
            progress: hospital.oxygenFraction,
            color: AppColors.info,
            icon: Icons.air,
          ),
          if (hospital.icuBeds > 0) ...[
            const SizedBox(height: 12),
            ResourceBar(
              label: 'ICU Beds',
              value: '${hospital.icuBeds}',
              progress: hospital.icuFraction,
              color: AppColors.warning,
              icon: Icons.monitor_heart,
            ),
          ],
          if (hospital.ventilators > 0) ...[
            const SizedBox(height: 12),
            ResourceBar(
              label: 'Ventilators',
              value: '${hospital.ventilators}',
              progress: hospital.ventilatorFraction,
              color: AppColors.purple,
              icon: Icons.medical_services_outlined,
            ),
          ],

          // AI reasoning (if available)
          if (reasoning != null && state.analysisResult != null) ...[
            const SizedBox(height: 12),
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
                    Icons.psychology,
                    size: 12,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      aiScore != null
                          ? 'Score ${aiScore.toStringAsFixed(0)}: $reasoning'
                          : reasoning,
                      style: TextStyle(
                        color: AppColors.accent.withOpacity(0.7),
                        fontSize: 10,
                        height: 1.4,
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

  Widget _smallInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _numericCard(String label, String value, Color color, IconData icon) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1020),
        border: Border(top: BorderSide(color: Color(0xFF1A2035))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _navButton(
              label: 'Volunteer Hub',
              icon: Icons.people_alt,
              color: AppColors.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VolunteerDashboardScreen()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _navButton(
              label: 'AI Transfer',
              icon: Icons.swap_horiz_rounded,
              color: AppColors.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResourceTransferScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _navButton(
              label: 'History',
              icon: Icons.history,
              color: AppColors.info,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuditLogScreen()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _navButton(
              label: 'Simulate',
              icon: Icons.science_outlined,
              color: AppColors.purple,
              onTap: () {
                state.enterSimulation();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SimulationScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _navButton(
              label: 'Node Panel',
              icon: Icons.dashboard_customize_outlined,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HospitalPanelScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Freshness pill ───────────────────────────────────────────────

  Widget _buildFreshnessPill(AppState state) {
    final hospitals = state.effectiveHospitals;
    if (hospitals.isEmpty) {
      return const SizedBox.shrink();
    }

    DateTime? newest;
    for (final h in hospitals) {
      if (h.lastUpdated != null) {
        if (newest == null || h.lastUpdated!.isAfter(newest)) {
          newest = h.lastUpdated;
        }
      }
    }

    String label;
    Color color;
    if (newest == null) {
      label = 'Live';
      color = AppColors.success;
    } else {
      final age = DateTime.now().difference(newest);
      if (age.inSeconds < 60) {
        label = 'Live · updated ${age.inSeconds}s ago';
        color = AppColors.success;
      } else if (age.inMinutes < 5) {
        label = 'Fresh · updated ${age.inMinutes}m ago';
        color = AppColors.success;
      } else {
        label = 'Stale · updated ${age.inMinutes}m ago';
        color = AppColors.warning;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── System-wide metrics ──────────────────────────────────────────

  Widget _buildSystemMetrics(AppState state) {
    final hospitals = state.effectiveHospitals;

    final totalBeds = hospitals.fold(0, (s, h) => s + h.beds);
    final totalOccupiedBeds = hospitals.fold(0, (s, h) => s + (AppConstants.maxBedCapacity - h.beds));
    final totalIcu = hospitals.fold(0, (s, h) => s + h.icuBeds);
    final totalOccupiedIcu = hospitals.fold(0, (s, h) => s + (AppConstants.maxIcuCapacity - h.icuBeds));

    double avgOxygenBuffer = 0;
    int oxygenCount = 0;
    for (final h in hospitals) {
      if (h.oxygenBufferHours < double.infinity) {
        avgOxygenBuffer += h.oxygenBufferHours;
        oxygenCount++;
      }
    }
    final oxygenBufferAvg = oxygenCount > 0 ? avgOxygenBuffer / oxygenCount : 0.0;

    final avgReadiness = hospitals.isNotEmpty
        ? hospitals.fold(0.0, (s, h) => s + h.healthScore) / hospitals.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SYSTEM METRICS',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _systemMetricCard('Beds available', totalBeds.toString(),
                '$totalOccupiedBeds occupied', AppColors.primary),
            _systemMetricCard('ICU capacity', totalIcu.toString(),
                '$totalOccupiedIcu occupied', AppColors.warning),
            _systemMetricCard('Oxygen buffer', '${oxygenBufferAvg.toStringAsFixed(1)}h',
                'Sustainable window', AppColors.info),
            _systemMetricCard('Readiness avg', '${avgReadiness.toStringAsFixed(0)}%',
                'System-wide', AppColors.success),
          ],
        ),
      ],
    );
  }

  Widget _systemMetricCard(
      String label, String value, String detail, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Transfer recommendation box ──────────────────────────────────

  Widget _buildTransferRecommendation(AppState state) {
    final plan = state.currentPlan!;
    final first = plan.validSuggestions.first;
    final resourceLabel = first.resourceType.toUpperCase();
    final urgency = first.urgencyScore > 5.0 ? 'Immediate' : 'High';
    final urgencyColor = urgency == 'Immediate' ? AppColors.danger : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: urgencyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Transfer recommendation: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  resourceLabel,
                  style: const TextStyle(
                    color: AppColors.info,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urgency,
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.route, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${first.fromHospitalName} → ${first.toHospitalName} · ${first.transferAmount} units',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            first.reason,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isTransferring
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResourceTransferScreen(),
                        ),
                      );
                    },
              child: const Text(
                'Initiate Transfer',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
