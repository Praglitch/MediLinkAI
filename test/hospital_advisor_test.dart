import 'package:flutter_test/flutter_test.dart';
import 'package:medilink_ai/src/models/hospital.dart';
import 'package:medilink_ai/src/utils/hospital_advisor.dart';

void main() {
  group('HospitalAdvisor', () {
    final sampleHospitals = [
      const Hospital(
        id: 'h1',
        name: 'Central Health',
        beds: 5,
        oxygen: 25,
        lastUpdated: null,
      ),
      const Hospital(
        id: 'h2',
        name: 'North Care',
        beds: 2,
        oxygen: 8,
        lastUpdated: null,
      ),
      const Hospital(
        id: 'h3',
        name: 'East Medical',
        beds: 12,
        oxygen: 40,
        lastUpdated: null,
      ),
    ];

    test('recommends hospital based on "oxygen" query', () {
      final recommendation = HospitalAdvisor.recommendHospital(
        sampleHospitals,
        'oxygen',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.id, equals('h3'));
    });

    test('recommends hospital based on "fever" query', () {
      final recommendation = HospitalAdvisor.recommendHospital(
        sampleHospitals,
        'fever',
      );

      expect(recommendation, isNotNull);
      expect(recommendation!.id, equals('h3'));
    });

    test('returns a transfer suggestion when imbalance exists', () {
      final suggestion = HospitalAdvisor.suggestTransfer(sampleHospitals);
      expect(suggestion, isNotNull);
      expect(suggestion!.fromHospitalId, equals('h3'));
      expect(suggestion.toHospitalId, equals('h2'));
      expect(suggestion.bedTransferAmount, greaterThan(0));
      expect(suggestion.oxygenTransferAmount, greaterThan(0));
    });

    test('returns oxygen-only transfer when beds are balanced', () {
      final oxygenImbalancedHospitals = [
        const Hospital(
          id: 'h1',
          name: 'A',
          beds: 10,
          oxygen: 100,
          lastUpdated: null,
        ),
        const Hospital(
          id: 'h2',
          name: 'B',
          beds: 10,
          oxygen: 20,
          lastUpdated: null,
        ),
      ];

      final suggestion = HospitalAdvisor.suggestTransfer(
        oxygenImbalancedHospitals,
      );

      expect(suggestion, isNotNull);
      expect(suggestion!.hasBedTransfer, isFalse);
      expect(suggestion.hasOxygenTransfer, isTrue);
      expect(suggestion.oxygenFromHospitalId, equals('h1'));
      expect(suggestion.oxygenToHospitalId, equals('h2'));
    });

    test('uses independent oxygen pair when different from bed pair', () {
      final mixedImbalanceHospitals = [
        const Hospital(
          id: 'h1',
          name: 'BedsDonor',
          beds: 30,
          oxygen: 30,
          lastUpdated: null,
        ),
        const Hospital(
          id: 'h2',
          name: 'BedsReceiver',
          beds: 5,
          oxygen: 40,
          lastUpdated: null,
        ),
        const Hospital(
          id: 'h3',
          name: 'OxygenDonor',
          beds: 15,
          oxygen: 120,
          lastUpdated: null,
        ),
        const Hospital(
          id: 'h4',
          name: 'OxygenReceiver',
          beds: 14,
          oxygen: 10,
          lastUpdated: null,
        ),
      ];

      final suggestion = HospitalAdvisor.suggestTransfer(
        mixedImbalanceHospitals,
      );

      expect(suggestion, isNotNull);
      expect(suggestion!.fromHospitalId, equals('h1'));
      expect(suggestion.toHospitalId, equals('h2'));
      expect(suggestion.oxygenFromHospitalId, equals('h3'));
      expect(suggestion.oxygenToHospitalId, equals('h4'));
    });

    test('returns null when hospitals are balanced', () {
      final balancedHospitals = [
        const Hospital(
          id: 'h1',
          name: 'A',
          beds: 10,
          oxygen: 50,
          lastUpdated: null,
        ),
        const Hospital(
          id: 'h2',
          name: 'B',
          beds: 10,
          oxygen: 50,
          lastUpdated: null,
        ),
      ];
      final suggestion = HospitalAdvisor.suggestTransfer(balancedHospitals);
      expect(suggestion, isNull);
    });
  });
}
