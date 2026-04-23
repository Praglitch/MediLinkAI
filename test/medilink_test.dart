import 'package:flutter_test/flutter_test.dart';

import 'package:medilink_ai/src/models/hospital.dart';
import 'package:medilink_ai/src/models/ambulance.dart';
import 'package:medilink_ai/src/models/transfer_suggestion.dart';
import 'package:medilink_ai/src/utils/hospital_advisor.dart';
import 'package:medilink_ai/src/utils/constants.dart';
import 'package:medilink_ai/src/utils/time_utils.dart';

void main() {
  group('Hospital Model', () {
    test('buffer time calculates correctly for beds', () {
      final hospital = Hospital(
        id: 'h1',
        name: 'Test Hospital',
        beds: 10,
        oxygen: 50,
        bedConsumptionRate: 2.0,
        oxygenConsumptionRate: 5.0,
      );
      expect(hospital.bedBufferHours, 5.0);
      expect(hospital.oxygenBufferHours, 10.0);
    });

    test('buffer time is infinity when consumption rate is zero', () {
      final hospital = Hospital(
        id: 'h1',
        name: 'Test Hospital',
        beds: 10,
        oxygen: 50,
        bedConsumptionRate: 0.0,
        oxygenConsumptionRate: 0.0,
      );
      expect(hospital.bedBufferHours, double.infinity);
      expect(hospital.oxygenBufferHours, double.infinity);
    });

    test('critical buffer hours returns minimum across resources', () {
      final hospital = Hospital(
        id: 'h1',
        name: 'Test Hospital',
        beds: 4,
        oxygen: 100,
        bedConsumptionRate: 2.0,
        oxygenConsumptionRate: 5.0,
      );
      // Beds: 4/2 = 2h, Oxygen: 100/5 = 20h → critical = 2h
      expect(hospital.criticalBufferHours, 2.0);
    });

    test('status returns critical when beds or oxygen is zero', () {
      final hospital = Hospital(id: 'h1', name: 'Test', beds: 0, oxygen: 50);
      expect(hospital.status, ResourceStatus.critical);
    });

    test('status returns low when beds below min reserve', () {
      final hospital = Hospital(
        id: 'h1',
        name: 'Test',
        beds: AppConstants.minBedReserve,
        oxygen: 50,
      );
      expect(hospital.status, ResourceStatus.low);
    });

    test('predicted beds accounts for incoming ambulances', () {
      final hospital = Hospital(id: 'h1', name: 'Test', beds: 10, oxygen: 50);
      final ambulances = [
        Ambulance(
          id: 'a1',
          fromHospitalId: 'h2',
          fromHospitalName: 'Other',
          toHospitalId: 'h1',
          toHospitalName: 'Test',
          patientType: PatientType.general,
          eta: DateTime.now().add(const Duration(minutes: 10)),
          status: AmbulanceStatus.enRoute,
          dispatchedAt: DateTime.now(),
        ),
        Ambulance(
          id: 'a2',
          fromHospitalId: 'h2',
          fromHospitalName: 'Other',
          toHospitalId: 'h1',
          toHospitalName: 'Test',
          patientType: PatientType.icu,
          eta: DateTime.now().add(const Duration(minutes: 5)),
          status: AmbulanceStatus.enRoute,
          dispatchedAt: DateTime.now(),
        ),
      ];
      expect(hospital.predictedBedsAvailable(ambulances), 8);
    });

    test('health score is in 0-100 range', () {
      final hospital = Hospital(id: 'h1', name: 'Test', beds: 50, oxygen: 250);
      expect(hospital.healthScore, greaterThanOrEqualTo(0));
      expect(hospital.healthScore, lessThanOrEqualTo(100));
    });

    test('surplus and deficit calculations', () {
      final hospital = Hospital(id: 'h1', name: 'Test', beds: 3, oxygen: 50);
      expect(hospital.bedDeficit, AppConstants.minBedReserve - 3);
      expect(hospital.bedSurplus, 0);
      expect(hospital.oxygenSurplus, 50 - AppConstants.minOxygenReserve);
    });
  });

  group('HospitalAdvisor', () {
    final hospitals = [
      Hospital(id: 'h1', name: 'Alpha', beds: 20, oxygen: 100),
      Hospital(id: 'h2', name: 'Beta', beds: 2, oxygen: 8),
      Hospital(id: 'h3', name: 'Gamma', beds: 15, oxygen: 60),
    ];

    test('network health score is calculated', () {
      final score = HospitalAdvisor.networkHealthScore(hospitals);
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('earliest collapse returns hospital with lowest buffer', () {
      final worst = HospitalAdvisor.earliestCollapse(hospitals);
      expect(worst, isNotNull);
      expect(worst!.id, 'h2'); // Beta has 2 beds → 1h buffer
    });

    test('system status label reflects critical hospitals', () {
      final label = HospitalAdvisor.systemStatusLabel(hospitals);
      expect(label, isNotEmpty);
    });

    test('safe transfer amount respects minimum reserve', () {
      final amount = HospitalAdvisor.safeTransferAmount(
        fromCurrent: 10,
        toCurrent: 2,
        minReserve: AppConstants.minBedReserve,
        ambulances: [],
        fromHospitalId: 'h1',
      );
      expect(amount, greaterThan(0));
      // Donor has 10, reserve is 5, so safe = 5
      // Receiver needs 5-2 = 3 + deterioration
      expect(amount, lessThanOrEqualTo(10 - AppConstants.minBedReserve));
    });

    test('safe transfer amount returns 0 when donor has no surplus', () {
      final amount = HospitalAdvisor.safeTransferAmount(
        fromCurrent: 3,
        toCurrent: 2,
        minReserve: AppConstants.minBedReserve,
        ambulances: [],
        fromHospitalId: 'h1',
      );
      expect(amount, 0);
    });

    test('transfer plan generates suggestions for deficit hospitals', () {
      final plan = HospitalAdvisor.generateTransferPlan(
        hospitals: hospitals,
        ambulances: [],
      );
      expect(plan.suggestions, isNotEmpty);
      // Beta (2 beds) should receive from Alpha (20 beds)
      final bedTransfer = plan.suggestions
          .where((s) => s.resourceType == 'beds')
          .firstOrNull;
      expect(bedTransfer, isNotNull);
      expect(bedTransfer!.toHospitalId, 'h2');
    });

    test('transfer plan blocks when ambulance incoming', () {
      final ambulances = [
        Ambulance(
          id: 'a1',
          fromHospitalId: 'h2',
          fromHospitalName: 'Beta',
          toHospitalId: 'h1',
          toHospitalName: 'Alpha',
          patientType: PatientType.general,
          eta: DateTime.now().add(const Duration(minutes: 10)),
          status: AmbulanceStatus.enRoute,
          dispatchedAt: DateTime.now(),
        ),
      ];
      // This shouldn't crash and should still find a donor
      final plan = HospitalAdvisor.generateTransferPlan(
        hospitals: hospitals,
        ambulances: ambulances,
      );
      expect(plan, isNotNull);
    });

    test('what-if offline generates valid plan', () {
      final plan = HospitalAdvisor.whatIfHospitalOffline(
        offlineHospitalId: 'h1',
        hospitals: hospitals,
        ambulances: [],
      );
      expect(plan.summary, contains('Alpha'));
      expect(plan.networkHealthBefore, greaterThan(0));
    });
  });

  group('TimeUtils', () {
    test('formatBufferTime handles edge cases', () {
      expect(TimeUtils.formatBufferTime(0), 'DEPLETED');
      expect(TimeUtils.formatBufferTime(double.infinity), '∞');
      expect(TimeUtils.formatBufferTime(0.5), '30m');
      expect(TimeUtils.formatBufferTime(3.5), '3.5h');
      expect(TimeUtils.formatBufferTime(48), '2.0d');
    });

    test('formatRelativeTime returns human-readable strings', () {
      expect(TimeUtils.formatRelativeTime(DateTime.now()), 'just now');
      expect(
        TimeUtils.formatRelativeTime(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        '5m ago',
      );
      expect(
        TimeUtils.formatRelativeTime(
          DateTime.now().subtract(const Duration(hours: 3)),
        ),
        '3h ago',
      );
    });
  });

  group('TransferSuggestion', () {
    test('fromAfter and toAfter calculated correctly', () {
      final suggestion = TransferSuggestion(
        fromHospitalId: 'h1',
        fromHospitalName: 'Alpha',
        toHospitalId: 'h2',
        toHospitalName: 'Beta',
        resourceType: 'beds',
        transferAmount: 5,
        fromBefore: 20,
        toBefore: 2,
        reason: 'test',
      );
      expect(suggestion.fromAfter, 15);
      expect(suggestion.toAfter, 7);
    });

    test('isValid is false when blocked by ambulance', () {
      final suggestion = TransferSuggestion(
        fromHospitalId: 'h1',
        fromHospitalName: 'Alpha',
        toHospitalId: 'h2',
        toHospitalName: 'Beta',
        resourceType: 'beds',
        transferAmount: 5,
        fromBefore: 20,
        toBefore: 2,
        reason: 'test',
        blockedByAmbulance: true,
      );
      expect(suggestion.isValid, false);
    });
  });
}
