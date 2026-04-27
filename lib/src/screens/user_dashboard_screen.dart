import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/hospital.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/ambulance_badge.dart';
import '../widgets/app_header.dart';
import '../widgets/buffer_time_indicator.dart';
import '../widgets/resource_bar.dart';
import '../widgets/skeleton_loader.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _sortMode = 'urgency'; // urgency, status, name

  List<Map<String, dynamic>> get _quickChips => const [
    {'label': 'Emergency', 'icon': Icons.emergency, 'color': Color(0xFFEF4444)},
    {'label': 'Fever', 'icon': Icons.thermostat, 'color': Color(0xFFF59E0B)},
    {'label': 'Oxygen', 'icon': Icons.air, 'color': Color(0xFF06B6D4)},
    {'label': 'ICU Bed', 'icon': Icons.monitor_heart, 'color': Color(0xFF8B5CF6)},
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
              title: 'User Portal',
              subtitle: 'Find beds, oxygen, and get emergency recommendations',
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 14, color: Colors.white60),
                ),
              ),
              trailing: GestureDetector(
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
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          child: _buildContent(context, state),
                        ),
            ),
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
              color: AppColors.danger.withOpacity(0.5),
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
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppState state) {
    final hospitals = state.effectiveHospitals;
    final sorted = _sortHospitals(hospitals);
    final earliest = state.earliestCollapse;
    final topPick = state.analysisResult?.topPick;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),

        // Search section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchSection(state),
        ),

        // Urgent alerts
        if (earliest != null &&
            earliest.criticalBufferHours < 6 &&
            earliest.criticalBufferHours != double.infinity)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildCollapseAlert(earliest),
          ),

        // AI recommendation
        if (state.isAnalysing)
          _buildAnalysingIndicator(),
        if (topPick != null && !state.isAnalysing)
          _buildRecommendationCard(state, topPick.hospitalId),

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
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Warning: ${hospital.name} is running critically low on $resourceName.',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.12),
            const Color(0xFF06B6D4).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: const Color(0xFF06B6D4).withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 12, color: Color(0xFF06B6D4)),
                    SizedBox(width: 5),
                    Text(
                      'Find Care',
                      style: TextStyle(
                        color: Color(0xFF06B6D4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'What do you need?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Describe your medical emergency, and our AI will find the nearest hospital with available beds and equipment.',
            style: TextStyle(
              color: AppColors.accent.withOpacity(0.6),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _queryController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Need an ICU bed for severe asthma',
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
                state.isAnalysing ? 'Finding best match...' : 'Ask AI for Recommendation',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'AI is finding the best hospital...',
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
    final reasoning = result.reasoningFor(hospitalId) ?? 'Best overall match for your needs.';
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
                  result.isFromAI ? 'GEMINI AI MATCH' : 'AI MATCH (OFFLINE)',
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
                    'Match Score: ${score.toStringAsFixed(0)}%',
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
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(List<Hospital> hospitals) {
    return Row(
      children: [
        const Text(
          'NEARBY HOSPITALS',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        // Sort buttons
        _sortButton('urgency', 'Urgency'),
        const SizedBox(width: 6),
        _sortButton('name', 'Name'),
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
                              'Best Match',
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
                    Text(
                      '${hospital.city} · ${hospital.tier}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
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
                ],
              ),
            ],
          ),
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
}
