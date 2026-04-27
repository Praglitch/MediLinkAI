/// Immutable record of a resource transfer for full audit trail.
class AuditLog {
  final String id;
  final String userId;
  final String action;
  final String fromHospitalId;
  final String fromHospitalName;
  final String toHospitalId;
  final String toHospitalName;
  final String resourceType;
  final int amount;
  final int fromBefore;
  final int fromAfter;
  final int toBefore;
  final int toAfter;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.fromHospitalId,
    required this.fromHospitalName,
    required this.toHospitalId,
    required this.toHospitalName,
    required this.resourceType,
    required this.amount,
    required this.fromBefore,
    required this.fromAfter,
    required this.toBefore,
    required this.toAfter,
    required this.timestamp,
  });

  factory AuditLog.fromFirestore(dynamic snapshot) {
    final data = (snapshot is Map ? snapshot : snapshot.data()) as Map<String, dynamic>? ?? {};
    final rawTs = data['timestamp'];
    DateTime ts = DateTime.now();
    if (rawTs is DateTime) {
      ts = rawTs;
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    }

    return AuditLog(
      id: snapshot.id,
      userId: data['userId'] as String? ?? 'unknown',
      action: data['action'] as String? ?? 'transfer',
      fromHospitalId: data['fromHospitalId'] as String? ?? '',
      fromHospitalName: data['fromHospitalName'] as String? ?? '',
      toHospitalId: data['toHospitalId'] as String? ?? '',
      toHospitalName: data['toHospitalName'] as String? ?? '',
      resourceType: data['resourceType'] as String? ?? 'beds',
      amount: _parseInt(data['amount']),
      fromBefore: _parseInt(data['fromBefore']),
      fromAfter: _parseInt(data['fromAfter']),
      toBefore: _parseInt(data['toBefore']),
      toAfter: _parseInt(data['toAfter']),
      timestamp: ts,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'action': action,
      'fromHospitalId': fromHospitalId,
      'fromHospitalName': fromHospitalName,
      'toHospitalId': toHospitalId,
      'toHospitalName': toHospitalName,
      'resourceType': resourceType,
      'amount': amount,
      'fromBefore': fromBefore,
      'fromAfter': fromAfter,
      'toBefore': toBefore,
      'toAfter': toAfter,
      'timestamp': DateTime.now(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
