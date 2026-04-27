import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ambulance.dart';

/// Production Ambulance repository using Cloud Firestore.
class AmbulanceRepository {
  AmbulanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Ambulance>> watchActiveAmbulances() {
    return _firestore
        .collection('ambulances')
        .where('status', isEqualTo: 'enRoute')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ambulance.fromFirestore(doc))
            .toList());
  }

  Stream<List<Ambulance>> watchAmbulancesForHospital(String hospitalId) {
    return _firestore
        .collection('ambulances')
        .where('toHospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ambulance.fromFirestore(doc))
            .toList());
  }

  Future<void> dispatchAmbulance({
    required String fromHospitalId,
    required String fromHospitalName,
    required String toHospitalId,
    required String toHospitalName,
    required PatientType patientType,
    required int etaMinutes,
  }) async {
    final eta = DateTime.now().add(Duration(minutes: etaMinutes));
    await _firestore.collection('ambulances').add({
      'fromHospitalId': fromHospitalId,
      'fromHospitalName': fromHospitalName,
      'toHospitalId': toHospitalId,
      'toHospitalName': toHospitalName,
      'patientType': patientType.name,
      'eta': eta,
      'status': 'enRoute',
      'dispatchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markArrived(String ambulanceId) async {
    await _firestore.collection('ambulances').doc(ambulanceId).update({
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
    });
  }
}
