/// Describes a single resource redistribution action between two hospitals.
class TransferSuggestion {
  final String fromHospitalId;
  final String fromHospitalName;
  final String toHospitalId;
  final String toHospitalName;
  final String resourceType;
  final int transferAmount;
  final int fromBefore;
  final int toBefore;
  final String reason;
  final double urgencyScore;
  final int transitMinutes;
  final int deteriorationDuringTransit;
  final bool blockedByAmbulance;

  const TransferSuggestion({
    required this.fromHospitalId,
    required this.fromHospitalName,
    required this.toHospitalId,
    required this.toHospitalName,
    required this.resourceType,
    required this.transferAmount,
    required this.fromBefore,
    required this.toBefore,
    required this.reason,
    this.urgencyScore = 0.0,
    this.transitMinutes = 25,
    this.deteriorationDuringTransit = 0,
    this.blockedByAmbulance = false,
  });

  int get fromAfter => fromBefore - transferAmount;
  int get toAfter => toBefore + transferAmount;
  bool get isValid => transferAmount > 0 && !blockedByAmbulance;

  String get label => '$transferAmount $resourceType';
  String get directionLabel =>
      '$fromHospitalName → $toHospitalName';
}

/// A complete transfer plan that may include multiple individual transfers.
class TransferPlan {
  final List<TransferSuggestion> suggestions;
  final String summary;
  final double networkHealthBefore;
  final double networkHealthAfter;
  final DateTime generatedAt;

  const TransferPlan({
    required this.suggestions,
    required this.summary,
    required this.networkHealthBefore,
    required this.networkHealthAfter,
    required this.generatedAt,
  });

  List<TransferSuggestion> get validSuggestions =>
      suggestions.where((s) => s.isValid).toList();

  bool get hasActions => validSuggestions.isNotEmpty;

  double get healthImprovement => networkHealthAfter - networkHealthBefore;
}
