import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/audit_log.dart';

/// Stores and retrieves transfer audit logs for accountability.
class AuditRepository {
  AuditRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('auditLog');

  /// Stream the most recent audit entries, newest first.
  Stream<List<AuditLog>> watchAuditLog({int limit = 50}) {
    return _collection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(AuditLog.fromFirestore)
          .toList(growable: false);
    });
  }

  /// Record a new audit entry.
  Future<void> record(AuditLog entry) async {
    await _collection.add(entry.toFirestore());
  }

  /// Get total number of transfers executed (for lives-impacted counter).
  Future<int> totalTransferCount() async {
    final snapshot =
        await _collection.where('action', isEqualTo: 'transfer').count().get();
    return snapshot.count ?? 0;
  }
}
