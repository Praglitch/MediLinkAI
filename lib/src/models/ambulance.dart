/// Real-time ambulance status for shadow-load prediction.
enum AmbulanceStatus { enRoute, arrived, cancelled }

/// Patient severity classification carried by the ambulance.
enum PatientType { general, icu, trauma, pediatric }

class Ambulance {
  final String id;
  final String fromHospitalId;
  final String fromHospitalName;
  final String toHospitalId;
  final String toHospitalName;
  final PatientType patientType;
  final DateTime eta;
  final AmbulanceStatus status;
  final DateTime dispatchedAt;

  const Ambulance({
    required this.id,
    required this.fromHospitalId,
    required this.fromHospitalName,
    required this.toHospitalId,
    required this.toHospitalName,
    required this.patientType,
    required this.eta,
    required this.status,
    required this.dispatchedAt,
  });

  bool get isIncoming => status == AmbulanceStatus.enRoute;

  bool get isUrgent {
    final minutesLeft = eta.difference(DateTime.now()).inMinutes;
    return minutesLeft >= 0 && minutesLeft < 30;
  }

  int get etaMinutes {
    final mins = eta.difference(DateTime.now()).inMinutes;
    return mins < 0 ? 0 : mins;
  }

  String get patientTypeLabel {
    switch (patientType) {
      case PatientType.general:
        return 'General';
      case PatientType.icu:
        return 'ICU';
      case PatientType.trauma:
        return 'Trauma';
      case PatientType.pediatric:
        return 'Pediatric';
    }
  }

  factory Ambulance.fromFirestore(dynamic snapshot) {
    final data = (snapshot is Map ? snapshot : snapshot.data()) as Map<String, dynamic>? ?? {};

    return Ambulance(
      id: snapshot is Map ? (data['id'] ?? '') : snapshot.id,
      fromHospitalId: data['fromHospitalId'] as String? ?? '',
      fromHospitalName: data['fromHospitalName'] as String? ?? '',
      toHospitalId: data['toHospitalId'] as String? ?? '',
      toHospitalName: data['toHospitalName'] as String? ?? '',
      patientType: _parsePatientType(data['patientType']),
      eta: _parseDateTime(data['eta']),
      status: _parseStatus(data['status']),
      dispatchedAt: _parseDateTime(data['dispatchedAt']),
    );
  }

  static PatientType _parsePatientType(dynamic value) {
    switch (value?.toString()) {
      case 'icu':
        return PatientType.icu;
      case 'trauma':
        return PatientType.trauma;
      case 'pediatric':
        return PatientType.pediatric;
      default:
        return PatientType.general;
    }
  }

  static AmbulanceStatus _parseStatus(dynamic value) {
    switch (value?.toString()) {
      case 'arrived':
        return AmbulanceStatus.arrived;
      case 'cancelled':
        return AmbulanceStatus.cancelled;
      default:
        return AmbulanceStatus.enRoute;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
