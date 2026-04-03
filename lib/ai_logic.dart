import 'package:flutter/material.dart';

class AILogic {

  static Map<String, dynamic> getBestHospital(
      List<Map<String, dynamic>> hospitals,
      String userQuery) {

    if (hospitals.isEmpty) {
      return {
        "name": "No hospitals available",
        "beds": 0,
        "oxygen": 0,
        "reason": "No data found in system"
      };
    }

    String query = userQuery.toLowerCase();
    Map<String, dynamic>? best;
    int bestScore = -1;

    for (var h in hospitals) {
      int beds = _parseInt(h['beds']);
      int oxygen = _parseInt(h['oxygen']);

      int score = beds * 2 + oxygen;

      if (query.contains("fever")) score += beds;
      if (query.contains("oxygen") || query.contains("breathing")) score += oxygen * 2;
      if (query.contains("icu") || query.contains("critical")) score += beds * 2;

      if (score > bestScore) {
        bestScore = score;
        best = h;
      }
    }

    if (best == null) {
      return {
        "name": "No suitable hospital",
        "beds": 0,
        "oxygen": 0,
        "reason": "Unable to determine best option"
      };
    }

    int bestBeds = _parseInt(best['beds']);
    int bestOxygen = _parseInt(best['oxygen']);

    String conditionNote = "";
    if (query.contains("fever")) conditionNote = "prioritized for bed availability (fever case)";
    else if (query.contains("oxygen") || query.contains("breathing")) conditionNote = "prioritized for oxygen supply (breathing emergency)";
    else if (query.contains("icu") || query.contains("critical")) conditionNote = "prioritized for ICU capacity (critical case)";
    else conditionNote = "best overall resource availability";

    return {
      "name": best['name'] ?? "Unknown",
      "beds": bestBeds,
      "oxygen": bestOxygen,
      "reason": "${best['name']} selected — $bestBeds beds & $bestOxygen oxygen units available, $conditionNote."
    };
  }

  static Map<String, dynamic>? getTransferSuggestion(
      List<Map<String, dynamic>> hospitals) {

    if (hospitals.length < 2) return null;

    Map<String, dynamic>? rich;
    Map<String, dynamic>? needy;

    for (var h in hospitals) {
      int beds = _parseInt(h['beds']);
      if (rich == null || beds > _parseInt(rich['beds'])) rich = h;
      if (needy == null || beds < _parseInt(needy['beds'])) needy = h;
    }

    if (rich == null || needy == null) return null;

    int richBeds = _parseInt(rich['beds']);
    int needyBeds = _parseInt(needy['beds']);

    if (richBeds <= needyBeds) return null;

    int transferAmount = ((richBeds - needyBeds) / 2).floor();
    if (transferAmount <= 0) return null;

    return {
      "from": rich['name'],
      "to": needy['name'],
      "amount": transferAmount,
      "fromBeds": richBeds,
      "toBeds": needyBeds,
      "after": needyBeds + transferAmount,
      "reason": "${rich['name']} has $richBeds beds (surplus). ${needy['name']} has $needyBeds beds (critical). Transferring $transferAmount beds balances the system."
    };
  }

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  static String getStatus(int beds, int oxygen) {
    if (beds == 0 || oxygen == 0) return "CRITICAL";
    if (beds <= 3 || oxygen <= 5) return "LOW";
    if (beds <= 7 || oxygen <= 15) return "MODERATE";
    return "STABLE";
  }

  static Color getStatusColor(int beds, int oxygen) {
    String status = getStatus(beds, oxygen);
    switch (status) {
      case "CRITICAL": return const Color(0xFFE53935);
      case "LOW":      return const Color(0xFFE53935);
      case "MODERATE": return const Color(0xFFFFA726);
      default:         return const Color(0xFF43A047);
    }
  }
}