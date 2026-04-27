import 'package:flutter_test/flutter_test.dart';
import 'package:medilink_ai/src/models/hospital.dart';
import 'package:medilink_ai/src/utils/hospital_advisor.dart';

void main() {
  group('HospitalAdvisor', () {
    final sampleHospitals = [
      const Hospital(
        id: 'h1',
        name: 'Central Health',
        beds: 50,
        icuBeds: 10,
        ventilators: 5,
        pediatricBeds: 5,
        traumaBeds: 5,
        oxygen: 100,
        bedConsumptionRate: 1.0,
        oxygenConsumptionRate: 5.0,
        lastUpdated: null,
      ),
      const Hospital(
        id: 'h2',
        name: 'North Care',
        beds: 5,
        icuBeds: 2,
        ventilators: 1,
        pediatricBeds: 0,
        traumaBeds: 0,
        oxygen: 20,
        bedConsumptionRate: 2.0,
        oxygenConsumptionRate: 10.0,
        lastUpdated: null,
      ),
    ];

    test('calculates network health score correctly', () {
      final score = HospitalAdvisor.networkHealthScore(sampleHospitals);
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('finds earliest collapse correctly', () {
      final worst = HospitalAdvisor.earliestCollapse(sampleHospitals);
      expect(worst, isNotNull);
      expect(worst!.id, equals('h2'));
    });
  });
}
