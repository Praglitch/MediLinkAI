import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ambulance.dart';

/// Real-time ambulance tracking repository for shadow-load calculations.
class AmbulanceRepository {
  AmbulanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('ambulances');

  /// Stream only active (en-route) ambulances.
  Stream<List<Ambulance>> watchActiveAmbulances() {
    return _collection
        .where('status', isEqualTo: 'enRoute')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(Ambulance.fromFirestore)
          .toList(growable: false);
    });
  }

  /// Stream all ambulances heading to a specific hospital.
  Stream<List<Ambulance>> watchAmbulancesForHospital(String hospitalId) {
    return _collection
        .where('toHospitalId', isEqualTo: hospitalId)
        .where('status', isEqualTo: 'enRoute')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(Ambulance.fromFirestore)
          .toList(growable: false);
    });
  }

  /// Dispatch a new ambulance (for demo / simulation).
  Future<void> dispatchAmbulance({
    required String fromHospitalId,
    required String fromHospitalName,
    required String toHospitalId,
    required String toHospitalName,
    required PatientType patientType,
    required int etaMinutes,
  }) async {
    await _collection.add({
      'fromHospitalId': fromHospitalId,
      'fromHospitalName': fromHospitalName,
      'toHospitalId': toHospitalId,
      'toHospitalName': toHospitalName,
      'patientType': patientType.name,
      'eta': Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: etaMinutes)),
      ),
      'status': 'enRoute',
      'dispatchedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark an ambulance as arrived.
  Future<void> markArrived(String ambulanceId) async {
    await _collection.doc(ambulanceId).update({'status': 'arrived'});
  }
}
