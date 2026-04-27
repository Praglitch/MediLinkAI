import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/volunteer_model.dart';
import '../models/transfer_request.dart';
import '../models/community_need.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../services/mock_data.dart';
import '../widgets/app_header.dart';

/// Full volunteer coordination hub — community needs feed, intelligent
/// volunteer matching, transfer request lifecycle, and live impact metrics.
class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  late List<TransferRequest> _requests;
  late List<CommunityNeed> _needs;
  int _dispatchedCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _requests = List.from(MockData.transferRequests);
    _needs = List.from(MockData.communityNeeds);
  }

  // ── Intelligent volunteer matching (Fix #2) ────────────────────────
  /// Finds the best available volunteer for a transfer between two hospitals.
  /// Ranks by: proximity to source → vehicle capacity for resource type.
  Volunteer? _findBestVolunteer(String fromName) {
    final sourceHospital = MockData.hospitals
        .where((h) => h.name == fromName)
        .toList();
    if (sourceHospital.isEmpty) return null;

    final src = sourceHospital.first;
    final available = MockData.volunteers
        .where((v) => v.status == VolunteerStatus.available)
        .toList();
    if (available.isEmpty) return null;

    // Sort by distance to source hospital (nearest first)
    available.sort((a, b) {
      final distA = a.distanceTo(src.latitude ?? 0, src.longitude ?? 0);
      final distB = b.distanceTo(src.latitude ?? 0, src.longitude ?? 0);
      return distA.compareTo(distB);
    });

    // Prefer vehicles with higher capacity for resource transfers
    // If distances are similar (<0.5km difference), pick higher capacity
    if (available.length > 1) {
      final distFirst = available[0].distanceTo(src.latitude ?? 0, src.longitude ?? 0);
      final distSecond = available[1].distanceTo(src.latitude ?? 0, src.longitude ?? 0);
      if ((distSecond - distFirst).abs() < 0.5 &&
          available[1].capacityKg > available[0].capacityKg) {
        final temp = available[0];
        available[0] = available[1];
        available[1] = temp;
      }
    }

    return available.first;
  }

  void _assignVolunteer(int index) {
    final request = _requests[index];
    final best = _findBestVolunteer(request.fromName);
    if (best == null) return;

    setState(() {
      _requests[index] = TransferRequest(
        id: request.id,
        resourceType: request.resourceType,
        status: TransferRequestStatus.dispatched,
        fromName: request.fromName,
        toName: request.toName,
        quantity: request.quantity,
        assignedVolunteerName: best.name,
      );
      _dispatchedCount++;
    });
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${best.name} dispatched to deliver ${request.resourceType}'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _assignVolunteerToNeed(int index) {
    final need = _needs[index];
    // Use the area's approximate center for matching
    final available = MockData.volunteers
        .where((v) => v.status == VolunteerStatus.available)
        .toList();
    if (available.isEmpty) return;

    // Just pick nearest available by default lat/lng center of Bengaluru
    available.sort((a, b) => a.distanceTo(12.97, 77.59).compareTo(b.distanceTo(12.97, 77.59)));

    setState(() {
      _needs[index] = CommunityNeed(
        id: need.id,
        title: need.title,
        description: need.description,
        reportedBy: need.reportedBy,
        area: need.area,
        category: need.category,
        urgency: need.urgency,
        reportedAt: need.reportedAt,
        isResolved: false,
        assignedVolunteerName: available.first.name,
      );
      _dispatchedCount++;
    });
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${available.first.name} dispatched to ${need.area}'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = state.currentPlan;

    // ── Live-computed impact metrics (Fix #3) ──────────────────────
    final totalAssigned = _dispatchedCount + _completedCount;
    final volunteerHours = (totalAssigned * 2.5).toStringAsFixed(0); // ~2.5h per trip
    final pendingNeeds = _needs.where((n) => n.assignedVolunteerName == null && !n.isResolved).length;
    final totalNeeds = _needs.length;
    final resolvedNeeds = _needs.where((n) => n.assignedVolunteerName != null || n.isResolved).length;
    final needsMetPct = totalNeeds > 0 ? ((resolvedNeeds / totalNeeds) * 100).round() : 0;
    final activeVolunteers = MockData.volunteers
        .where((v) => v.status != VolunteerStatus.unavailable)
        .length;

    // Avg Response Time — time between need reported and volunteer assigned
    final assignedNeeds = _needs.where((n) => n.assignedVolunteerName != null).toList();
    int avgResponseMin = 0;
    if (assignedNeeds.isNotEmpty) {
      final totalMin = assignedNeeds.fold<int>(0, (sum, n) {
        return sum + DateTime.now().difference(n.reportedAt).inMinutes;
      });
      avgResponseMin = (totalMin / assignedNeeds.length).round();
    }
    final responseLabel = avgResponseMin > 0 ? '${avgResponseMin}m' : '--';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportNeedSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text('Report Need',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Volunteer Coordination',
              subtitle: 'Data-Driven Volunteer Coordination for Social Impact',
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Impact metrics (LIVE, not hardcoded) ──────
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _numericCard('Community\nNeeds Pending',
                            '$pendingNeeds', AppColors.danger,
                            Icons.report_problem_outlined),
                        _numericCard('Volunteer Hours\nCoordinated', volunteerHours,
                            AppColors.success, Icons.timer),
                        _numericCard('Needs\nAddressed',
                            '$needsMetPct%', AppColors.info,
                            Icons.check_circle_outline),
                        _numericCard('Active\nVolunteers',
                            '$activeVolunteers', AppColors.purple,
                            Icons.people),
                        _numericCard('Avg Response\nTime', responseLabel,
                            AppColors.warning, Icons.speed),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Community Needs Feed (Fix #1) ─────────────
                    Row(
                      children: [
                        _sectionHeader('Community Needs Feed'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalNeeds reports from ${_uniqueSources()} sources',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Aggregated from NGO paper surveys, field worker reports, and community organizations',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    ..._needs.asMap().entries.map(
                      (e) => _communityNeedCard(e.key, e.value),
                    ),
                    const SizedBox(height: 28),

                    // ── Transfer Alerts ────────────────────────────
                    _sectionHeader('Transfer Alerts'),
                    const SizedBox(height: 12),
                    if (plan != null && plan.hasActions)
                      ...plan.validSuggestions.map(
                        (s) => _transferAlertCard(s),
                      )
                    else
                      _emptyStateCard(
                        'No imbalance detected right now.',
                        Icons.check_circle_outline,
                      ),
                    const SizedBox(height: 28),

                    // ── Volunteer Coordination ─────────────────────
                    _sectionHeader('Volunteer Coordination'),
                    const SizedBox(height: 12),
                    ...MockData.volunteers
                        .where((v) => v.status != VolunteerStatus.unavailable)
                        .map((v) => _volunteerCard(v)),
                    const SizedBox(height: 20),

                    // ── Transfer requests subsection ───────────────
                    const Text(
                      'Transfer requests',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_requests.isEmpty)
                      _emptyStateCard(
                        'No active request records.',
                        Icons.inbox_outlined,
                      )
                    else
                      ..._requests.asMap().entries.map(
                            (e) => _transferRequestCard(e.key, e.value),
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _uniqueSources() {
    return _needs.map((n) => n.reportedBy).toSet().length;
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _numericCard(String label, String value, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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

  // ── Community Need Card (Fix #1 — the "scattered data" visualised) ──

  Widget _communityNeedCard(int index, CommunityNeed need) {
    Color urgencyColor;
    switch (need.urgency) {
      case NeedUrgency.critical:
        urgencyColor = AppColors.danger;
        break;
      case NeedUrgency.high:
        urgencyColor = AppColors.warning;
        break;
      case NeedUrgency.medium:
        urgencyColor = AppColors.info;
        break;
      case NeedUrgency.low:
        urgencyColor = AppColors.success;
        break;
    }

    final isAssigned = need.assignedVolunteerName != null;
    final ago = DateTime.now().difference(need.reportedAt);
    String timeLabel;
    if (ago.inMinutes < 60) {
      timeLabel = '${ago.inMinutes}m ago';
    } else {
      timeLabel = '${ago.inHours}h ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAssigned
              ? AppColors.success.withOpacity(0.3)
              : urgencyColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — urgency + category + time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  need.urgencyLabel,
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  need.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeLabel,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            need.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            need.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Source + area
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${need.area} · Reported by ${need.reportedBy}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Assign or assigned
          if (isAssigned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_pin, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Volunteer dispatched: ${need.assignedVolunteerName}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => _assignVolunteerToNeed(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Match & assign volunteer',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _transferAlertCard(dynamic suggestion) {
    final resourceType = suggestion.resourceType.toString().toUpperCase();
    final urgency = suggestion.urgencyScore > 5.0 ? 'Immediate' : 'High';
    final urgencyColor = urgency == 'Immediate' ? AppColors.danger : AppColors.warning;

    // Find best volunteer for this transfer (intelligent matching preview)
    final best = _findBestVolunteer(suggestion.fromHospitalName);
    String? matchInfo;
    if (best != null) {
      final sourceHospital = MockData.hospitals.where((h) => h.name == suggestion.fromHospitalName).toList();
      if (sourceHospital.isNotEmpty) {
        final dist = best.distanceTo(sourceHospital.first.latitude ?? 0, sourceHospital.first.longitude ?? 0);
        matchInfo = '${best.name} (${dist.toStringAsFixed(1)}km away, ${best.vehicleType}, ${best.capacityKg}kg)';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: urgencyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(resourceType,
                    style: const TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(urgency,
                    style: TextStyle(color: urgencyColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('Quantity ${suggestion.transferAmount}',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.route, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${suggestion.fromHospitalName} → ${suggestion.toHospitalName}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(suggestion.reason,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, height: 1.4)),
          // Show intelligent match suggestion
          if (matchInfo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_search, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Best match: $matchInfo',
                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
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

  Widget _volunteerCard(Volunteer volunteer) {
    final isAvailable = volunteer.status == VolunteerStatus.available;
    final statusColor = isAvailable ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(volunteer.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${volunteer.phone} · ${volunteer.vehicleType} · ${volunteer.capacityKg}kg',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(volunteer.statusLabel,
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _transferRequestCard(int index, TransferRequest request) {
    final isAssigned = request.assignedVolunteerName != null;
    Color statusColor;
    switch (request.status) {
      case TransferRequestStatus.pending:
        statusColor = AppColors.warning;
        break;
      case TransferRequestStatus.approved:
        statusColor = AppColors.info;
        break;
      case TransferRequestStatus.dispatched:
      case TransferRequestStatus.inTransit:
        statusColor = AppColors.primary;
        break;
      case TransferRequestStatus.received:
      case TransferRequestStatus.completed:
        statusColor = AppColors.success;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(request.resourceType,
                    style: const TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(request.statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('Qty ${request.quantity}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${request.fromName} → ${request.toName}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (isAssigned)
            Row(
              children: [
                const Icon(Icons.person_pin, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Assigned to ${request.assignedVolunteerName}',
                    style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            )
          else
            GestureDetector(
              onTap: () => _assignVolunteer(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Assign volunteer',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyStateCard(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 16),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        ],
      ),
    );
  }

  // ── Report Community Need — bottom sheet form ────────────────────

  void _showReportNeedSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final reporterCtrl = TextEditingController();
    String selectedCategory = 'healthcare';
    NeedUrgency selectedUrgency = NeedUrgency.high;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20, 20, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Report a Community Need',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Submit a field report from an NGO survey, community worker, or local organization.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                    const SizedBox(height: 18),

                    _sheetTextField(titleCtrl, 'Need Title', 'e.g. 30 families need clean water'),
                    const SizedBox(height: 12),
                    _sheetTextField(descCtrl, 'Description', 'Details from field survey...', maxLines: 3),
                    const SizedBox(height: 12),
                    _sheetTextField(areaCtrl, 'Area / Ward', 'e.g. Koramangala 6th Block'),
                    const SizedBox(height: 12),
                    _sheetTextField(reporterCtrl, 'Reported By', 'e.g. WaterAid Field Team'),
                    const SizedBox(height: 14),

                    // Category selector
                    const Text('Category', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['healthcare', 'resources', 'food', 'shelter'].map((cat) {
                        final isSelected = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              cat.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Urgency selector
                    const Text('Urgency', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: NeedUrgency.values.map((u) {
                        final isSelected = selectedUrgency == u;
                        final color = u == NeedUrgency.critical
                            ? AppColors.danger
                            : u == NeedUrgency.high
                                ? AppColors.warning
                                : u == NeedUrgency.medium
                                    ? AppColors.info
                                    : AppColors.success;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedUrgency = u),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? color : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              u.name.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? color : const Color(0xFF9CA3AF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) return;
                          final newNeed = CommunityNeed(
                            id: 'cn_${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? 'Field report submitted via MediLink'
                                : descCtrl.text.trim(),
                            reportedBy: reporterCtrl.text.trim().isEmpty
                                ? 'Field Worker'
                                : reporterCtrl.text.trim(),
                            area: areaCtrl.text.trim().isEmpty
                                ? 'Bengaluru'
                                : areaCtrl.text.trim(),
                            category: selectedCategory,
                            urgency: selectedUrgency,
                            reportedAt: DateTime.now(),
                          );
                          setState(() {
                            _needs.insert(0, newNeed);
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('\u2713 Need reported: ${newNeed.title}'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ));
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Submit Field Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF6B7280).withOpacity(0.5), fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
