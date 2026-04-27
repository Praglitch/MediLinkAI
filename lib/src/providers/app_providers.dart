import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_recommendation.dart';
import '../models/ambulance.dart';
import '../models/audit_log.dart';
import '../models/hospital.dart';
import '../models/transfer_suggestion.dart';
import '../services/ai_service.dart';
import '../services/ambulance_repository.dart';
import '../services/audit_repository.dart';
import '../services/auth_service.dart';
import '../services/hospital_repository.dart';
import '../utils/constants.dart';
import '../utils/hospital_advisor.dart';
import '../services/mock_data.dart';

/// Central application state — single source of truth for all live data.
///
/// Replaces per-screen StreamBuilder + manual repository instantiation
/// with a shared, lifecycle-aware state object exposed via Provider.
class AppState extends ChangeNotifier {
  AppState({
    HospitalRepository? hospitalRepo,
    AmbulanceRepository? ambulanceRepo,
    AuditRepository? auditRepo,
    AIService? aiService,
    AuthService? authService,
  })  : _hospitalRepo = hospitalRepo ?? HospitalRepository(),
        _ambulanceRepo = ambulanceRepo ?? AmbulanceRepository(),
        _auditRepo = auditRepo ?? AuditRepository(),
        _aiService = aiService ?? AIService(),
        authService = authService ?? AuthService() {
    _init();
  }

  final HospitalRepository _hospitalRepo;
  final AmbulanceRepository _ambulanceRepo;
  final AuditRepository _auditRepo;
  final AIService _aiService;
  final AuthService authService;

  StreamSubscription<List<Hospital>>? _hospitalSub;
  StreamSubscription<List<Ambulance>>? _ambulanceSub;
  StreamSubscription<List<AuditLog>>? _auditSub;

  // ── Live data ──────────────────────────────────────────────────────

  List<Hospital> hospitals = [];
  List<Ambulance> ambulances = [];
  List<AuditLog> auditLogs = [];
  bool isLoading = true;
  String? error;

  // ── AI state ───────────────────────────────────────────────────────

  bool isAnalysing = false;
  AIAnalysisResult? analysisResult;
  String currentQuery = '';

  // ── Transfer state ─────────────────────────────────────────────────

  bool isTransferring = false;
  TransferPlan? currentPlan;

  // ── Simulation state ───────────────────────────────────────────────

  bool isSimulationMode = false;
  bool isMockMode = false;
  double simPatientRate = 5.0;
  double simConsumptionRate = AppConstants.defaultBedConsumptionRate;
  List<Hospital>? _simulatedHospitals;

  List<Hospital> get effectiveHospitals {
    if (isMockMode && hospitals.isEmpty) return MockData.hospitals;
    return isSimulationMode ? (_simulatedHospitals ?? hospitals) : hospitals;
  }

  List<Ambulance> get effectiveAmbulances {
    if (isMockMode && ambulances.isEmpty) return MockData.ambulances;
    return ambulances;
  }

  List<AuditLog> get effectiveAuditLogs {
    if (isMockMode && auditLogs.isEmpty) return MockData.auditLogs;
    return auditLogs;
  }

  // ── Computed properties ────────────────────────────────────────────

  double get networkHealthScore =>
      HospitalAdvisor.networkHealthScore(effectiveHospitals);

  Hospital? get earliestCollapse =>
      HospitalAdvisor.earliestCollapse(effectiveHospitals);

  String get systemStatusLabel =>
      HospitalAdvisor.systemStatusLabel(effectiveHospitals);

  int get livesImpacted =>
      effectiveAuditLogs.length * AppConstants.estimatedLivesPerTransfer;

  int get totalTransfers => effectiveAuditLogs.length;

  bool get hasAIKey => _aiService.isConfigured;

  // ── Initialisation ─────────────────────────────────────────────────

  void _init() {
    _hospitalSub = _hospitalRepo.watchHospitals().listen(
      (data) {
        hospitals = data;
        isLoading = false;
        error = null;
        _refreshPlan();
        notifyListeners();
      },
      onError: (e) {
        if (isMockMode) return;
        error = 'Failed to load hospitals: $e';
        isLoading = false;
        notifyListeners();
      },
    );

    _ambulanceSub = _ambulanceRepo.watchActiveAmbulances().listen(
      (data) {
        ambulances = data;
        _refreshPlan();
        notifyListeners();
      },
      onError: (_) {
        // Ambulance stream failure is non-critical
      },
    );

    _auditSub = _auditRepo.watchAuditLog().listen(
      (data) {
        auditLogs = data;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void _refreshPlan() {
    currentPlan = HospitalAdvisor.generateTransferPlan(
      hospitals: effectiveHospitals,
      ambulances: effectiveAmbulances,
    );
  }

  void enableMockMode() {
    isMockMode = true;
    isLoading = false;
    error = null;
    _hospitalSub?.cancel();
    _ambulanceSub?.cancel();
    _auditSub?.cancel();
    _refreshPlan();
    notifyListeners();
  }

  // ── AI analysis ────────────────────────────────────────────────────

  Future<void> analyseQuery(String query) async {
    if (query.trim().isEmpty) return;

    currentQuery = query.trim();
    isAnalysing = true;
    notifyListeners();

    try {
      analysisResult = await _aiService.analyse(
        query: currentQuery,
        hospitals: effectiveHospitals,
      );
    } catch (e) {
      // Fallback already handled inside AIService
      analysisResult = null;
    } finally {
      isAnalysing = false;
      notifyListeners();
    }
  }

  void clearAnalysis() {
    analysisResult = null;
    currentQuery = '';
    notifyListeners();
  }

  // ── Transfer execution ─────────────────────────────────────────────

  Future<bool> executeTransfer(TransferSuggestion suggestion) async {
    isTransferring = true;
    notifyListeners();

    try {
      await _hospitalRepo.executeTransfer(
        suggestion,
        userId: authService.userId,
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isTransferring = false;
      notifyListeners();
    }
  }

  Future<int> executePlan() async {
    if (currentPlan == null) return 0;
    isTransferring = true;
    notifyListeners();

    try {
      final count = await _hospitalRepo.executePlan(
        currentPlan!,
        userId: authService.userId,
      );
      return count;
    } catch (e) {
      error = e.toString();
      return 0;
    } finally {
      isTransferring = false;
      notifyListeners();
    }
  }

  // ── Resource updates ───────────────────────────────────────────────

  Future<bool> updateResources({
    required String hospitalId,
    required int beds,
    required int oxygen,
    int? icuBeds,
    int? ventilators,
  }) async {
    try {
      await _hospitalRepo.updateHospitalResources(
        hospitalId: hospitalId,
        beds: beds,
        oxygen: oxygen,
        icuBeds: icuBeds,
        ventilators: ventilators,
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Simulation ─────────────────────────────────────────────────────

  void enterSimulation() {
    isSimulationMode = true;
    _simulatedHospitals = hospitals.map((h) => h.copyWith()).toList();
    notifyListeners();
  }

  void exitSimulation() {
    isSimulationMode = false;
    _simulatedHospitals = null;
    _refreshPlan();
    notifyListeners();
  }

  void updateSimulation({double? patientRate, double? consumptionRate}) {
    if (patientRate != null) simPatientRate = patientRate;
    if (consumptionRate != null) simConsumptionRate = consumptionRate;

    // Recalculate simulated hospitals based on new rates
    _simulatedHospitals = hospitals.map((h) {
      final simBeds =
          (h.beds - (simPatientRate * 0.5)).round().clamp(0, h.beds);
      final simOxygen =
          (h.oxygen - (simPatientRate * 2)).round().clamp(0, h.oxygen);
      return h.copyWith(
        beds: simBeds,
        oxygen: simOxygen,
        bedConsumptionRate: simConsumptionRate,
        oxygenConsumptionRate: simConsumptionRate * 2.5,
      );
    }).toList();

    _refreshPlan();
    notifyListeners();
  }

  // ── What-If ────────────────────────────────────────────────────────

  TransferPlan whatIfOffline(String hospitalId) {
    return HospitalAdvisor.whatIfHospitalOffline(
      offlineHospitalId: hospitalId,
      hospitals: effectiveHospitals,
      ambulances: ambulances,
    );
  }

  // ── Cleanup ────────────────────────────────────────────────────────

  @override
  void dispose() {
    _hospitalSub?.cancel();
    _ambulanceSub?.cancel();
    _auditSub?.cancel();
    super.dispose();
  }
}
