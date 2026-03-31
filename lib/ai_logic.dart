// 🔷 STATUS LOGIC
String getStatus(int beds) {
  if (beds == 0) return "CRITICAL";
  if (beds <= 5) return "LOW";
  return "STABLE";
}


// 🔷 BEST HOSPITAL (AI DECISION ENGINE)
Map<String, dynamic> getBestHospital(
    List<Map<String, dynamic>> hospitals) {

  // Remove hospitals with no beds
  List<Map<String, dynamic>> valid =
      hospitals.where((h) => h['beds'] > 0).toList();

  if (valid.isEmpty) {
    return {
      "name": "No Hospital Available",
      "reason": "All hospitals are full"
    };
  }

  // Sort by beds descending
  valid.sort((a, b) => b['beds'].compareTo(a['beds']));

  var best = valid.first;

  return {
    "name": best['name'],
    "beds": best['beds'],
    "oxygen": best['oxygen'],
    "reason": "Highest bed availability"
  };
}


// 🔷 SMART RESOURCE TRANSFER (USP 🔥)
Map<String, dynamic> suggestTransfer(
    List<Map<String, dynamic>> hospitals) {

  if (hospitals.isEmpty) {
    return {"message": "No data"};
  }

  // Sort by beds ascending
  hospitals.sort((a, b) => a['beds'].compareTo(b['beds']));

  var needy = hospitals.first;
  var rich = hospitals.last;

  // If system stable → no transfer
  if (needy['beds'] >= 5) {
    return {
      "message": "System Stable",
      "action": "No transfer needed"
    };
  }

  int transferAmount = (rich['beds'] / 2).floor();

  return {
    "from": rich['name'],
    "to": needy['name'],
    "amount": transferAmount,
    "reason": "Balancing hospital load"
  };
}


// 🔷 ALERT SYSTEM (HIGH IMPACT FEATURE)
List<Map<String, dynamic>> getAlerts(
    List<Map<String, dynamic>> hospitals) {

  List<Map<String, dynamic>> alerts = [];

  for (var h in hospitals) {

    if (h['beds'] == 0) {
      alerts.add({
        "hospital": h['name'],
        "type": "CRITICAL",
        "message": "No beds available"
      });
    }

    else if (h['beds'] <= 3) {
      alerts.add({
        "hospital": h['name'],
        "type": "LOW",
        "message": "Beds running low"
      });
    }
  }

  return alerts;
}