/// A single hospital ranking returned by the AI recommendation engine.
class AIRecommendation {
  final String hospitalId;
  final String hospitalName;
  final double score;
  final String reasoning;
  final Map<String, dynamic> factors;

  const AIRecommendation({
    required this.hospitalId,
    required this.hospitalName,
    required this.score,
    required this.reasoning,
    this.factors = const {},
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      hospitalId: json['hospitalId'] as String? ?? '',
      hospitalName: json['hospitalName'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? 'No reasoning provided.',
      factors: json['factors'] as Map<String, dynamic>? ?? const {},
    );
  }
}

/// The complete result of an AI analysis — may contain multiple ranked hospitals.
class AIAnalysisResult {
  final List<AIRecommendation> rankings;
  final String summary;
  final bool isFromAI;
  final DateTime timestamp;

  const AIAnalysisResult({
    required this.rankings,
    required this.summary,
    required this.isFromAI,
    required this.timestamp,
  });

  AIRecommendation? get topPick =>
      rankings.isNotEmpty ? rankings.first : null;

  String? reasoningFor(String hospitalId) {
    for (final r in rankings) {
      if (r.hospitalId == hospitalId) return r.reasoning;
    }
    return null;
  }

  double? scoreFor(String hospitalId) {
    for (final r in rankings) {
      if (r.hospitalId == hospitalId) return r.score;
    }
    return null;
  }
}
