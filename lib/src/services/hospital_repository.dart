import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital.dart';
import '../models/transfer_suggestion.dart';
import '../models/audit_log.dart';

/// Production Hospital repository using Cloud Firestore.
class HospitalRepository {
  HospitalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Hospital>> watchHospitals() {
    return _firestore
        .collection('hospitals')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Hospital.fromFirestore(doc))
            .toList());
  }

  Future<Hospital?> getHospital(String id) async {
    final doc = await _firestore.collection('hospitals').doc(id).get();
    if (!doc.exists) return null;
    return Hospital.fromFirestore(doc);
  }

  Future<void> updateHospitalResources({
    required String hospitalId,
    required int beds,
    required int oxygen,
    int? icuBeds,
    int? ventilators,
  }) async {
    await _firestore.collection('hospitals').doc(hospitalId).update({
      'beds': beds,
      'oxygen': oxygen,
      if (icuBeds != null) 'icuBeds': icuBeds,
      if (ventilators != null) 'ventilators': ventilators,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> executeTransfer(
    TransferSuggestion suggestion, {
    required String userId,
  }) async {
    final batch = _firestore.batch();
    
    final fromRef = _firestore.collection('hospitals').doc(suggestion.fromHospitalId);
    final toRef = _firestore.collection('hospitals').doc(suggestion.toHospitalId);
    final auditRef = _firestore.collection('audit_logs').doc();

    batch.update(fromRef, {
      'beds': suggestion.fromBefore - suggestion.transferAmount,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    batch.update(toRef, {
      'beds': suggestion.toBefore + suggestion.transferAmount,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    batch.set(auditRef, {
      'userId': userId,
      'action': 'transfer',
      'fromHospitalId': suggestion.fromHospitalId,
      'fromHospitalName': suggestion.fromHospitalName,
      'toHospitalId': suggestion.toHospitalId,
      'toHospitalName': suggestion.toHospitalName,
      'resourceType': suggestion.resourceType,
      'amount': suggestion.transferAmount,
      'fromBefore': suggestion.fromBefore,
      'fromAfter': suggestion.fromBefore - suggestion.transferAmount,
      'toBefore': suggestion.toBefore,
      'toAfter': suggestion.toBefore + suggestion.transferAmount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<int> executePlan(
    TransferPlan plan, {
    required String userId,
  }) async {
    int count = 0;
    for (final suggestion in plan.validSuggestions) {
      await executeTransfer(suggestion, userId: userId);
      count++;
    }
    return count;
  }
}
