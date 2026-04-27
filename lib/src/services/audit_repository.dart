import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';

/// Production Audit repository using Cloud Firestore.
class AuditRepository {
  AuditRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AuditLog>> watchAuditLog({int limit = 50}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLog.fromFirestore(doc))
            .toList());
  }

  Future<void> record(AuditLog entry) async {
    await _firestore.collection('audit_logs').add(entry.toFirestore());
  }

  Future<int> totalTransferCount() async {
    final snapshot = await _firestore.collection('audit_logs').count().get();
    return snapshot.count ?? 0;
  }
}
