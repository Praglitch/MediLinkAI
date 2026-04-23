import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hospital.dart';
import '../models/transfer_suggestion.dart';
import '../models/audit_log.dart';

/// Hospital data access layer with transactional transfer safety.
class HospitalRepository {
  HospitalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _hospitals =>
      _firestore.collection('hospitals');

  CollectionReference<Map<String, dynamic>> get _auditLog =>
      _firestore.collection('auditLog');

  CollectionReference<Map<String, dynamic>> get _usageSnapshots =>
      _firestore.collection('usageSnapshots');

  // ── Read ──────────────────────────────────────────────────────────

  Stream<List<Hospital>> watchHospitals() {
    return _hospitals.snapshots().map((snapshot) {
      return snapshot.docs.map(Hospital.fromFirestore).toList(growable: false);
    });
  }

  Future<Hospital?> getHospital(String id) async {
    final doc = await _hospitals.doc(id).get();
    if (!doc.exists) return null;
    return Hospital.fromFirestore(doc);
  }

  // ── Update resources ──────────────────────────────────────────────

  Future<void> updateHospitalResources({
    required String hospitalId,
    required int beds,
    required int oxygen,
    int? icuBeds,
    int? ventilators,
    int? pediatricBeds,
    int? traumaBeds,
  }) async {
    if (hospitalId.isEmpty) {
      throw ArgumentError.value(
        hospitalId,
        'hospitalId',
        'Hospital ID is required',
      );
    }
    if (beds < 0 || oxygen < 0) {
      throw ArgumentError('Resource values must be zero or greater');
    }

    final updates = <String, dynamic>{
      'beds': beds,
      'oxygen': oxygen,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    if (icuBeds != null) updates['icuBeds'] = icuBeds;
    if (ventilators != null) updates['ventilators'] = ventilators;
    if (pediatricBeds != null) updates['pediatricBeds'] = pediatricBeds;
    if (traumaBeds != null) updates['traumaBeds'] = traumaBeds;

    await _hospitals.doc(hospitalId).update(updates);

    // Record usage snapshot for buffer-time moving average
    await _usageSnapshots.add({
      'hospitalId': hospitalId,
      'beds': beds,
      'oxygen': oxygen,
      'icuBeds': icuBeds,
      'ventilators': ventilators,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ── Transactional transfer execution ──────────────────────────────

  /// Execute a single transfer inside a Firestore transaction to prevent
  /// race conditions. Validates that the source hospital still has enough
  /// resources before committing.
  Future<void> executeTransfer(
    TransferSuggestion suggestion, {
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // Read current state inside the transaction
      final fromDoc =
          await transaction.get(_hospitals.doc(suggestion.fromHospitalId));
      final toDoc =
          await transaction.get(_hospitals.doc(suggestion.toHospitalId));

      if (!fromDoc.exists || !toDoc.exists) {
        throw Exception('One or both hospitals no longer exist.');
      }

      final fromData = fromDoc.data()!;
      final toData = toDoc.data()!;

      final resourceField = _resourceFieldName(suggestion.resourceType);
      final fromCurrent = _parseInt(fromData[resourceField]);
      final toCurrent = _parseInt(toData[resourceField]);

      // Safety check: source must still have enough
      if (fromCurrent < suggestion.transferAmount) {
        throw Exception(
          '${suggestion.fromHospitalName} only has $fromCurrent '
          '${suggestion.resourceType} remaining. Transfer of '
          '${suggestion.transferAmount} cannot proceed.',
        );
      }

      // Apply the transfer
      transaction.update(_hospitals.doc(suggestion.fromHospitalId), {
        resourceField: FieldValue.increment(-suggestion.transferAmount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      transaction.update(_hospitals.doc(suggestion.toHospitalId), {
        resourceField: FieldValue.increment(suggestion.transferAmount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });

    // Record audit log (outside transaction — non-critical)
    await _auditLog.add(AuditLog(
      id: '',
      userId: userId,
      action: 'transfer',
      fromHospitalId: suggestion.fromHospitalId,
      fromHospitalName: suggestion.fromHospitalName,
      toHospitalId: suggestion.toHospitalId,
      toHospitalName: suggestion.toHospitalName,
      resourceType: suggestion.resourceType,
      amount: suggestion.transferAmount,
      fromBefore: suggestion.fromBefore,
      fromAfter: suggestion.fromAfter,
      toBefore: suggestion.toBefore,
      toAfter: suggestion.toAfter,
      timestamp: DateTime.now(),
    ).toFirestore());
  }

  /// Execute all valid suggestions in a [TransferPlan] sequentially.
  Future<int> executePlan(
    TransferPlan plan, {
    required String userId,
  }) async {
    int executed = 0;
    for (final suggestion in plan.validSuggestions) {
      await executeTransfer(suggestion, userId: userId);
      executed++;
    }
    return executed;
  }

  // ── Helpers ───────────────────────────────────────────────────────

  String _resourceFieldName(String resourceType) {
    switch (resourceType) {
      case 'beds':
        return 'beds';
      case 'oxygen':
        return 'oxygen';
      case 'icuBeds':
        return 'icuBeds';
      case 'ventilators':
        return 'ventilators';
      case 'pediatricBeds':
        return 'pediatricBeds';
      case 'traumaBeds':
        return 'traumaBeds';
      default:
        return 'beds';
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
