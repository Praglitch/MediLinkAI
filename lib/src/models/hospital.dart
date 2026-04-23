import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'ambulance.dart';

enum ResourceStatus { critical, low, moderate, stable }

class Hospital {
  final String id;
  final String name;
  final int beds;
  final int icuBeds;
  final int ventilators;
  final int pediatricBeds;
  final int traumaBeds;
  final int oxygen;
  final double bedConsumptionRate;
  final double oxygenConsumptionRate;
  final double icuConsumptionRate;
  final double ventilatorConsumptionRate;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  const Hospital({
    required this.id,
    required this.name,
    required this.beds,
    this.icuBeds = 0,
    this.ventilators = 0,
    this.pediatricBeds = 0,
    this.traumaBeds = 0,
    required this.oxygen,
    this.bedConsumptionRate = AppConstants.defaultBedConsumptionRate,
    this.oxygenConsumptionRate = AppConstants.defaultOxygenConsumptionRate,
    this.icuConsumptionRate = AppConstants.defaultIcuConsumptionRate,
    this.ventilatorConsumptionRate = AppConstants.defaultVentilatorConsumptionRate,
    this.latitude,
    this.longitude,
    this.lastUpdated,
  });

  // ── Resource status ────────────────────────────────────────────────

  ResourceStatus get status {
    if (beds == 0 || oxygen == 0) return ResourceStatus.critical;
    if (beds <= AppConstants.minBedReserve ||
        oxygen <= AppConstants.minOxygenReserve) {
      return ResourceStatus.low;
    }
    if (beds <= AppConstants.minBedReserve * 2 ||
        oxygen <= AppConstants.minOxygenReserve * 3) {
      return ResourceStatus.moderate;
    }
    return ResourceStatus.stable;
  }

  Color get statusColor {
    switch (status) {
      case ResourceStatus.critical:
        return const Color(0xFFEF4444);
      case ResourceStatus.low:
        return const Color(0xFFF97316);
      case ResourceStatus.moderate:
        return const Color(0xFFFBBF24);
      case ResourceStatus.stable:
        return const Color(0xFF10B981);
    }
  }

  String get statusLabel {
    switch (status) {
      case ResourceStatus.critical:
        return 'CRITICAL';
      case ResourceStatus.low:
        return 'LOW';
      case ResourceStatus.moderate:
        return 'MODERATE';
      case ResourceStatus.stable:
        return 'STABLE';
    }
  }

  // ── Buffer time — predicted hours until resource depletion ─────────

  double get bedBufferHours =>
      bedConsumptionRate > 0 ? beds / bedConsumptionRate : double.infinity;

  double get oxygenBufferHours =>
      oxygenConsumptionRate > 0
          ? oxygen / oxygenConsumptionRate
          : double.infinity;

  double get icuBufferHours =>
      icuConsumptionRate > 0 && icuBeds > 0
          ? icuBeds / icuConsumptionRate
          : double.infinity;

  double get ventilatorBufferHours =>
      ventilatorConsumptionRate > 0 && ventilators > 0
          ? ventilators / ventilatorConsumptionRate
          : double.infinity;

  /// The most urgent buffer — whichever resource depletes first.
  double get criticalBufferHours {
    final buffers = <double>[bedBufferHours, oxygenBufferHours];
    if (icuBeds > 0) buffers.add(icuBufferHours);
    if (ventilators > 0) buffers.add(ventilatorBufferHours);
    return buffers.reduce(min);
  }

  // ── Shadow load — ambulance-adjusted availability ──────────────────

  int incomingAmbulanceCount(List<Ambulance> ambulances) {
    return ambulances
        .where((a) => a.toHospitalId == id && a.isIncoming)
        .length;
  }

  int urgentAmbulanceCount(List<Ambulance> ambulances) {
    return ambulances
        .where((a) => a.toHospitalId == id && a.isIncoming && a.isUrgent)
        .length;
  }

  int predictedBedsAvailable(List<Ambulance> ambulances) {
    return max(0, beds - incomingAmbulanceCount(ambulances));
  }

  int predictedIcuAvailable(List<Ambulance> ambulances) {
    final incomingIcu = ambulances
        .where(
          (a) =>
              a.toHospitalId == id &&
              a.isIncoming &&
              a.patientType == PatientType.icu,
        )
        .length;
    return max(0, icuBeds - incomingIcu);
  }

  // ── Progress fractions (for UI bars) ───────────────────────────────

  double get bedsFraction =>
      (beds / AppConstants.maxBedCapacity).clamp(0.0, 1.0);
  double get oxygenFraction =>
      (oxygen / AppConstants.maxOxygenCapacity).clamp(0.0, 1.0);
  double get icuFraction =>
      (icuBeds / AppConstants.maxIcuCapacity).clamp(0.0, 1.0);
  double get ventilatorFraction =>
      (ventilators / AppConstants.maxVentilatorCapacity).clamp(0.0, 1.0);

  // ── Network health contribution (0-100) ────────────────────────────

  double get healthScore {
    final bedScore = (beds / AppConstants.maxBedCapacity * 100).clamp(0.0, 100.0);
    final o2Score =
        (oxygen / AppConstants.maxOxygenCapacity * 100).clamp(0.0, 100.0);
    final bufferScore =
        (criticalBufferHours / AppConstants.bufferWarningHours * 100)
            .clamp(0.0, 100.0);
    return (bedScore * 0.3 + o2Score * 0.3 + bufferScore * 0.4);
  }

  // ── Surplus above minimum reserve ──────────────────────────────────

  int get bedSurplus => max(0, beds - AppConstants.minBedReserve);
  int get oxygenSurplus => max(0, oxygen - AppConstants.minOxygenReserve);
  int get icuSurplus => max(0, icuBeds - AppConstants.minIcuReserve);
  int get ventilatorSurplus =>
      max(0, ventilators - AppConstants.minVentilatorReserve);

  int get bedDeficit => max(0, AppConstants.minBedReserve - beds);
  int get oxygenDeficit => max(0, AppConstants.minOxygenReserve - oxygen);

  // ── Copy / serialisation ───────────────────────────────────────────

  Hospital copyWith({
    String? id,
    String? name,
    int? beds,
    int? icuBeds,
    int? ventilators,
    int? pediatricBeds,
    int? traumaBeds,
    int? oxygen,
    double? bedConsumptionRate,
    double? oxygenConsumptionRate,
    double? icuConsumptionRate,
    double? ventilatorConsumptionRate,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      beds: beds ?? this.beds,
      icuBeds: icuBeds ?? this.icuBeds,
      ventilators: ventilators ?? this.ventilators,
      pediatricBeds: pediatricBeds ?? this.pediatricBeds,
      traumaBeds: traumaBeds ?? this.traumaBeds,
      oxygen: oxygen ?? this.oxygen,
      bedConsumptionRate: bedConsumptionRate ?? this.bedConsumptionRate,
      oxygenConsumptionRate:
          oxygenConsumptionRate ?? this.oxygenConsumptionRate,
      icuConsumptionRate: icuConsumptionRate ?? this.icuConsumptionRate,
      ventilatorConsumptionRate:
          ventilatorConsumptionRate ?? this.ventilatorConsumptionRate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory Hospital.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    DateTime? lastUpdated;
    final rawUpdated = data['lastUpdated'];
    if (rawUpdated is Timestamp) {
      lastUpdated = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      lastUpdated = DateTime.tryParse(rawUpdated);
    }

    return Hospital(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Unknown',
      beds: _parseInt(data['beds']),
      icuBeds: _parseInt(data['icuBeds']),
      ventilators: _parseInt(data['ventilators']),
      pediatricBeds: _parseInt(data['pediatricBeds']),
      traumaBeds: _parseInt(data['traumaBeds']),
      oxygen: _parseInt(data['oxygen']),
      bedConsumptionRate: _parseDouble(
        data['bedConsumptionRate'],
        AppConstants.defaultBedConsumptionRate,
      ),
      oxygenConsumptionRate: _parseDouble(
        data['oxygenConsumptionRate'],
        AppConstants.defaultOxygenConsumptionRate,
      ),
      icuConsumptionRate: _parseDouble(
        data['icuConsumptionRate'],
        AppConstants.defaultIcuConsumptionRate,
      ),
      ventilatorConsumptionRate: _parseDouble(
        data['ventilatorConsumptionRate'],
        AppConstants.defaultVentilatorConsumptionRate,
      ),
      latitude: _parseNullableDouble(data['latitude']),
      longitude: _parseNullableDouble(data['longitude']),
      lastUpdated: lastUpdated,
    );
  }

  /// Serialise to Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'beds': beds,
      'icuBeds': icuBeds,
      'ventilators': ventilators,
      'pediatricBeds': pediatricBeds,
      'traumaBeds': traumaBeds,
      'oxygen': oxygen,
      'bedConsumptionRate': bedConsumptionRate,
      'oxygenConsumptionRate': oxygenConsumptionRate,
      'icuConsumptionRate': icuConsumptionRate,
      'ventilatorConsumptionRate': ventilatorConsumptionRate,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
