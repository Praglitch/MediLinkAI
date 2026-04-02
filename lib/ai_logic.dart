class AILogic {

  /// 🧠 BEST HOSPITAL SELECTION
  static Map<String, dynamic> getBestHospital(
      List<Map<String, dynamic>> hospitals,
      String userQuery) {

    /// ❌ EMPTY DATA SAFETY
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

      /// ✅ SAFE PARSING (NO CRASH)
      int beds = h['beds'] is int
          ? h['beds']
          : int.tryParse(h['beds'].toString()) ?? 0;

      int oxygen = h['oxygen'] is int
          ? h['oxygen']
          : int.tryParse(h['oxygen'].toString()) ?? 0;

      /// 🎯 BASE SCORE
      int score = beds * 2 + oxygen;

      /// 🤖 SIMPLE AI BOOST
      if (query.contains("fever")) {
        score += beds;
      }

      if (query.contains("oxygen") || query.contains("breathing")) {
        score += oxygen * 2;
      }

      if (query.contains("icu") || query.contains("critical")) {
        score += beds * 2;
      }

      /// 🏆 SELECT BEST
      if (score > bestScore) {
        bestScore = score;
        best = h;
      }
    }

    /// ⚠️ FALLBACK
    if (best == null) {
      return {
        "name": "No suitable hospital",
        "beds": 0,
        "oxygen": 0,
        "reason": "Unable to determine best option"
      };
    }

    return {
      "name": best['name'] ?? "Unknown",
      "beds": best['beds'] ?? 0,
      "oxygen": best['oxygen'] ?? 0,
      "reason":
          "Recommended based on better availability of beds and oxygen"
    };
  }

  /// 🔄 RESOURCE TRANSFER LOGIC
  static Map<String, dynamic>? getTransferSuggestion(
      List<Map<String, dynamic>> hospitals) {

    if (hospitals.length < 2) return null;

    Map<String, dynamic>? rich;
    Map<String, dynamic>? needy;

    for (var h in hospitals) {

      int beds = h['beds'] is int
          ? h['beds']
          : int.tryParse(h['beds'].toString()) ?? 0;

      if (rich == null || beds > (rich['beds'] ?? 0)) {
        rich = h;
      }

      if (needy == null || beds < (needy['beds'] ?? 0)) {
        needy = h;
      }
    }

    if (rich == null || needy == null) return null;

    int richBeds = rich['beds'] ?? 0;
    int needyBeds = needy['beds'] ?? 0;

    if (richBeds <= needyBeds) return null;

    int transferAmount = ((richBeds - needyBeds) / 2).floor();

    if (transferAmount <= 0) return null;

    return {
      "from": rich['name'],
      "to": needy['name'],
      "amount": transferAmount,
      "after": needyBeds + transferAmount,
      "reason": "Redistribution suggested to balance resources"
    };
  }

  /// 📊 STATUS LABEL
  static String getStatus(int beds) {
    if (beds == 0) return "CRITICAL";
    if (beds <= 3) return "LOW";
    if (beds <= 7) return "MODERATE";
    return "STABLE";
  }
}