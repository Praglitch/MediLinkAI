import '../models/hospital.dart';
import '../models/ambulance.dart';
import '../models/audit_log.dart';

class MockData {
  static List<Hospital> get hospitals => [
        const Hospital(
          id: 'h1',
          name: 'City General Hospital',
          beds: 45,
          icuBeds: 8,
          ventilators: 12,
          pediatricBeds: 10,
          traumaBeds: 5,
          oxygen: 350,
          latitude: 12.9716,
          longitude: 77.5946,
        ),
        const Hospital(
          id: 'h2',
          name: 'Metro Medical Center',
          beds: 5, 
          icuBeds: 1,
          ventilators: 2,
          pediatricBeds: 2,
          traumaBeds: 1,
          oxygen: 40,
          latitude: 12.9352,
          longitude: 77.6245,
        ),
        const Hospital(
          id: 'h3',
          name: 'St. Jude Children\'s',
          beds: 80,
          icuBeds: 15,
          ventilators: 20,
          pediatricBeds: 50,
          traumaBeds: 10,
          oxygen: 480,
          latitude: 12.9801,
          longitude: 77.5872,
        ),
      ];

  static List<Ambulance> get ambulances => [
        Ambulance(
          id: 'a1',
          fromHospitalId: 'h1',
          fromHospitalName: 'City General',
          toHospitalId: 'h2',
          toHospitalName: 'Metro Medical',
          patientType: PatientType.icu,
          status: AmbulanceStatus.enRoute,
          eta: DateTime.now().add(const Duration(minutes: 12)),
          dispatchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        Ambulance(
          id: 'a2',
          fromHospitalId: 'h3',
          fromHospitalName: 'St. Jude',
          toHospitalId: 'h1',
          toHospitalName: 'City General',
          patientType: PatientType.general,
          status: AmbulanceStatus.enRoute,
          eta: DateTime.now().add(const Duration(minutes: 5)),
          dispatchedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ];

  static List<AuditLog> get auditLogs => [
        AuditLog(
          id: 'l1',
          userId: 'mock-admin',
          action: 'transfer',
          fromHospitalId: 'h1',
          fromHospitalName: 'City General',
          toHospitalId: 'h2',
          toHospitalName: 'Metro Medical',
          resourceType: 'beds',
          amount: 5,
          fromBefore: 50,
          fromAfter: 45,
          toBefore: 0,
          toAfter: 5,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
}
