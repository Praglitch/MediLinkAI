import 'dart:math';

import 'package:flutter/material.dart';

import '../models/ambulance.dart';
import '../models/hospital.dart';
import '../models/transfer_suggestion.dart';
import '../utils/constants.dart';

/// Network-level resource optimisation engine.
///
/// Replaces the naive pairwise min-max approach with a greedy algorithm
/// that resolves deficits in order of urgency (lowest buffer-time first)
/// while respecting safety margins and ambulance shadow-load.
class HospitalAdvisor {
  HospitalAdvisor._();

  // ── System status ──────────────────────────────────────────────────

  static String systemStatusLabel(List<Hospital> hospitals) {
    final critical = _criticalCount(hospitals);
    if (critical == 0) return 'ALL SYSTEMS NORMAL';
    if (critical == 1) return 'MINOR IMBALANCE';
    if (critical == 2) return 'ELEVATED ALERT';
    return 'CRITICAL ALERT';
  }

  static Color systemStatusColor(List<Hospital> hospitals) {
    final critical = _criticalCount(hospitals);
    if (critical == 0) return const Color(0xFF10B981);
    if (critical == 1) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static int _criticalCount(List<Hospital> hospitals) {
    return hospitals.where((h) =>
        h.status == ResourceStatus.critical ||
        h.status == ResourceStatus.low).length;
  }

  // ── Network health score (0–100) ───────────────────────────────────

  static double networkHealthScore(List<Hospital> hospitals) {
    if (hospitals.isEmpty) return 100.0;
    final total = hospitals.fold(0.0, (sum, h) => sum + h.healthScore);
    return (total / hospitals.length).clamp(0.0, 100.0);
  }

  // ── Earliest collapse alert ────────────────────────────────────────

  static Hospital? earliestCollapse(List<Hospital> hospitals) {
    if (hospitals.isEmpty) return null;
    Hospital? worst;
    double worstBuffer = double.infinity;
    for (final h in hospitals) {
      if (h.criticalBufferHours < worstBuffer) {
        worstBuffer = h.criticalBufferHours;
        worst = h;
      }
    }
    return worst;
  }

  // ── Safe transfer amount ───────────────────────────────────────────

  /// Calculate how many units can safely move from [from] to [to] for a
  /// given resource type, accounting for:
  ///   - minimum reserves at the donor
  ///   - actual deficit at the receiver
  ///   - resource deterioration during transit
  ///   - incoming ambulances (shadow load)
  static int safeTransferAmount({
    required int fromCurrent,
    required int toCurrent,
    required int minReserve,
    required List<Ambulance> ambulances,
    required String fromHospitalId,
  }) {
    // Donor safety: never drop below reserve
    final fromSafe = max(0, fromCurrent - minReserve);
    if (fromSafe <= 0) return 0;

    // Receiver need: how much they need to reach reserve + buffer
    final toNeeded = max(0, minReserve - toCurrent);
    if (toNeeded <= 0) return 0;

    // Deterioration during transit
    final deterioration =
        (AppConstants.deteriorationRatePerHour *
                AppConstants.transferDelayMinutes /
                60)
            .round();

    // Ambulance shadow load: reduce donor safe amount by incoming count
    final incomingToFrom = ambulances
        .where((a) => a.toHospitalId == fromHospitalId && a.isIncoming)
        .length;

    final adjustedFromSafe = max(0, fromSafe - incomingToFrom);

    return max(0, min(adjustedFromSafe, toNeeded + deterioration));
  }

  // ── Network-level greedy transfer plan ─────────────────────────────

  /// Generate an optimised [TransferPlan] across ALL hospitals:
  /// 1. Sort hospitals by urgency (lowest buffer time first)
  /// 2. For each deficit hospital, find best donor (highest surplus above reserve)
  /// 3. Generate safe transfer suggestions respecting all constraints
  /// 4. Never recommend draining a hospital with incoming ambulances (eta < 30 min)
  static TransferPlan generateTransferPlan({
    required List<Hospital> hospitals,
    required List<Ambulance> ambulances,
  }) {
    if (hospitals.length < 2) {
      return TransferPlan(
        suggestions: const [],
        summary: 'Not enough hospitals to generate a transfer plan.',
        networkHealthBefore: networkHealthScore(hospitals),
        networkHealthAfter: networkHealthScore(hospitals),
        generatedAt: DateTime.now(),
      );
    }

    final healthBefore = networkHealthScore(hospitals);
    final suggestions = <TransferSuggestion>[];

    // Build mutable copies for simulation
    final bedPool = {for (final h in hospitals) h.id: h.beds};
    final oxygenPool = {for (final h in hospitals) h.id: h.oxygen};

    // ── BED transfers ─────────────────────────────────────────────
    _resolveResource(
      hospitals: hospitals,
      ambulances: ambulances,
      resourcePool: bedPool,
      resourceName: 'beds',
      minReserve: AppConstants.minBedReserve,
      suggestions: suggestions,
      getAmount: (h) => bedPool[h.id]!,
    );

    // ── OXYGEN transfers ──────────────────────────────────────────
    _resolveResource(
      hospitals: hospitals,
      ambulances: ambulances,
      resourcePool: oxygenPool,
      resourceName: 'oxygen',
      minReserve: AppConstants.minOxygenReserve,
      suggestions: suggestions,
      getAmount: (h) => oxygenPool[h.id]!,
    );

    // Simulate post-transfer health
    final simulated = hospitals.map((h) {
      return h.copyWith(
        beds: bedPool[h.id],
        oxygen: oxygenPool[h.id],
      );
    }).toList();
    final healthAfter = networkHealthScore(simulated);

    final summary = suggestions.isEmpty
        ? 'All hospitals are balanced — no transfers needed.'
        : '${suggestions.length} transfer(s) suggested to improve network '
            'health from ${healthBefore.toStringAsFixed(0)} → '
            '${healthAfter.toStringAsFixed(0)}.';

    return TransferPlan(
      suggestions: suggestions,
      summary: summary,
      networkHealthBefore: healthBefore,
      networkHealthAfter: healthAfter,
      generatedAt: DateTime.now(),
    );
  }

  static void _resolveResource({
    required List<Hospital> hospitals,
    required List<Ambulance> ambulances,
    required Map<String, int> resourcePool,
    required String resourceName,
    required int minReserve,
    required List<TransferSuggestion> suggestions,
    required int Function(Hospital) getAmount,
  }) {
    // Sort by current amount ascending (most urgent first)
    final sorted = List<Hospital>.from(hospitals)
      ..sort((a, b) => resourcePool[a.id]!.compareTo(resourcePool[b.id]!));

    for (final receiver in sorted) {
      final receiverCurrent = resourcePool[receiver.id]!;
      if (receiverCurrent >= minReserve) continue; // No deficit

      // Find best donor: most surplus, not blocked by ambulances
      Hospital? bestDonor;
      int bestSurplus = 0;

      for (final donor in sorted.reversed) {
        if (donor.id == receiver.id) continue;
        final donorCurrent = resourcePool[donor.id]!;
        final surplus = donorCurrent - minReserve;
        if (surplus <= 0) continue;

        // Block if donor has urgent incoming ambulances
        final urgentIncoming = ambulances
            .where((a) =>
                a.toHospitalId == donor.id && a.isIncoming && a.isUrgent)
            .length;
        final blocked = urgentIncoming > 0 &&
            (donorCurrent - urgentIncoming) <= minReserve;

        if (blocked) continue;

        if (surplus > bestSurplus) {
          bestSurplus = surplus;
          bestDonor = donor;
        }
      }

      if (bestDonor == null) continue;

      final amount = safeTransferAmount(
        fromCurrent: resourcePool[bestDonor.id]!,
        toCurrent: receiverCurrent,
        minReserve: minReserve,
        ambulances: ambulances,
        fromHospitalId: bestDonor.id,
      );

      if (amount <= 0) continue;

      final donorBefore = resourcePool[bestDonor.id]!;
      suggestions.add(TransferSuggestion(
        fromHospitalId: bestDonor.id,
        fromHospitalName: bestDonor.name,
        toHospitalId: receiver.id,
        toHospitalName: receiver.name,
        resourceType: resourceName,
        transferAmount: amount,
        fromBefore: donorBefore,
        toBefore: receiverCurrent,
        reason:
            '${receiver.name} is below minimum reserve ($receiverCurrent $resourceName). '
            '${bestDonor.name} has a surplus of ${donorBefore - minReserve} above reserve. '
            'Transferring $amount $resourceName to stabilise the network.',
        urgencyScore: (minReserve - receiverCurrent).toDouble(),
        transitMinutes: AppConstants.transferDelayMinutes,
        deteriorationDuringTransit:
            (AppConstants.deteriorationRatePerHour *
                    AppConstants.transferDelayMinutes /
                    60)
                .round(),
      ));

      // Update simulation pool
      resourcePool[bestDonor.id] = donorBefore - amount;
      resourcePool[receiver.id] = receiverCurrent + amount;
    }
  }

  // ── What-If analysis ───────────────────────────────────────────────

  /// Simulate what happens if a hospital goes completely offline.
  static TransferPlan whatIfHospitalOffline({
    required String offlineHospitalId,
    required List<Hospital> hospitals,
    required List<Ambulance> ambulances,
  }) {
    final remaining =
        hospitals.where((h) => h.id != offlineHospitalId).toList();
    final offlineHospital =
        hospitals.where((h) => h.id == offlineHospitalId).firstOrNull;

    if (offlineHospital == null || remaining.isEmpty) {
      return TransferPlan(
        suggestions: const [],
        summary: 'Unable to simulate — hospital not found.',
        networkHealthBefore: networkHealthScore(hospitals),
        networkHealthAfter: 0,
        generatedAt: DateTime.now(),
      );
    }

    final plan = generateTransferPlan(
      hospitals: remaining,
      ambulances: ambulances,
    );

    return TransferPlan(
      suggestions: plan.suggestions,
      summary:
          'If ${offlineHospital.name} goes offline: '
          '${plan.suggestions.length} redistributions needed. '
          'Network health would drop to '
          '${plan.networkHealthAfter.toStringAsFixed(0)}/100.',
      networkHealthBefore: networkHealthScore(hospitals),
      networkHealthAfter: plan.networkHealthAfter,
      generatedAt: DateTime.now(),
    );
  }
}
