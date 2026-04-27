import 'dart:convert';
import 'dart:math' show min;

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/ai_recommendation.dart';
import '../models/hospital.dart';
import '../models/volunteer_model.dart';
import '../utils/constants.dart';
import 'mock_data.dart';

/// Wraps the Gemini API for intelligent hospital recommendation.
///
/// Falls back to offline heuristic scoring when the API key is missing or
/// the network call fails, ensuring the app always produces a result.
class AIService {
  AIService({String? apiKey})
      : _apiKey = apiKey ?? AppConstants.geminiApiKey;

  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Analyse a user query against live hospital data via Gemini.
  Future<AIAnalysisResult> analyse({
    required String query,
    required List<Hospital> hospitals,
  }) async {
    if (!isConfigured || hospitals.isEmpty) {
      return _triageEngineAnalysis(query, hospitals);
    }

    try {
      final model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.3,
          responseSchema: Schema.object(
            properties: {
              'summary': Schema.string(),
              'rankings': Schema.array(
                items: Schema.object(
                  properties: {
                    'hospitalId': Schema.string(),
                    'hospitalName': Schema.string(),
                    'score': Schema.integer(),
                    'reasoning': Schema.string(),
                    'factors': Schema.object(
                      properties: {
                        'resourceMatch': Schema.integer(),
                        'bufferTime': Schema.integer(),
                        'specialtyFit': Schema.integer(),
                      },
                    ),
                  },
                ),
              ),
            },
          ),
        ),
      );

      final prompt = _buildPrompt(query, hospitals);
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return _triageEngineAnalysis(query, hospitals);
      }

      return _parseResponse(text, hospitals);
    } catch (_) {
      return _triageEngineAnalysis(query, hospitals);
    }
  }

  String _buildPrompt(String query, List<Hospital> hospitals) {
    final hospitalData = hospitals.map((h) {
      return {
        'id': h.id,
        'name': h.name,
        'beds': h.beds,
        'icuBeds': h.icuBeds,
        'ventilators': h.ventilators,
        'pediatricBeds': h.pediatricBeds,
        'traumaBeds': h.traumaBeds,
        'oxygen': h.oxygen,
        'bedBufferHours': h.bedBufferHours == double.infinity
            ? 'unlimited'
            : h.bedBufferHours.toStringAsFixed(1),
        'oxygenBufferHours': h.oxygenBufferHours == double.infinity
            ? 'unlimited'
            : h.oxygenBufferHours.toStringAsFixed(1),
        'status': h.statusLabel,
      };
    }).toList();

    return '''
You are MediLink AI, a community volunteer coordination engine that helps NGOs
and local organizations identify the best resource nodes and match volunteers
to urgent community needs.

A user describes a community need or emergency. You must rank the available
community resource nodes (hospitals, NGOs, community hubs) from best to worst
for addressing this need, based on:
1. Resource availability matching the community's likely needs
2. Buffer time (how long the node can sustain at current consumption — predicts resource depletion)
3. Overall node status (critical/low/moderate/stable)
4. Specialty match (ICU for critical cases, trauma beds for accidents, general resources for community needs)
5. Volunteer accessibility (prefer nodes closer to available volunteer coverage)

USER QUERY: "$query"

RESOURCE NODE DATA:
${jsonEncode(hospitalData)}

Return a JSON object with this exact structure:
{
  "summary": "One-sentence overview explaining the recommended volunteer-assisted resource routing",
  "rankings": [
    {
      "hospitalId": "id_from_data",
      "hospitalName": "name_from_data",
      "score": 0-100,
      "reasoning": "2-3 sentence explanation referencing specific resource numbers, buffer times, and why a volunteer should be dispatched to/from this node",
      "factors": {
        "resourceMatch": 0-100,
        "bufferTime": 0-100,
        "specialtyFit": 0-100
      }
    }
  ]
}

Rank ALL nodes. Be specific — cite actual resource counts and buffer times.
Frame recommendations in terms of volunteer dispatch and community impact.
''';
  }

  AIAnalysisResult _parseResponse(
    String responseText,
    List<Hospital> hospitals,
  ) {
    try {
      final json = jsonDecode(responseText) as Map<String, dynamic>;
      final rankingsJson = json['rankings'] as List<dynamic>? ?? [];
      final summary = json['summary'] as String? ?? 'Analysis complete.';

      final rankings = rankingsJson.map((r) {
        final map = r as Map<String, dynamic>;
        return AIRecommendation.fromJson(map);
      }).toList();

      // Ensure all hospital IDs actually exist in our data
      final validIds = hospitals.map((h) => h.id).toSet();
      final validRankings =
          rankings.where((r) => validIds.contains(r.hospitalId)).toList();

      if (validRankings.isEmpty) {
        return _triageEngineAnalysis('', hospitals);
      }

      return AIAnalysisResult(
        rankings: validRankings,
        summary: summary,
        isFromAI: true,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return _triageEngineAnalysis('', hospitals);
    }
  }

  // ── MediLink Triage Engine — proprietary multi-criteria scoring ─────

  AIAnalysisResult _triageEngineAnalysis(
    String query,
    List<Hospital> hospitals,
  ) {
    if (hospitals.isEmpty) {
      return AIAnalysisResult(
        rankings: const [],
        summary: 'No resource nodes available.',
        isFromAI: true,
        timestamp: DateTime.now(),
      );
    }

    final q = query.trim().toLowerCase();
    final rankings = <AIRecommendation>[];

    // Pre-compute nearest volunteer for each hospital using Haversine
    final availableVolunteers = MockData.volunteers
        .where((v) => v.status == VolunteerStatus.available)
        .toList();

    for (final h in hospitals) {
      var score = 0.0;
      final reasons = <String>[];

      // Base capacity score (40% weight)
      final capacityScore =
          (h.beds / AppConstants.maxBedCapacity * 40) +
          (h.oxygen / AppConstants.maxOxygenCapacity * 20);
      score += capacityScore;
      reasons.add('${h.beds} beds, ${h.oxygen} O₂ units available');

      // Buffer time score (30% weight)
      final bufferScore =
          (h.criticalBufferHours / AppConstants.bufferWarningHours * 30)
              .clamp(0.0, 30.0);
      score += bufferScore;
      if (h.criticalBufferHours < double.infinity) {
        reasons.add(
          'Buffer: ${h.criticalBufferHours.toStringAsFixed(1)}h '
          'until earliest resource depletion',
        );
      }

      // Specialty match (30% weight)
      if (q.contains('icu') || q.contains('critical') ||
          q.contains('intensive')) {
        final icuScore = (h.icuBeds / AppConstants.maxIcuCapacity * 30)
            .clamp(0.0, 30.0);
        score += icuScore;
        reasons.add('${h.icuBeds} ICU beds for critical care');
      } else if (q.contains('trauma') || q.contains('accident')) {
        final traumaScore =
            (h.traumaBeds / AppConstants.maxBedCapacity * 30).clamp(0.0, 30.0);
        score += traumaScore;
        reasons.add('${h.traumaBeds} trauma beds');
      } else if (q.contains('oxygen') || q.contains('breathing') ||
          q.contains('respiratory')) {
        score += (h.oxygen / AppConstants.maxOxygenCapacity * 30)
            .clamp(0.0, 30.0);
        reasons.add('Strong oxygen supply for respiratory needs');
      } else if (q.contains('child') || q.contains('pediatric')) {
        score +=
            (h.pediatricBeds / AppConstants.maxBedCapacity * 30)
                .clamp(0.0, 30.0);
        reasons.add('${h.pediatricBeds} pediatric beds');
      } else {
        score += (h.beds / AppConstants.maxBedCapacity * 15).clamp(0.0, 15.0);
        score +=
            (h.oxygen / AppConstants.maxOxygenCapacity * 15).clamp(0.0, 15.0);
      }

      // Volunteer proximity score — real Haversine distance calculation
      double volunteerProximityScore = 0.0;
      String volunteerNote = 'No volunteers currently available';
      if (availableVolunteers.isNotEmpty && h.latitude != null && h.longitude != null) {
        // Find nearest available volunteer to this node
        Volunteer nearest = availableVolunteers.first;
        double nearestDist = nearest.distanceTo(h.latitude!, h.longitude!);
        for (final v in availableVolunteers.skip(1)) {
          final d = v.distanceTo(h.latitude!, h.longitude!);
          if (d < nearestDist) {
            nearestDist = d;
            nearest = v;
          }
        }
        // Score: closer = higher (max 15 for <1km, 0 for >10km)
        volunteerProximityScore =
            (15.0 * (1.0 - (nearestDist / 10.0).clamp(0.0, 1.0)));
        volunteerNote =
            '${nearest.name} is ${nearestDist.toStringAsFixed(1)}km away '
            '(${nearest.vehicleType}, ${nearest.capacityKg}kg capacity)';
      }
      score += volunteerProximityScore;
      reasons.add(volunteerNote);

      // Status penalty
      if (h.status == ResourceStatus.critical) {
        score *= 0.3;
        reasons.add('⚠ CRITICAL status — capacity severely limited');
      } else if (h.status == ResourceStatus.low) {
        score *= 0.6;
        reasons.add('⚠ LOW status — limited capacity');
      }

      rankings.add(AIRecommendation(
        hospitalId: h.id,
        hospitalName: h.name,
        score: score.clamp(0.0, 100.0),
        reasoning: reasons.join('. ') + '.',
        factors: {
          'capacityScore': capacityScore,
          'bufferScore': bufferScore,
          'volunteerProximity': volunteerProximityScore,
          'statusMultiplier':
              h.status == ResourceStatus.critical
                  ? 0.3
                  : h.status == ResourceStatus.low
                      ? 0.6
                      : 1.0,
        },
      ));
    }

    rankings.sort((a, b) => b.score.compareTo(a.score));

    // Build intelligent summary using actual nearest volunteer
    final top = rankings.first;
    final topHospital = hospitals.where((h) => h.id == top.hospitalId).first;
    String volunteerSummary = '';
    if (availableVolunteers.isNotEmpty &&
        topHospital.latitude != null &&
        topHospital.longitude != null) {
      Volunteer nearest = availableVolunteers.first;
      double nearestDist =
          nearest.distanceTo(topHospital.latitude!, topHospital.longitude!);
      for (final v in availableVolunteers.skip(1)) {
        final d = v.distanceTo(topHospital.latitude!, topHospital.longitude!);
        if (d < nearestDist) {
          nearestDist = d;
          nearest = v;
        }
      }
      volunteerSummary =
          'Nearest volunteer: ${nearest.name} (${nearestDist.toStringAsFixed(1)}km, '
          '${nearest.vehicleType}). ';
    }

    return AIAnalysisResult(
      rankings: rankings,
      summary: q.isEmpty
          ? 'Triage Engine: Nodes ranked by resource availability, buffer time, '
            'and volunteer proximity. $volunteerSummary'
          : '${volunteerSummary}'
              '${top.hospitalName} is the best match for "$query" '
              'with a triage score of ${top.score.toStringAsFixed(0)}/100.',
      isFromAI: true,
      timestamp: DateTime.now(),
    );
  }
}
